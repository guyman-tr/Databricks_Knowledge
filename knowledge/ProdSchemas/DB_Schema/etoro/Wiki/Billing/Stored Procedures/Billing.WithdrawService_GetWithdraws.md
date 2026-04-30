# Billing.WithdrawService_GetWithdraws

> Returns all withdrawal requests for a customer (optionally filtered by start date), providing the core withdrawal summary columns needed by the WithdrawalService.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid - the customer whose withdrawals are retrieved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetWithdraws` retrieves the withdrawal history for a specific customer from `Billing.Withdraw`. It is the standard customer-facing read procedure for the withdrawal list - used when the WithdrawalService needs to show a customer all of their withdrawal requests (past and present).

The procedure exposes a focused set of columns (WithdrawID, status, date, amount, approval flag, fee, and funding instrument) rather than the full 30+ column `Billing.Withdraw` row. This is a deliberate API contract: the caller receives exactly what is needed for displaying the withdrawal list and for driving follow-on actions.

The optional `@startTime` parameter enables incremental/paginated fetches - by providing a date, callers can retrieve only recent withdrawals rather than the full history. The implementation uses a temp table with an index on `RequestDate` for query performance, a pattern refined through multiple revisions (initial performance pass on 2021-01-03, further revision for MIMOPS-5535 on 2021-11-14).

The DDL comment "Taking Fee from Withdraw table directly" (PAYUA-3811, 2021-09-05) indicates that the Fee column was previously derived from a calculation or a different source - it is now taken directly from `Billing.Withdraw.Fee`.

---

## 2. Business Logic

### 2.1 Optional Date Filter

**What**: @startTime restricts the result set to withdrawals requested on or after the given date.

**Columns/Parameters Involved**: `@startTime`, `RequestDate`

**Rules**:
- If `@startTime IS NULL` (default): all withdrawals for the customer are returned regardless of date
- If `@startTime` is provided: only rows where `w.RequestDate >= @startTime` are included
- Implemented as `(w.RequestDate >= @startTime OR @startTime IS NULL)` - the OR branch handles the null case without a separate code path

### 2.2 Temp Table Performance Pattern

**What**: Results are staged in a temp table with an index before being returned to reduce query compilation and execution overhead.

**Columns/Parameters Involved**: `#TMP_Withdraw`, `WithdrawID` (PK), `RequestDate` (indexed)

**Rules**:
- `#TMP_Withdraw` has `WithdrawID` as PRIMARY KEY to guarantee uniqueness
- `TMP_IX_1` on `RequestDate` supports range scans against the temp table
- Pattern was added during 2021 performance revisions (MIMOPS-5535)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INTEGER | NO | - | CODE-BACKED | Required. Customer ID. Filters `Billing.Withdraw` to only this customer's withdrawal records. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional. Earliest RequestDate to include. NULL returns all withdrawals for the customer regardless of date. Used for incremental fetches or limiting result set size. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | PK of the withdrawal request. From `Billing.Withdraw.WithdrawID`. |
| 2 | CashoutStatusID | int | NO | - | CODE-BACKED | Current lifecycle status of the withdrawal. Key values: 1=Pending, 2=InProcess, 3=Processed (completed), 4=Cancelled. From `Billing.Withdraw.CashoutStatusID`. See Billing.Withdraw Section 2.1 for full status distribution. |
| 3 | RequestDate | datetime | NO | - | CODE-BACKED | When the customer submitted this withdrawal request. From `Billing.Withdraw.RequestDate`. The date filter @startTime is applied against this column. |
| 4 | Amount | money | YES | - | CODE-BACKED | Requested withdrawal amount in the customer's account currency (USD for most customers). From `Billing.Withdraw.Amount`. |
| 5 | Approved | bit | YES | - | CODE-BACKED | Approval flag for the withdrawal request. From `Billing.Withdraw.Approved`. 1=approved for processing, 0/NULL=pending approval. |
| 6 | Fee | money | YES | - | CODE-BACKED | Withdrawal fee charged to the customer, taken directly from `Billing.Withdraw.Fee`. Changed in PAYUA-3811 to read from the Withdraw table directly rather than being derived. |
| 7 | FundingID | int | YES | - | CODE-BACKED | FK to `Billing.Funding`. The payment instrument (card, bank account, wallet) designated for this withdrawal. From `Billing.Withdraw.FundingID`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | Billing.Withdraw | Reader | Filters on CID to retrieve customer-specific withdrawal history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawalService (application) | @cid, @startTime | Caller | Called to retrieve the withdrawal list for a customer for display in the eToro platform UI |
| Billing.WithdrawService_GetWithdrawsWithoutRedeems | (EXEC) | Procedure call | Wraps this SP, filtering result to exclude withdrawals linked to a Redeem record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetWithdraws (procedure)
└── Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary source - filtered by CID and optional RequestDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WithdrawalService (application) | External application | Caller - retrieves withdrawal list for customer-facing display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| #TMP_Withdraw PK | Design | WithdrawID as temp table PK guarantees one row per withdrawal and optimizes lookup |
| TMP_IX_1 on RequestDate | Performance | Supports range scans on the temp table result set |
| Fee source | Business Rule | Fee is taken directly from Billing.Withdraw.Fee as of PAYUA-3811 (2021-09-05). Previously derived from a different source. |

---

## 8. Sample Queries

### 8.1 Get all withdrawals for a customer

```sql
EXEC Billing.WithdrawService_GetWithdraws
    @cid = 123456;
```

### 8.2 Get withdrawals since a specific date

```sql
EXEC Billing.WithdrawService_GetWithdraws
    @cid = 123456,
    @startTime = '2025-01-01';
```

### 8.3 Check pending/in-process withdrawals directly

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,
    w.RequestDate,
    w.Amount,
    w.Fee,
    w.FundingID
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.CID = 123456
  AND w.CashoutStatusID IN (1, 2)  -- Pending or InProcess
ORDER BY w.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-5535 (referenced in DDL comment) | Jira | Performance revision - introduced temp table with index pattern |
| PAYUA-3811 (referenced in DDL comment) | Jira | Changed Fee column to read directly from Billing.Withdraw.Fee rather than being derived |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira (2 tickets referenced in DDL comments) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetWithdraws | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetWithdraws.sql*
