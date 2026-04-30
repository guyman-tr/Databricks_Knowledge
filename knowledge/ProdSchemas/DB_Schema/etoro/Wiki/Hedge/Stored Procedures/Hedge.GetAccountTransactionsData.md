# Hedge.GetAccountTransactionsData

> Aggregates hedge account transaction amounts since a reference date, grouped by hedge server, liquidity account, and transaction type - parallel companion to GetAccountClosedPositionsData in the hedge cost monitoring pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReferenceDate, @HedgeServers - filter parameters for recent transaction window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves aggregated transaction amounts from `Hedge.AccountTransactions` for a specified time window and set of hedge servers, grouped by (HedgeServerID, LiquidityAccountID, TransactionTypeID). It mirrors the design pattern of `GetAccountClosedPositionsData` but for cash flow transactions rather than position P&L.

The result feeds the hedge cost monitoring service's cash flow analysis - tracking total deposits, withdrawals, commissions, overnight fees, and other transaction types that occurred in hedge server accounts since the last check. This enables the service to compute net cash flows per account and identify funding patterns or unexpected fees.

Like its companion procedure, this SP uses dynamic SQL with a comma-separated `@HedgeServers` string and is explicitly designed for high-frequency calls (the developer comment notes the design was chosen to avoid repeated CSV/XML parsing).

---

## 2. Business Logic

### 2.1 Transaction Aggregation by Type

**What**: Returns the sum of all transaction amounts per (HedgeServerID, LiquidityAccountID, TransactionTypeID) since a reference date.

**Columns/Parameters Involved**: `@ReferenceDate`, `@HedgeServers`, `Amount`, `OccurredAtAccount`, `TransactionTypeID`

**Rules**:
- Only transactions where `OccurredAtAccount > @ReferenceDate` are included (watermark pattern, same as companion proc)
- `@HedgeServers` is a comma-separated integer list (e.g., "1,3,5,6") injected directly into the IN clause
- `SUM(Amount)` per group - total cash flow amount for this type/server/account combination
- `MAX(OccurredAtAccount)` - most recent transaction timestamp for watermark tracking
- Grouping by TransactionTypeID allows downstream pivot-style analysis of each transaction category (deposits vs fees vs commissions)

**Transaction Type Map** (from `Hedge.AccountTransactions` doc):
| TypeID | Name | Notes |
|---|---|---|
| 1 | Deposit | Cash added to account |
| 2 | Withdrawal | Cash removed |
| 3-13 | Fee/revenue categories | See full map in AccountTransactions doc |

### 2.2 Dynamic SQL Pattern (Same as GetAccountClosedPositionsData)

**What**: @HedgeServers is directly concatenated into the SQL string to avoid CSV parsing overhead on a high-frequency call path.

**Rules**:
- `@ReferenceDate` IS properly parameterized via sp_executesql - no injection risk for the date
- `@HedgeServers` is concatenated directly - caller must provide a validated integer list
- Same pattern and same comment as `GetAccountClosedPositionsData` (identical design rationale)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferenceDate | datetime | NO | - | CODE-BACKED | Lower bound for the transaction window. Only `AccountTransactions` rows with `OccurredAtAccount > @ReferenceDate` are included. Set by the monitoring service as a watermark of the last processed timestamp. |
| 2 | @HedgeServers | varchar(300) | NO | - | CODE-BACKED | Comma-separated list of HedgeServerID integers to include (e.g., "1,3,5,6"). Directly concatenated into the IN clause of dynamic SQL - must be a validated integer list from the caller. Same constraint and format as in `GetAccountClosedPositionsData`. |

**Output Columns** (from the dynamic SQL SELECT):

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.AccountTransactions | The hedge server that generated this transaction group |
| LiquidityAccountID | Hedge.AccountTransactions | The account where the transactions occurred |
| TransactionTypeID | Hedge.AccountTransactions | Transaction category: 1=Deposit, 2=Withdrawal, 3-13=other types |
| Amount | SUM(Amount) | Total cash flow for this (server, account, type) combination since @ReferenceDate |
| OccurredAtAccount | MAX(OccurredAtAccount) | Most recent transaction timestamp for this group |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.AccountTransactions | Direct read (SELECT) | Source of transaction data - cash flows in hedge liquidity accounts |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Part of the hedge cost monitoring service call pattern (see `GetAccountClosedPositionsData` for the parallel companion).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAccountTransactionsData (procedure)
└── Hedge.AccountTransactions (table) - SELECT source
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountTransactions | Table | SELECT with GROUP BY - aggregates transaction amounts by (HedgeServerID, LiquidityAccountID, TransactionTypeID) since a reference date |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Design | @ReferenceDate parameterized properly; @HedgeServers concatenated (injection risk) |
| SET NOCOUNT ON | Performance | Suppresses row count messages for high-frequency call path |
| Parallel design | Pattern | Identical structure to `GetAccountClosedPositionsData` - both serve the hedge cost monitoring service |

---

## 8. Sample Queries

### 8.1 Equivalent of what the procedure returns (with explicit NOLOCK)

```sql
DECLARE @ReferenceDate datetime = DATEADD(hour, -1, GETUTCDATE())

SELECT HedgeServerID, LiquidityAccountID, TransactionTypeID,
       SUM(Amount) AS Amount,
       MAX(OccurredAtAccount) AS OccurredAtAccount
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE OccurredAtAccount > @ReferenceDate
  AND HedgeServerID IN (1,2,3)
GROUP BY HedgeServerID, LiquidityAccountID, TransactionTypeID
ORDER BY HedgeServerID, LiquidityAccountID, TransactionTypeID
```

### 8.2 Net cash flow per account type (deposits minus withdrawals)

```sql
SELECT LiquidityAccountID,
       SUM(CASE WHEN TransactionTypeID = 1 THEN Amount ELSE 0 END) AS TotalDeposits,
       SUM(CASE WHEN TransactionTypeID = 2 THEN Amount ELSE 0 END) AS TotalWithdrawals,
       SUM(CASE WHEN TransactionTypeID = 1 THEN Amount ELSE -Amount END) AS NetCashFlow
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE OccurredAtAccount > DATEADD(day, -7, GETUTCDATE())
GROUP BY LiquidityAccountID
ORDER BY NetCashFlow DESC
```

### 8.3 Transaction volume by type for monitoring

```sql
SELECT TransactionTypeID,
       COUNT(*) AS TransactionCount,
       SUM(Amount) AS TotalAmount
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE OccurredAtAccount > DATEADD(hour, -24, GETUTCDATE())
GROUP BY TransactionTypeID
ORDER BY TransactionTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAccountTransactionsData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAccountTransactionsData.sql*
