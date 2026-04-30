# Billing.GetSumAmountByCID

> Aggregates total deposit payment amounts per customer (CreditTypeID=1 from History.Credit), joining with Customer.Customer to expose OriginalCID and OriginalProviderID for cross-server customer identity resolution in the QUADFOOT demo environment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | (CID, OriginalCID, OriginalProviderID) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GetSumAmountByCID` answers the question "how much has a customer deposited in total?" by summing the `Payment` column from `History.Credit` for deposit credits (CreditTypeID=1), grouped by customer identity fields.

The view exists specifically for the **QUADFOOT demo server** (`AMS-QUAD-SQL-1`, database `tradonomi`). Both stored procedures that use it gate their calls with `IF @@SERVERNAME = 'AMS-QUAD-SQL-1'` checks, meaning this view is never queried in production. In the demo environment, customer accounts are clones of production accounts, identified by `OriginalCID` (original production CID) and `OriginalProviderID` (the source provider/server). This view allows the demo environment to check whether a customer's original production account had a positive deposit history, used to determine account expiration policy.

**Note**: This view depends on `History.Credit` in the `EtoroArchive` database, which is not accessible to the standard read-only MCP user. Live row counts cannot be obtained via MCP.

---

## 2. Business Logic

### 2.1 Deposit Credits Only (CreditTypeID=1)

**What**: Only deposit-type credit history records are summed.

**Columns/Parameters Involved**: `CreditTypeID`, `SumAmount`

**Rules**:
- WHERE CreditTypeID = 1 (Deposit credits only)
- Other credit types (bonuses=5/7, adjustments, etc.) are excluded
- SumAmount represents total lifetime deposit credits for the customer
- Callers check `SumAmount > 0` to determine if the customer has ever deposited

### 2.2 OriginalCID for Demo Environment Identity Mapping

**What**: Joins with Customer.Customer to expose OriginalCID and OriginalProviderID for cross-server identity resolution.

**Columns/Parameters Involved**: `CID`, `OriginalCID`, `OriginalProviderID`

**Rules**:
- INNER JOIN: only customers who exist in both History.Credit and Customer.Customer appear
- `OriginalCID`: the CID from the production/source server that this demo account was cloned from
- `OriginalProviderID`: identifies which source system/provider the original account came from
- Callers join on `OriginalCID = DEP.OriginalCID AND OriginalProviderID = DEP.OriginalProviderID` to match demo customers back to their production deposit history
- `BackOffice.ExpirationHoursCalc` queries: `WHERE OriginalCID = @CID AND SumAmount > 0`

### 2.3 QUADFOOT Demo Server Usage Only

**What**: This view is only ever called from procedures that gate execution on a specific server name.

**Columns/Parameters Involved**: (all columns - guarded at call site)

**Rules**:
- `BackOffice.ExpirationHoursCalc`: `IF @ActualServerName = 'AMS-QUAD-SQL-1' AND @ActualDBName = 'tradonomi'`
- `BackOffice.GetCustomersForStatusChange`: `IF @@SERVERNAME = 'AMS-QUAD-SQL-1' AND DB_NAME() = 'tradonomi'`
- In the demo server, deposits are represented as cloned credit history entries from production
- The demo environment uses deposit totals to determine account expiration: accounts with SumAmount > 0 get `ExpirationDate = '3000-01-01'` (never expire)

---

## 3. Data Overview

Live query not available - view depends on `History.Credit` in `EtoroArchive` database (inaccessible to read-only MCP user). Expected structure:

| CID | OriginalCID | OriginalProviderID | SumAmount | Meaning |
|-----|-------------|-------------------|-----------|---------|
| 12345 (demo) | 98765 (prod) | 1 | 2500.00 | Demo account cloned from production CID 98765 who deposited $2500 total |
| 54321 (demo) | 11111 (prod) | 1 | 0.00 | Demo clone of a non-depositing production customer |

**Row count**: Unknown (requires EtoroArchive access). Contains one row per (CID, OriginalCID, OriginalProviderID) combination for customers with CreditTypeID=1 records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID from Customer.Customer. The demo server's local customer identifier. Used as the primary customer reference in the demo environment. INNER JOIN key - only customers present in both History.Credit and Customer.Customer are included. |
| 2 | OriginalCID | int | YES | - | CODE-BACKED | Original production CID from Customer.Customer. The production server's CID that this demo account was cloned from. NULL if this customer has no original (i.e., not a demo clone). Used by callers to link demo accounts back to production deposit histories. |
| 3 | OriginalProviderID | int | YES | - | CODE-BACKED | Original provider/server identifier from Customer.Customer. Identifies the source system that the demo clone originated from. Used together with OriginalCID to uniquely identify the source production account. |
| 4 | SumAmount | money (computed) | YES | - | CODE-BACKED | Total lifetime deposit amount for this customer. Computed as SUM(History.Credit.Payment) WHERE CreditTypeID=1. In the caller context: if SumAmount > 0, the customer has deposited at least once. NULL if Payment column values are all NULL (edge case). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Payment, CreditTypeID | History.Credit (EtoroArchive) | Source (FROM anchor, WHERE CreditTypeID=1) | Deposit credit records; EtoroArchive cross-database |
| CID, OriginalCID, OriginalProviderID | Customer.Customer | Source (INNER JOIN on CID) | Customer identity and original production mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.ExpirationHoursCalc | SumAmount | Reference (SELECT, WHERE OriginalCID + SumAmount>0) | Checks if customer has deposits to assign no-expiry status on demo server |
| BackOffice.GetCustomersForStatusChange | SumAmount, OriginalProviderID | Reference (LEFT JOIN on OriginalCID + OriginalProviderID) | Gets deposit totals for batch status change processing on demo server |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetSumAmountByCID (view)
├── History.Credit (table, EtoroArchive cross-database)
└── Customer.Customer (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (EtoroArchive) | FROM anchor: CID, Payment (summed), filtered to CreditTypeID=1 (deposits) |
| Customer.Customer | Table (cross-schema) | INNER JOIN on CID: OriginalCID, OriginalProviderID for demo identity mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ExpirationHoursCalc | Stored Procedure | Queries SumAmount by OriginalCID on QUADFOOT server only |
| BackOffice.GetCustomersForStatusChange | Stored Procedure | LEFT JOINs on OriginalCID + OriginalProviderID for batch status changes on QUADFOOT server only |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Depends on History.Credit (EtoroArchive) and Customer.Customer indexes. The GROUP BY on (CID, OriginalCID, OriginalProviderID) requires a full scan of the CreditTypeID=1 subset. Performance is only relevant in the QUADFOOT demo environment where this view is actually called.

### 7.2 Constraints

N/A for view. Cross-database dependency on EtoroArchive (History.Credit) - requires the executing login to have access to EtoroArchive. INNER JOIN means customers with History.Credit records but no Customer.Customer record are excluded (and vice versa). No SCHEMABINDING (cross-database). Not queryable via standard read-only MCP user due to EtoroArchive access restriction.

---

## 8. Sample Queries

### 8.1 Check if a customer has deposited (demo server use case)

```sql
SELECT SumAmount
FROM Billing.GetSumAmountByCID WITH (NOLOCK)
WHERE OriginalCID = @CID
  AND SumAmount > 0
```

### 8.2 Get deposit totals for demo account expiration check

```sql
SELECT CUS.CID, CUS.AccountExpirationDate, DEP.SumAmount, DEP.OriginalProviderID
FROM Customer.Customer CUS WITH (NOLOCK)
LEFT JOIN Billing.GetSumAmountByCID DEP WITH (NOLOCK)
    ON CUS.OriginalCID = DEP.OriginalCID
    AND CUS.OriginalProviderID = DEP.OriginalProviderID
WHERE CUS.AccountExpirationDate IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 3/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetSumAmountByCID | Type: View | Source: etoro/etoro/Billing/Views/Billing.GetSumAmountByCID.sql*
