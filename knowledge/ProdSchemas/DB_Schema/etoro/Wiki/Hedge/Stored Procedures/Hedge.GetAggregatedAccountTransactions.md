# Hedge.GetAggregatedAccountTransactions

> Returns total deposit and withdrawal amounts for a specific liquidity account (optionally filtered by hedge server), surfacing the net funding state of the account.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityAccountID (required), @HedgeServerID (optional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure calculates total deposits and total withdrawals for a hedge server liquidity account, returning a single summary row with two aggregated amounts. It provides a high-level view of the account's funding history - how much money has been deposited into and withdrawn from the account since tracking began.

The result enables the hedge monitoring system to quickly assess whether an account is well-funded (deposits >> withdrawals) or has had significant capital drawn down. This is used for account health monitoring and hedge cost analysis at the account level.

The optional `@HedgeServerID` parameter allows filtering transactions to a specific hedge server context, or passing NULL to aggregate across all hedge servers that have used this account.

---

## 2. Business Logic

### 2.1 Two-Category Aggregation (Deposits vs Withdrawals)

**What**: Exactly two transaction categories are aggregated - deposits (TransactionTypeID=1) and withdrawals (TransactionTypeID=2). All other types are excluded.

**Columns/Parameters Involved**: `TransactionTypeID`, `Amount`

**Rules**:
- `TransactionTypeID = 1` = Deposit. SUM(Amount) returned as `TotalDepositsAmount`
- `TransactionTypeID = 2` = Withdrawal. SUM(Amount) returned as `TotalWithdrawsAmount`
- All other TransactionTypeIDs (3-13: refunds, commissions, fees, etc.) are NOT included
- The comment in the code for the withdrawal query incorrectly says "TransactionTypeID 1 means Deposits" - this is a copy-paste error; the WHERE correctly uses `TransactionTypeID = 2`
- If no transactions exist for a category, SUM returns NULL (not 0) - the variable remains NULL

### 2.2 Optional HedgeServerID Filter

**What**: @HedgeServerID can be NULL to aggregate across all servers for the account, or set to a specific value to scope to one server.

**Columns/Parameters Involved**: `@HedgeServerID`, `HedgeServerID`

**Rules**:
- `HedgeServerID = ISNULL(@HedgeServerID, HedgeServerID)` - the ISNULL trick: when @HedgeServerID is NULL, the condition `HedgeServerID = HedgeServerID` is always true (no filter)
- When @HedgeServerID is provided, only transactions from that specific server are included
- The result row always returns `@HedgeServerID` as the output HedgeServerID (may be NULL if not specified)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | YES | NULL | CODE-BACKED | Optional hedge server filter. When NULL (default), aggregates transactions across ALL hedge servers for the account. When provided, scopes the aggregation to that specific server. Uses `ISNULL(@HedgeServerID, HedgeServerID)` pattern to implement optional filtering. |
| 2 | @LiquidityAccountID | int | NO | - | CODE-BACKED | Required. The liquidity account to aggregate transactions for. All deposit and withdrawal records for this account are summed. FK to `Trade.LiquidityAccounts.LiquidityAccountID`. |

**Output Columns** (single summary row):

| Column | Description |
|--------|-------------|
| HedgeServerID | The @HedgeServerID parameter value (may be NULL if not filtered) |
| LiquidityAccountID | The @LiquidityAccountID parameter value |
| TotalDepositsAmount | SUM of all amounts where TransactionTypeID=1. NULL if no deposits found. |
| TotalWithdrawsAmount | SUM of all amounts where TransactionTypeID=2. NULL if no withdrawals found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.AccountTransactions | Direct read (2 queries) | Reads TransactionTypeID=1 and TransactionTypeID=2 rows separately, each with SUM(Amount) |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by hedge monitoring application for account-level funding summary.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAggregatedAccountTransactions (procedure)
└── Hedge.AccountTransactions (table) - two SELECT aggregations (TransactionTypeID=1 and TypeID=2)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountTransactions | Table | Two separate SUM queries: one for deposits (TransactionTypeID=1), one for withdrawals (TransactionTypeID=2) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Limited aggregation | Business Rule | Only TransactionTypeID 1 and 2 are aggregated - commissions, fees, rebates (3-13) are excluded |
| NULL return risk | Note | Both SUM variables can return NULL if no transactions exist for that type; callers should handle NULL amounts |
| Code comment error | Note | The withdrawal query has a copy-paste error: `--TransactionTypeID 1 means Deposits` on the withdrawal block (TypeID=2). This is a documentation bug in the SQL code, not a logic bug. |

---

## 8. Sample Queries

### 8.1 Equivalent aggregation query

```sql
SELECT
    NULL AS HedgeServerID,  -- or specific server
    1 AS LiquidityAccountID,
    SUM(CASE WHEN TransactionTypeID = 1 THEN Amount ELSE 0 END) AS TotalDepositsAmount,
    SUM(CASE WHEN TransactionTypeID = 2 THEN Amount ELSE 0 END) AS TotalWithdrawsAmount
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE LiquidityAccountID = 1
  AND TransactionTypeID IN (1, 2)
```

### 8.2 Net funding position (deposits minus withdrawals)

```sql
SELECT
    LiquidityAccountID,
    SUM(CASE WHEN TransactionTypeID = 1 THEN Amount ELSE 0 END) AS TotalDeposits,
    SUM(CASE WHEN TransactionTypeID = 2 THEN Amount ELSE 0 END) AS TotalWithdrawals,
    SUM(CASE WHEN TransactionTypeID = 1 THEN Amount ELSE -Amount END) AS NetFunding
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE TransactionTypeID IN (1, 2)
GROUP BY LiquidityAccountID
ORDER BY LiquidityAccountID
```

### 8.3 Funding history for a specific account and server

```sql
SELECT OccurredAtAccount, HedgeServerID, TransactionTypeID, Amount, Comment
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE LiquidityAccountID = 1
  AND TransactionTypeID IN (1, 2)
  AND HedgeServerID = 2
ORDER BY OccurredAtAccount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAggregatedAccountTransactions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAggregatedAccountTransactions.sql*
