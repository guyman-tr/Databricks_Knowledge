# Billing.PayPal

> Registry of customer PayPal email accounts registered on the platform; each row stores one PayPal email address, uniquely keyed to prevent duplicate registrations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | PayPalID (PRIMARY KEY NONCLUSTERED, IDENTITY) |
| **Row Count** | ~29,471 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED on PayPalID; 1 - UNIQUE NC on PayPalEmailAccount |

---

## 1. Business Meaning

`Billing.PayPal` is the registry of PayPal email accounts that customers have linked to the eToro platform. Each row represents one PayPal account, identified by the customer's PayPal email address. The `PayPalID` is eToro's internal identifier for the registration, used to link deposit and withdrawal records to a specific PayPal account without repeatedly storing the email string.

With ~29,471 rows, PayPal was a significantly more adopted payment method than Neteller (1,687 rows), reflecting PayPal's broader consumer usage. The table participates in:
- `Billing.PayPalToPayment`: deposit payments linked to PayPal accounts
- `Billing.CashoutProcessToPayPal`: withdrawal processing via PayPal API
- `Billing.PayPalBillingAgreementGet/Delete`: PayPal recurring billing agreement management (more sophisticated integration than Neteller)

---

## 2. Business Logic

### 2.1 PayPal Account Registration

**What**: Records a customer's PayPal email when they register it as a payment method on eToro.

**Columns Involved**: `PayPalID`, `PayPalEmailAccount`

**Rules**:
- `Billing.PayPalAdd @PayPalEmailAccount -> @PayPalID OUTPUT`: inserts a new PayPal account; returns the new `PayPalID`
- `PayPalEmailAccount` is UNIQUE (BPPL_ACCOUNT index) - one registration per PayPal email address
- `Billing.CheckInBlockedPayPals @PayPalEmail` - checks whether a PayPal email is on the blocked list (separate `Billing.BlockPayPal` table, distinct from this registry)
- `Billing.PayPalBillingAgreementGet/Delete`: manage PayPal pre-authorized billing agreements tied to `PayPalID`

### 2.2 PayPal vs. Billing Agreement Flows

PayPal supports two payment flows:
1. **Direct payment**: customer initiates each transaction using their registered PayPal email
2. **Billing agreement**: a pre-authorized recurring authorization; `PayPalID` is linked to a billing agreement token allowing eToro to initiate charges without per-transaction customer approval

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | ~29,471 |
| ID range | 24 to 29,495 (gaps from deleted accounts) |
| Unique emails | 29,471 (UNIQUE constraint) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PayPalID | int | NO | IDENTITY(1,1) | CODE-BACKED | Internal eToro primary key for this PayPal account registration. Auto-generated. Referenced by `Billing.PayPalToPayment` (deposits), cashout processing, and billing agreement tables. NOT FOR REPLICATION. |
| 2 | PayPalEmailAccount | varchar(250) | NO | - | CODE-BACKED | The customer's PayPal email address. This is the PayPal account identifier used to initiate transfers. UNIQUE enforced by BPPL_ACCOUNT index. Up to 250 characters to accommodate long email addresses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PayPalToPayment | PayPalID | FK (implicit) | Links deposit payment records to registered PayPal accounts |
| Billing.CashoutProcessToPayPal | PayPalID, PayPalEmailAccount | Read | Retrieves PayPal email for cashout API call |
| Billing.PayPalBillingAgreementGet | PayPalID | Read | Retrieves billing agreement for recurring payments |
| Billing.PayPalBillingAgreementDelete | PayPalID | Delete | Removes billing agreement on account change |
| Billing.PayPalAdd | PayPalID (OUTPUT) | Write | Inserts new PayPal account registration |
| Billing.LoadPayPals | - | Read | Loads full registry into application cache |
| Billing.LoadPayPalToPayment | - | Read | Loads PayPal-to-payment associations |
| Billing.PaymentByPayPalAdd | PayPalID | Write | Associates a payment with a PayPal account |
| Billing.PayPalToPaymentEdit | PayPalID | Write | Updates PayPal account on a payment |
| Billing.BlockPayPalAdd / Remove | PayPalEmailAccount | Read/Write | Manages the separate blocked PayPal list |
| Billing.GetPaymentByTransaction | PayPalID | Read | Retrieves payment details including PayPal reference |
| Billing.CustomerRemove | PayPalID | Delete | Removes PayPal registrations on customer account deletion |

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies - independent registry table.

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayPalToPayment | Table | FK on PayPalID - links deposits to PayPal accounts |
| Billing.CashoutProcessToPayPal | Stored Procedure | Reads email for PayPal cashout API |
| Billing.PayPalBillingAgreementGet | Stored Procedure | Reads billing agreement by PayPalID |
| Billing.LoadPayPals | Stored Procedure | Full table scan for cache loading |
| Billing.PayPalAdd | Stored Procedure | Inserts new PayPal registrations |
| Billing.CustomerRemove | Stored Procedure | Deletes records on customer removal |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BPPL | NONCLUSTERED PK | PayPalID ASC | - | - | Active; FILLFACTOR=90; heap table (no clustered index) |
| BPPL_ACCOUNT | UNIQUE NC | PayPalEmailAccount ASC | - | - | Active; FILLFACTOR=90; SET ANSI_PADDING ON; prevents duplicate email registration |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BPPL | PRIMARY KEY NONCLUSTERED | One row per PayPalID |
| BPPL_ACCOUNT (index) | UNIQUE | One registration per PayPal email address |

---

## 8. Sample Queries

### 8.1 View PayPal registrations (count and recent)

```sql
SELECT COUNT(*) AS TotalRegistered FROM Billing.PayPal WITH (NOLOCK)

SELECT TOP 10 PayPalID, LEFT(PayPalEmailAccount, 3) + '***' AS EmailMasked
FROM Billing.PayPal WITH (NOLOCK)
ORDER BY PayPalID DESC
```

### 8.2 Find PayPal accounts with associated payments

```sql
SELECT TOP 20
    p.PayPalID,
    COUNT(ptp.PaymentID) AS PaymentCount
FROM Billing.PayPal p WITH (NOLOCK)
JOIN Billing.PayPalToPayment ptp WITH (NOLOCK) ON ptp.PayPalID = p.PayPalID
GROUP BY p.PayPalID
ORDER BY PaymentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayPal | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PayPal.sql*
