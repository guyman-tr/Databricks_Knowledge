# Hedge.GetAccountTransactions

> Returns all transaction records for a specified liquidity account, providing the full cash flow history (deposits, withdrawals, fees, commissions) for that account.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityAccountID - identifies the account whose transactions are retrieved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all transaction records for a specific liquidity provider account from `Hedge.AccountTransactions`. It provides the hedge monitoring system with the raw, unfiltered transaction history for a given account - every deposit, withdrawal, commission, fee, rebate, and other cash movement that has been recorded for that account.

Unlike `GetAggregatedAccountTransactions` (which returns only deposit/withdrawal totals) or `GetAccountTransactionsData` (which filters by date and groups by type), this procedure returns individual transaction records with full detail including free-text comments, manual flag, and instrument linkage. This makes it suitable for detailed account audit queries, reconciliation tasks, and diagnostic investigation.

---

## 2. Business Logic

### 2.1 Full Account Transaction Retrieval

**What**: Returns every transaction row for the specified account, ordered by the table's clustered index (OccurredAtAccount, HedgeServerID, TransactionTypeID).

**Columns/Parameters Involved**: `@LiquidityAccountID`, all `Hedge.AccountTransactions` columns

**Rules**:
- No date filter - all historical records are returned (the table has no automatic archiving beyond what DeleteRecordsFromHedgingTables and other procs provide)
- No TransactionTypeID filter - all 13 types are returned (Deposit, Withdrawal, Refund, Compensation, Commission, Adjustment, Interest, Transaction Fees, Overnight Fees, Conversion, Rebate, Manual Cost, System Cost)
- `IsManual` flag distinguishes system-generated transactions from those manually entered by operations staff
- `InstrumentID` is nullable - only populated for instrument-specific transactions (e.g., overnight fees, conversions)

**Transaction Type Map** (inherited from `Hedge.AccountTransactions` doc):
| TransactionTypeID | TransactionTypeName |
|---|---|
| 1 | Deposit |
| 2 | Withdrawal |
| 3 | Refund |
| 4 | Compensation |
| 5 | Commission |
| 6 | Adjustment |
| 7 | Interest |
| 8 | Transaction Fees |
| 9 | Overnight Fees |
| 10 | Conversion |
| 11 | Rebate |
| 12 | Manual Cost |
| 13 | System Cost |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity account to retrieve transactions for. FK to `Trade.LiquidityAccounts.LiquidityAccountID`. The WHERE clause filters `Hedge.AccountTransactions.LiquidityAccountID = @LiquidityAccountID`. All transaction rows for this account are returned. |

**Output Columns** (all columns from `Hedge.AccountTransactions`):

| Column | Description |
|--------|-------------|
| LiquidityAccountID | The liquidity account this transaction belongs to |
| HedgeServerID | The hedge server that recorded or originated this transaction |
| TransactionTypeID | Transaction category: 1=Deposit, 2=Withdrawal, 3-13=fee/revenue types |
| Amount | Cash flow amount in USD (decimal(14,4)) |
| IsManual | 1=manually entered by operations, 0=system-generated |
| OccurredAtAccount | Provider-reported timestamp of when the transaction occurred |
| Comment | Free-text description or reference (nullable) |
| InstrumentID | Linked instrument (nullable - only for instrument-specific transactions like overnight fees) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.AccountTransactions | Direct read (SELECT) | Reads all transaction rows for the specified liquidity account |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by application services that need the full transaction history for a specific liquidity account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAccountTransactions (procedure)
└── Hedge.AccountTransactions (table) - SELECT source
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountTransactions | Table | SELECT all columns WHERE LiquidityAccountID = @LiquidityAccountID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Simple filter | Design | Single equality filter on LiquidityAccountID - no date range, no type filter, returns all records |
| No NOLOCK | Note | Does not use WITH (NOLOCK) or READ UNCOMMITTED - may experience blocking on heavily written accounts |

---

## 8. Sample Queries

### 8.1 Retrieve all transactions for a specific account

```sql
SELECT [LiquidityAccountID],
       [HedgeServerID],
       [TransactionTypeID],
       [Amount],
       [IsManual],
       [OccurredAtAccount],
       [Comment],
       [InstrumentID]
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE LiquidityAccountID = 1
ORDER BY OccurredAtAccount DESC
```

### 8.2 Summary by transaction type for an account

```sql
SELECT TransactionTypeID,
       SUM(Amount) AS TotalAmount,
       COUNT(*) AS TransactionCount,
       MIN(OccurredAtAccount) AS FirstOccurrence,
       MAX(OccurredAtAccount) AS LastOccurrence
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE LiquidityAccountID = 1
GROUP BY TransactionTypeID
ORDER BY TransactionTypeID
```

### 8.3 Recent manual transactions for audit purposes

```sql
SELECT TOP 50 *
FROM Hedge.AccountTransactions WITH (NOLOCK)
WHERE LiquidityAccountID = 1
  AND IsManual = 1
ORDER BY OccurredAtAccount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAccountTransactions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAccountTransactions.sql*
