# Billing.WithdrawService_GetCustomerWithdrawals

> Returns withdrawal records for a customer from Billing.Withdraw, optionally filtered by a start date, using a query hint to guarantee CID-index usage for consistent performance.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid - customer whose withdrawals are returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetCustomerWithdrawals` provides the withdrawal service with a customer's withdrawal history. The service uses this to check existing withdrawal requests, verify the customer's withdrawal behaviour, and enforce business rules (e.g., maximum pending withdrawals, checking prior request amounts for comparison).

The procedure exists to give the withdrawal service a stable, permissioned read interface to `Billing.Withdraw` with a predictable query plan. A notable design decision is the `OPTION (OPTIMIZE FOR (@startTime = '20090101'))` hint: this forces the query optimizer to always plan as if `@startTime` is a date far in the past (2009), ensuring the CID-based index is always chosen over a date-range scan. Without this hint, if a caller passes a very recent `@startTime`, the optimizer might choose a date-range index that scans many CIDs instead of the CID-based index, causing poor performance for common use cases.

---

## 2. Business Logic

### 2.1 Optional Date Filter with OPTIMIZE FOR Hint

**What**: The @startTime parameter filters withdrawals to those from a certain date forward, but the query hint overrides cardinality estimation.

**Columns/Parameters Involved**: `@startTime`, `RequestDate`

**Rules**:
- If `@startTime IS NULL`: all withdrawals for the customer are returned (no date filter applied).
- If `@startTime` is provided: only withdrawals where `RequestDate >= @startTime` are returned.
- `OPTION (OPTIMIZE FOR (@startTime = '20090101'))` forces the optimizer to treat the date as 2009-01-01, resulting in high estimated row count and therefore CID-index selection. This prevents accidental date-range index selection when a very recent date is passed (code comment explains this explicitly).

### 2.2 Partial Column Projection (Not SELECT *)

**What**: A specific subset of Billing.Withdraw columns is returned, not all columns.

**Columns/Parameters Involved**: All result set columns

**Rules**:
- Excluded columns (not returned): `FundingTypeID`, `CID` (CID excluded from SELECT but caller knows it from @cid), `WithdrawTypeID`, `FlowID`, `CurrencyID`, and other extended columns.
- The selected columns cover the core withdrawal lifecycle: identification, status, dates, amounts, and comments.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters `Billing.Withdraw` by CID. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional lower bound on RequestDate. If NULL, all withdrawals are returned. If provided, only withdrawals with RequestDate >= @startTime are included. Subject to OPTIMIZE FOR hint (see Section 2.1). |

**Result Set Columns** (from `Billing.Withdraw`):

| # | Column | Description |
|---|--------|-------------|
| 1 | WithdrawID | Primary key of the withdrawal request. |
| 2 | CID | Customer ID (same as @cid). |
| 3 | CashoutStatusID | Withdrawal status: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 7=Rejected, etc. |
| 4 | RequestDate | When the withdrawal was submitted. |
| 5 | Amount | Withdrawal amount in the account currency. |
| 6 | Commission | Commission/fee deducted from the withdrawal. |
| 7 | Approved | Approval flag. |
| 8 | IPAddress | Customer IP at time of request. |
| 9 | ModificationDate | Last status change timestamp. |
| 10 | Remark | Internal remark set by operations (e.g., reversal description). |
| 11 | Comment | Customer-facing or manager comment on the withdrawal. |
| 12 | Fee | Additional fee. |
| 13 | FundingID | FK to `Billing.Funding` - the payment instrument for this withdrawal. |
| 14 | RequestorComments | Comments from the requestor at submission. |
| 15 | SuggestedBonusDeductionAmount | Suggested bonus deduction amount calculated during withdrawal submission. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | Billing.Withdraw | Filter | All (or date-filtered) withdrawals for this CID are returned. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawService (application) | - | Caller | Withdrawal service calls this to retrieve customer withdrawal history for validation and display. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetCustomerWithdrawals (procedure)
└── Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT subset of columns WHERE CID = @cid AND optional date filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No DB-layer dependents found | - | Called from withdrawal service application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTIMIZE FOR hint | Query hint | Forces optimizer to plan for @startTime = '2009-01-01' to always use CID-based index (prevents date-range scan on recent dates) |

---

## 8. Sample Queries

### 8.1 Get all withdrawals for a customer

```sql
EXEC Billing.WithdrawService_GetCustomerWithdrawals @cid = 12345, @startTime = NULL;
```

### 8.2 Get withdrawals from the last 6 months

```sql
EXEC Billing.WithdrawService_GetCustomerWithdrawals
    @cid = 12345,
    @startTime = DATEADD(MONTH, -6, GETDATE());
```

### 8.3 Get pending or in-process withdrawals for a customer

```sql
SELECT w.WithdrawID, w.CashoutStatusID, w.Amount, w.RequestDate, w.FundingID
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.CID = 12345
  AND w.CashoutStatusID IN (1, 2)
ORDER BY w.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetCustomerWithdrawals | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetCustomerWithdrawals.sql*
