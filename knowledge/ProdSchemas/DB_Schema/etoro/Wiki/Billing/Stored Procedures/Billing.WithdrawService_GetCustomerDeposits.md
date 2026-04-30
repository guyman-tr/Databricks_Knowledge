# Billing.WithdrawService_GetCustomerDeposits

> Returns all deposit records for a customer from Billing.Deposit, providing the withdrawal service with the full deposit history needed for refund eligibility and payment method validation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid - customer whose deposits are returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetCustomerDeposits` is a simple reader procedure used by the withdrawal service to retrieve a customer's complete deposit history. The withdrawal service needs deposit data to determine eligible refund methods (a customer can only receive a refund to a payment method they deposited from), to assess prior payment method usage for AMOP eligibility, and to check deposit amounts for refund calculations.

The procedure exists as a named entry point rather than an inline query so the withdrawal service has a stable, permissioned interface to deposit data without needing direct table access. All columns are returned without filtering by status, giving the caller full visibility into all deposit states (pending, approved, declined, refunded, etc.).

Data flows from the withdrawal service into this procedure whenever a customer initiates a withdrawal and the service needs to evaluate which payment methods are eligible for refund or which deposit a withdrawal is linked to.

---

## 2. Business Logic

### 2.1 No Status Filtering - Full History Returned

**What**: All deposit rows for the customer are returned regardless of PaymentStatusID.

**Columns/Parameters Involved**: `@cid`, `PaymentStatusID`

**Rules**:
- No WHERE clause on PaymentStatusID - returns pending, approved, declined, charged-back, and refunded deposits alike.
- The caller (withdrawal service) is responsible for filtering by status for its specific use case.
- Approved deposits (PaymentStatusID=2) are the ones that contributed real funds; others are still returned for context.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters `Billing.Deposit` by CID to return deposits for this customer only. |

**Result Set Columns** (all from `Billing.Deposit`):

| # | Column | Description |
|---|--------|-------------|
| 1 | DepositID | Primary key of the deposit record. |
| 2 | CID | Customer ID (same as @cid - included for client-side convenience). |
| 3 | FundingID | The payment instrument used for this deposit. FK to `Billing.Funding`. |
| 4 | CurrencyID | Currency of the deposit. FK to `Dictionary.Currency`. |
| 5 | PaymentStatusID | Deposit status: 2=Approved, 1=New, 5=InProcess, 3=Declined, etc. |
| 6 | ManagerID | Manager who last acted on this deposit, or NULL for system-processed. |
| 7 | RiskManagementStatusID | Risk management decision for this deposit. |
| 8 | Amount | Deposit amount in the deposit currency. |
| 9 | ExchangeRate | Exchange rate applied if currency conversion occurred. |
| 10 | PaymentDate | Timestamp when the deposit was submitted/approved. |
| 11 | ModificationDate | Last modification timestamp. |
| 12 | TransactionID | Payment provider transaction reference. |
| 13 | IPAddress | Customer IP address at deposit time. |
| 14 | Approved | Approval flag for the deposit. |
| 15 | Commission | Commission charged on this deposit. |
| 16 | PaymentData | XML with provider response and routing details. Subject to DDM masking. |
| 17 | IsFTD | 1 if this was the customer's first-time deposit. |
| 18 | DepotID | The depot (MID/merchant account) that processed this deposit. |
| 19 | FunnelID | Marketing funnel identifier for attribution. |
| 20 | DepositTypeID | Type of deposit (standard, bonus, etc.). |
| 21 | ExchangeFee | Fee charged for currency exchange if applicable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | Billing.Deposit | Filter | All deposits for this CID are returned. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawService (application) | - | Caller | Withdrawal service calls this to get deposit history for refund eligibility assessment. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetCustomerDeposits (procedure)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT all columns WHERE CID = @cid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No DB-layer dependents found | - | Called from withdrawal service application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No input validation or filtering beyond CID.

---

## 8. Sample Queries

### 8.1 Get all deposits for a customer

```sql
EXEC Billing.WithdrawService_GetCustomerDeposits @cid = 12345;
```

### 8.2 Get only approved deposits for a customer (caller-side filter)

```sql
-- The SP returns all statuses; filter in the application or via a wrapper query:
SELECT d.*
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.CID = 12345
  AND d.PaymentStatusID = 2
ORDER BY d.PaymentDate DESC;
```

### 8.3 Get funding methods used in approved deposits for AMOP validation

```sql
SELECT DISTINCT
    d.FundingID,
    f.FundingTypeID,
    ft.Name AS FundingTypeName,
    MAX(d.PaymentDate) AS LastApprovedDepositDate
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = d.FundingID
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = f.FundingTypeID
WHERE d.CID = 12345
  AND d.PaymentStatusID = 2
GROUP BY d.FundingID, f.FundingTypeID, ft.Name
ORDER BY LastApprovedDepositDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetCustomerDeposits | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetCustomerDeposits.sql*
