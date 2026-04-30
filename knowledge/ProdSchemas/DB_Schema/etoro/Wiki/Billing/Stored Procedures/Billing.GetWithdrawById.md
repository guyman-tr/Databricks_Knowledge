# Billing.GetWithdrawById

> Fetches withdrawal record(s) from Billing.Withdraw by ID: supports both a single WithdrawalID scalar and a bulk BackOffice.IDs table-valued parameter, returning full withdrawal details including status, amounts, payment method, FlowID, and manager metadata.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawalID (scalar) OR @WithdrawalIDs (TVP); returns one row per matched withdrawal |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWithdrawById retrieves withdrawal record details from `Billing.Withdraw` for one or more withdrawal IDs. It is the canonical lookup procedure for withdrawal data in the billing service, supporting both:
- **Single lookup**: Pass @WithdrawalID (INT) for backward compatibility (original pattern, MIMOPSA-6589, May 2022)
- **Bulk lookup**: Pass @WithdrawalIDs (BackOffice.IDs TVP) for fetching multiple withdrawals in one call (added Jan 2024)
- **Combined**: Both can be passed simultaneously; the procedure merges both sources into a single internal table

The procedure merges both input sources into a local table variable `@tblWithdrawalIDs`, then joins to `Billing.Withdraw` - a clean design that avoids duplicate result rows from having both inputs active simultaneously.

FlowID was added Aug 2024 (Itay) - likely a saga/orchestration flow identifier for the withdrawal processing pipeline.

Referenced in "Transaction Details EP - Refactor" (MG) and "Update Withdraw comment Api" (OG/MG).

---

## 2. Business Logic

### 2.1 Dual-Input ID Merging

**What**: Both scalar and TVP inputs are merged into a single internal ID table for the JOIN.

**Columns/Parameters Involved**: `@WithdrawalID`, `@WithdrawalIDs`, `@tblWithdrawalIDs`

**Rules**:
- `DECLARE @tblWithdrawalIDs AS BackOffice.IDs` - local table variable of the same type as the TVP
- `IF @WithdrawalID IS NOT NULL`: inserts the scalar ID into @tblWithdrawalIDs
- `IF EXISTS(SELECT 1 FROM @WithdrawalIDs)`: inserts all rows from the TVP into @tblWithdrawalIDs
- If both are provided: both IDs are merged (no deduplication - caller should avoid overlapping inputs)
- If neither is provided: @tblWithdrawalIDs is empty -> INNER JOIN returns 0 rows (no error)

### 2.2 Withdrawal Data Fetch

**What**: Returns all relevant fields from Billing.Withdraw for the matched IDs.

**Columns/Parameters Involved**: All selected columns from `Billing.Withdraw`

**Rules**:
- `INNER JOIN @tblWithdrawalIDs AS WI ON BW.WithdrawID = WI.ID` - only returns rows for IDs in the merged set
- `ISNULL(BW.FundingTypeID, 0)` AS PaymentMethodTypeID - 0 if no funding type (manual/non-card withdrawals)
- `ISNULL(BW.FundingID, 0)` AS PaymentMethodID - 0 if no funding record linked
- `BW.Remark` aliased as `UserComment` - the customer-facing note on the withdrawal
- `BW.Comment` - internal/manager comment
- `CID` aliased as `CustomerId` - customer identifier

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawalID | INT | YES | NULL | CODE-BACKED | Single withdrawal ID for backward-compatible single-record lookup. If NULL, only @WithdrawalIDs is used. |
| 2 | @WithdrawalIDs | BackOffice.IDs | NO | (empty) | CODE-BACKED | Table-valued parameter (READONLY) for bulk withdrawal ID lookup. BackOffice.IDs is a user-defined table type with a single INT column (ID). If empty, only @WithdrawalID is used. |
| - | CustomerId | INT | NO | - | CODE-BACKED | Customer ID who owns this withdrawal. Aliased from Billing.Withdraw.CID. |
| - | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal record from Billing.Withdraw. |
| - | Status | INT | NO | - | CODE-BACKED | Current cashout status. Aliased from Billing.Withdraw.CashoutStatusID. |
| - | Amount | DECIMAL | YES | - | CODE-BACKED | Withdrawal amount requested. |
| - | CurrencyID | INT | YES | - | CODE-BACKED | Currency of the withdrawal amount. |
| - | AccountCurrencyID | INT | YES | - | CODE-BACKED | Currency of the customer's account (may differ from withdrawal currency). |
| - | PaymentMethodTypeID | INT | NO | 0 | CODE-BACKED | Payment method type (FundingTypeID). ISNULL to 0 if not set (e.g., manual/bank transfer withdrawals). |
| - | PaymentMethodID | INT | NO | 0 | CODE-BACKED | Specific payment method record (FundingID). ISNULL to 0 if not linked to a funding record. |
| - | Fee | DECIMAL | YES | - | CODE-BACKED | Fee charged for this withdrawal. |
| - | ModificationDate | DATETIME | YES | - | CODE-BACKED | Last modification timestamp of the withdrawal record. |
| - | RequestDate | DATETIME | YES | - | CODE-BACKED | Date the withdrawal was requested. |
| - | UserComment | NVARCHAR | YES | - | CODE-BACKED | Customer-facing note on the withdrawal. Aliased from Billing.Withdraw.Remark. |
| - | ManagerID | INT | YES | - | CODE-BACKED | ID of the manager who last acted on this withdrawal. |
| - | Comment | NVARCHAR | YES | - | CODE-BACKED | Internal manager/ops comment on the withdrawal. |
| - | ExTransactionID | VARCHAR | YES | - | CODE-BACKED | External transaction ID from the payment gateway or cashout provider. |
| - | Approved | BIT | YES | - | CODE-BACKED | Whether the withdrawal has been approved. |
| - | WithdrawTypeID | INT | YES | - | CODE-BACKED | Type of withdrawal (e.g., standard cashout, wire transfer, crypto). |
| - | FlowID | INT | YES | - | CODE-BACKED | Saga/orchestration flow identifier for the withdrawal processing pipeline. Added Aug 2024 (Itay). Used to correlate with the async withdrawal flow system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID (all columns) | Billing.Withdraw | SELECT via INNER JOIN | Source of all withdrawal data |
| @WithdrawalIDs parameter type | BackOffice.IDs | TVP type | User-defined table type used for the bulk input parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Transaction Details service | @WithdrawalID / @WithdrawalIDs | EXEC | Withdrawal record lookup for transaction details API (MIMOPSA-6589) |
| Update Withdraw comment API | @WithdrawalID | EXEC | Used to verify/fetch withdrawal before updating comment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWithdrawById (procedure)
+-- Billing.Withdraw (table) [source of all withdrawal data]
+-- BackOffice.IDs (user defined type) [@WithdrawalIDs TVP type]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | INNER JOIN to merged ID set; source of all returned withdrawal fields |
| BackOffice.IDs | User Defined Type | Type of @WithdrawalIDs TVP parameter; single INT column (ID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Transaction Details EP | External | Withdrawal data for transaction detail views (MIMOPSA-6589) |
| Update Withdraw comment API | External | Fetch before update pattern for withdrawal comment updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Empty inputs -> 0 rows | Behavior | If both @WithdrawalID=NULL and @WithdrawalIDs is empty, @tblWithdrawalIDs is empty and INNER JOIN returns no rows |
| No deduplication on merge | Design | If same ID appears in both @WithdrawalID and @WithdrawalIDs, it may be returned twice |
| NOLOCK | Concurrency | Billing.Withdraw read with NOLOCK; consistent with read-heavy usage pattern |
| BackOffice.IDs READONLY | Design | TVP must be READONLY per SQL Server TVP rules; the procedure cannot modify the input |
| FlowID nullable | History | Added Aug 2024; older withdrawals will have NULL FlowID |

---

## 8. Sample Queries

### 8.1 Single withdrawal lookup

```sql
-- Pass an empty TVP for the required parameter
DECLARE @emptyIDs BackOffice.IDs
EXEC [Billing].[GetWithdrawById]
    @WithdrawalID = 12345,
    @WithdrawalIDs = @emptyIDs
```

### 8.2 Bulk withdrawal lookup

```sql
DECLARE @ids BackOffice.IDs
INSERT INTO @ids (ID) VALUES (12345), (12346), (12347)

EXEC [Billing].[GetWithdrawById]
    @WithdrawalID = NULL,
    @WithdrawalIDs = @ids
```

### 8.3 Equivalent direct query

```sql
SELECT
    CID AS CustomerId, WithdrawID, CashoutStatusID AS Status,
    Amount, CurrencyID, AccountCurrencyID,
    ISNULL(FundingTypeID, 0) AS PaymentMethodTypeID,
    ISNULL(FundingID, 0) AS PaymentMethodID,
    Fee, ModificationDate, RequestDate,
    Remark AS UserComment, ManagerID, Comment,
    ExTransactionID, Approved, WithdrawTypeID, FlowID
FROM [Billing].[Withdraw] WITH (NOLOCK)
WHERE WithdrawID = 12345
```

---

## 9. Atlassian Knowledge Sources

**Confluence**:
- "Transaction Details EP - Refactor" (/spaces/MG) - transaction details API refactoring that uses this procedure (MIMOPSA-6589)
- "Update Withdraw comment Api" (/spaces/OG and /spaces/MG) - API for updating withdrawal comments; uses this SP for pre-fetch

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 2 Confluence (Transaction Details EP, Update Withdraw comment API) + 1 Jira (MIMOPSA-6589) | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWithdrawById | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWithdrawById.sql*
