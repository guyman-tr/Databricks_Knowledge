# BackOffice.LastCustomerInfo

> Near-empty cache table (10 rows) intended to store pointers to each customer's last login, last payment, and last cashout. In practice only LoginID is populated (10 rows); PaymentID and CashoutID are NULL for all rows. Used exclusively by NewRiskAlertsPCIVersion to retrieve the last login IP address by joining to History.LoginArch.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, CLUSTERED PK) |
| **Partition** | No (stored ON [HISTORY] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.LastCustomerInfo was designed as a denormalized cache of the most recent activity identifiers for each customer: their last login (LoginID), last deposit (PaymentID), and last cashout (CashoutID). By storing these pointers in a dedicated one-row-per-customer table, reports like NewRiskAlertsPCIVersion can look up the last login IP address without scanning History.LoginArch by customer.

In practice, the table was barely used:
- 10 rows exist for 10 customers only.
- All 10 rows have LoginID populated (clustered around LoginIDs 185010138-185010147, suggesting a one-time batch insert).
- PaymentID and CashoutID are NULL for all 10 rows - these columns were never written.
- The table is stored on the [HISTORY] filegroup, alongside archive/historical data.

The only consumer is NewRiskAlertsPCIVersion (the BackOffice risk alerts PCI-compliant report), which LEFT JOINs this table to resolve the "Last Login IP" column:
```
LEFT JOIN BackOffice.LastCustomerInfo ON LastCustomerInfo.CID = BDEP.CID
LEFT JOIN History.LoginArch LastLogin ON LastLogin.LoginID = LastCustomerInfo.LoginID
```
For the 99.999%+ of customers with no row here, the join produces NULL (last login IP is blank).

---

## 2. Business Logic

### 2.1 Last Login IP Lookup (NewRiskAlertsPCIVersion)

**What**: Resolves the last login IP for a customer in the risk alerts report.

**Columns Involved**: `CID`, `LoginID`

**Rules**:
- NewRiskAlertsPCIVersion LEFT JOINs LastCustomerInfo on CID, then LEFT JOINs History.LoginArch on LoginID.
- Output column "Last Login IP" = History.LoginArch.IP for the matching LoginID.
- If no LastCustomerInfo row exists for the customer (which is true for virtually all customers), "Last Login IP" = NULL.

---

## 3. Data Overview

10 rows as of 2026-03-17 (10 distinct CIDs, 10 LoginIDs, 0 PaymentIDs, 0 CashoutIDs):

| CID | LoginID | PaymentID | CashoutID |
|-----|---------|-----------|-----------|
| 36 | 185010145 | NULL | NULL |
| 555 | 185010147 | NULL | NULL |
| 15,281 | 185010144 | NULL | NULL |
| 27,986 | 185010141 | NULL | NULL |
| 2,575,684 | 185010138 | NULL | NULL |
| ... (5 more rows) | ~185010138-185010147 range | NULL | NULL |

The LoginIDs are tightly clustered (185010138-185010147), suggesting these 10 rows were inserted in a single batch operation. The CIDs span a wide range (36 to millions), so these are not sequential test accounts.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. CLUSTERED PK. One row per customer. FK (WITH CHECK) to Customer.CustomerStatic(CID). 10 rows currently - the table is near-empty. |
| 2 | LoginID | bigint | YES | NULL | VERIFIED | The ID of the customer's most recent login session. FK (WITH CHECK) to Billing.Payment - wait, actually there is no FK to History.LoginArch declared. Used by NewRiskAlertsPCIVersion to join History.LoginArch for last login IP. All 10 current rows have this populated. BIGINT (login IDs are high-volume, exceeding INT range). |
| 3 | PaymentID | int | YES | NULL | CODE-BACKED | The ID of the customer's most recent deposit. FK (WITH CHECK) to Billing.Payment(PaymentID). NULL for all current rows - this column was never written to in practice. INT. |
| 4 | CashoutID | int | YES | NULL | CODE-BACKED | The ID of the customer's most recent cashout/withdrawal. FK (WITH CHECK) to Billing.Cashout(CashoutID). NULL for all current rows - this column was never written to in practice. INT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (WITH CHECK) | Customer identity anchor |
| PaymentID | Billing.Payment | FK (WITH CHECK) | Last deposit record (never populated in practice) |
| CashoutID | Billing.Cashout | FK (WITH CHECK) | Last cashout record (never populated in practice) |
| LoginID | History.LoginArch | Implicit (no FK) | Last login session - no declared constraint; joined by NewRiskAlertsPCIVersion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.NewRiskAlertsPCIVersion | CID | READER (LEFT JOIN) | Resolves "Last Login IP" via History.LoginArch |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.LastCustomerInfo (cache table)
- FK targets:
  |- Customer.CustomerStatic (CID)
  |- Billing.Payment (PaymentID)
  |- Billing.Cashout (CashoutID)
- Implicit reference: History.LoginArch (LoginID, no FK)
- Reader: BackOffice.NewRiskAlertsPCIVersion
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK on CID |
| Billing.Payment | Table | FK on PaymentID |
| Billing.Cashout | Table | FK on CashoutID |
| History.LoginArch | Table | Implicit - LoginID joined by consumer procedure |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.NewRiskAlertsPCIVersion | Procedure | READER - LEFT JOIN to resolve last login IP |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_BLCI | CLUSTERED PK | CID ASC | Active (FILLFACTOR=90, ON [HISTORY]) |

Table stored on [HISTORY] filegroup, indicating design intent as a historical/archive-adjacent reference cache. Single clustered PK on CID - appropriate for the primary access pattern of per-customer lookup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BLCI | PK | CID uniqueness (one row per customer) |
| FK_CCST_BLCI | FK (WITH CHECK) | CID -> Customer.CustomerStatic(CID) |
| FK_BPAY_BLCI | FK (WITH CHECK) | PaymentID -> Billing.Payment(PaymentID) |
| FK_BCSH_BLCI | FK (WITH CHECK) | CashoutID -> Billing.Cashout(CashoutID) |

---

## 8. Sample Queries

### 8.1 Get last login info for a customer
```sql
SELECT lci.CID,
       lci.LoginID,
       la.IP AS LastLoginIP,
       la.LoginDate AS LastLoginDate
FROM BackOffice.LastCustomerInfo lci WITH (NOLOCK)
LEFT JOIN History.LoginArch la WITH (NOLOCK)
    ON la.LoginID = lci.LoginID
WHERE lci.CID = @CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.LastCustomerInfo | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.LastCustomerInfo.sql*
