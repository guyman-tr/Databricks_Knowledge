# Hedge.GetAggregatedAccountTransactionsByType

> Flexible multi-filter aggregation of account transactions by type, returning summed amounts per (account, server, instrument, type) combination with optional TVP-based filtering on all dimensions.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityAccountIDs, @HedgeServerIds, @TransactionTypeIDs (TVP filters), @StartDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the more flexible, production-grade evolution of `GetAggregatedAccountTransactions`. While that procedure returns only deposit/withdrawal totals for a single account, this procedure supports:
- Filtering by multiple liquidity accounts at once (via TVP)
- Filtering by multiple hedge servers at once (via TVP)
- Filtering by any set of transaction types (via TVP)
- Filtering by instrument (optional scalar)
- A mandatory start date filter for time-bounded queries

The result is grouped by (LiquidityAccountID, HedgeServerID, InstrumentID, TransactionTypeID), providing a detailed breakdown suitable for hedge cost analysis, funding attribution, and fee reporting across multiple accounts and servers simultaneously.

The "empty TVP = no filter" pattern (using COUNT) makes all TVP parameters effectively optional - passing an empty TVP is equivalent to "all values for this dimension".

---

## 2. Business Logic

### 2.1 Empty-TVP "Optional Filter" Pattern

**What**: When a TVP parameter has 0 rows, the corresponding filter is effectively disabled - all values for that dimension are included.

**Columns/Parameters Involved**: `@LiquidityAccountIDs`, `@HedgeServerIds`, `@TransactionTypeIDs`

**Rules**:
- `@LiquidityAccountIDs_Count = 0` - when the TVP has no rows, `LiquidityAccountID IN (SELECT ID ...)` is skipped entirely (the OR condition is true)
- `@HedgeServerIDs_Count = 0` - same pattern for server filtering
- `@TransactionTypeIDs` is handled differently: it uses an INNER JOIN (`Inner join @TransactionTypeIDs tt on hat.TransactionTypeID = tt.ID`) rather than the empty-TVP pattern. This means `@TransactionTypeIDs` is effectively REQUIRED to have at least one row - an empty TVP would return no results
- @InstrumentID = NULL means all instruments; any non-null value scopes to one instrument
- @StartDate is always applied (not optional)

**Diagram**:
```
@LiquidityAccountIDs_Count = 0?
  YES --> no account filter (all accounts)
  NO  --> WHERE LiquidityAccountID IN (@LiquidityAccountIDs)

@HedgeServerIDs_Count = 0?
  YES --> no server filter (all servers)
  NO  --> WHERE HedgeServerID IN (@HedgeServerIds)

@TransactionTypeIDs --> always required (INNER JOIN - empty TVP = no results)
@StartDate --> always applied (WHERE OccurredAtAccount > @StartDate)
@InstrumentID --> NULL = all instruments, value = specific instrument only
```

### 2.2 Full Group-By Aggregation

**What**: Results are grouped at the finest granularity - per (account, server, instrument, type) - preserving full breakdown for downstream analysis.

**Rules**:
- GROUP BY: LiquidityAccountID, HedgeServerID, InstrumentID, TransactionTypeID
- MAX(OccurredAtAccount) as `LastUpdateTime` - most recent transaction for this group
- SUM(Amount) as `TotalAmount` - total cash flow for this group
- InstrumentID is included in the GROUP BY even though it's nullable (instrument-specific transactions like overnight fees group separately from instrument-agnostic ones like deposits)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountIDs | Hedge.IDs READONLY | NO | - | CODE-BACKED | Memory-optimized TVP of integer account IDs to filter by. When empty (0 rows), the account filter is disabled and all accounts are included. When populated, only transactions for those accounts are returned. FK to `Trade.LiquidityAccounts.LiquidityAccountID`. |
| 2 | @HedgeServerIds | Hedge.IDs READONLY | NO | - | CODE-BACKED | Memory-optimized TVP of integer hedge server IDs to filter by. When empty (0 rows), the server filter is disabled. When populated, only transactions from those hedge servers are returned. FK to `Trade.HedgeServer.HedgeServerID`. |
| 3 | @TransactionTypeIDs | Hedge.IDs READONLY | NO | - | CODE-BACKED | Memory-optimized TVP of integer transaction type IDs to include (e.g., 1=Deposit, 2=Withdrawal, 5=Commission). REQUIRED to be non-empty - uses INNER JOIN so an empty TVP returns no rows. Specifies which transaction categories to aggregate. Values from `Dictionary.AccountTransactionType`. |
| 4 | @StartDate | datetime | NO | - | CODE-BACKED | Mandatory lower bound for the time window. Only transactions with `OccurredAtAccount > @StartDate` are included. Required - callers must provide a valid start date. |
| 5 | @InstrumentID | int | YES | NULL | CODE-BACKED | Optional instrument filter. When NULL (default), all instruments are included. When provided, scopes aggregation to transactions for that specific instrument (e.g., overnight fees for a specific trading instrument). |

**Output Columns**:

| Column | Description |
|--------|-------------|
| LiquidityAccountID | The account where transactions occurred |
| HedgeServerID | The hedge server that generated the transactions |
| InstrumentID | The instrument (nullable - NULL for account-level transactions) |
| TransactionTypeID | Transaction category (from @TransactionTypeIDs filter) |
| LastUpdateTime | MAX(OccurredAtAccount) - most recent transaction timestamp in this group |
| TotalAmount | SUM(Amount) - total cash flow for this (account, server, instrument, type) combination |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.AccountTransactions | Direct read with INNER JOIN on TVP | Source of all transaction data; joined to @TransactionTypeIDs TVP |
| @LiquidityAccountIDs param | Hedge.IDs | TVP parameter type | Memory-optimized TVP type for integer ID sets |
| @HedgeServerIds param | Hedge.IDs | TVP parameter type | Memory-optimized TVP type for integer ID sets |
| @TransactionTypeIDs param | Hedge.IDs | TVP parameter type | Memory-optimized TVP type for integer ID sets |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by hedge monitoring application for flexible multi-dimension transaction analysis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAggregatedAccountTransactionsByType (procedure)
├── Hedge.AccountTransactions (table) - transaction data source
└── Hedge.IDs (type) - TVP type used by all three TVP parameters
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountTransactions | Table | INNER JOIN with @TransactionTypeIDs and WHERE filters on all other dimensions |
| Hedge.IDs | User Defined Type | TVP parameter type for @LiquidityAccountIDs, @HedgeServerIds, @TransactionTypeIDs |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TransactionTypeIDs required | Business Rule | Uses INNER JOIN on @TransactionTypeIDs - empty TVP returns no rows. Callers must always provide at least one transaction type. |
| Empty-TVP optional filter | Design Pattern | @LiquidityAccountIDs and @HedgeServerIds use count-based optional filtering (count=0 means no filter). @TransactionTypeIDs does NOT - it uses INNER JOIN. |
| Memory-optimized TVPs | Performance | Hedge.IDs is MEMORY_OPTIMIZED - eliminates I/O overhead for TVP parameter passing. |

---

## 8. Sample Queries

### 8.1 Equivalent scalar query for deposit totals across all accounts

```sql
SELECT hat.LiquidityAccountID, hat.HedgeServerID, hat.InstrumentID,
       hat.TransactionTypeID,
       MAX(OccurredAtAccount) AS LastUpdateTime,
       SUM(Amount) AS TotalAmount
FROM Hedge.AccountTransactions hat WITH (NOLOCK)
WHERE hat.OccurredAtAccount > DATEADD(day, -30, GETUTCDATE())
  AND hat.TransactionTypeID IN (1, 2)  -- Deposits and Withdrawals
GROUP BY hat.LiquidityAccountID, hat.HedgeServerID, hat.InstrumentID, hat.TransactionTypeID
ORDER BY hat.LiquidityAccountID, hat.TransactionTypeID
```

### 8.2 Fee summary for specific accounts and servers

```sql
SELECT hat.LiquidityAccountID, hat.HedgeServerID, hat.InstrumentID,
       hat.TransactionTypeID,
       MAX(OccurredAtAccount) AS LastUpdateTime,
       SUM(Amount) AS TotalAmount
FROM Hedge.AccountTransactions hat WITH (NOLOCK)
WHERE hat.OccurredAtAccount > DATEADD(day, -7, GETUTCDATE())
  AND hat.TransactionTypeID IN (5, 8, 9)  -- Commission, Transaction Fees, Overnight Fees
  AND hat.LiquidityAccountID IN (1, 2, 3)
GROUP BY hat.LiquidityAccountID, hat.HedgeServerID, hat.InstrumentID, hat.TransactionTypeID
ORDER BY TotalAmount DESC
```

### 8.3 Overnight fee breakdown per instrument

```sql
SELECT hat.InstrumentID, hat.LiquidityAccountID,
       SUM(hat.Amount) AS TotalOvernightFees,
       COUNT(*) AS FeeCount
FROM Hedge.AccountTransactions hat WITH (NOLOCK)
WHERE hat.OccurredAtAccount > DATEADD(month, -1, GETUTCDATE())
  AND hat.TransactionTypeID = 9  -- Overnight Fees
  AND hat.InstrumentID IS NOT NULL
GROUP BY hat.InstrumentID, hat.LiquidityAccountID
ORDER BY TotalOvernightFees DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAggregatedAccountTransactionsByType | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAggregatedAccountTransactionsByType.sql*
