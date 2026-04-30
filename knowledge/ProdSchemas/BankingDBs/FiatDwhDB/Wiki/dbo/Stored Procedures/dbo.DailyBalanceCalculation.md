# dbo.DailyBalanceCalculation

> Complex scheduled procedure that calculates daily movements and end-of-day balances for all customers by aggregating settled transaction amounts over a configurable date range.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Multi-step ETL: FiatTransactionsStatuses -> DailyMovements + CustomerEODBalance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DailyBalanceCalculation is the core scheduled job that computes daily movements and end-of-day (EOD) balances for all customers. It processes settled transactions over a configurable lookback period (@ProcessDate days, default 31), aggregates them by customer/currency/date into DailyMovements, then computes cumulative EOD balances in CustomerEODBalance.

This is the engine behind the DWH's balance reporting capability. Without it, dbo.CustomerEODBalance and dbo.DailyMovements would have no data.

---

## 2. Business Logic

### 2.1 Multi-Step ETL Pipeline

**What**: Aggregates settled transactions into daily movements, then computes cumulative EOD balances.

**Columns/Parameters Involved**: `@ProcessDate` (lookback days)

**Rules**:
- Step 1: Find last transaction per GCID from DailyMovements (watermark)
- Step 2: Find new settled transactions since the watermark
- Step 3: Aggregate new transactions by GCID + Currency + Date into DailyMovements
- Step 4: UPDATE existing DailyMovements rows or INSERT new ones
- Step 5: Compute EODBalance = previous balance + daily movements
- Step 6: UPDATE existing CustomerEODBalance rows or INSERT new ones
- Uses multiple temp tables (#LastTransactionCreatedForGCID, #NewTransactions, #NewTransactionAggregate, #EODBalanceForNewTransaction, etc.)
- Processes FiatTransactionsStatuses (settled amounts) joined with FiatTransactions, FiatAccount, FiatCurrencyBalances

**Diagram**:
```
FiatTransactionsStatuses (settled txns)
      |
      v
#NewTransactions (filtered by date range + watermark)
      |
      v
#NewTransactionAggregate (GROUP BY GCID, Currency, Date)
      |
      +---> UPDATE/INSERT DailyMovements
      |
      v
Previous CustomerEODBalance + DailyMovements
      |
      v
UPDATE/INSERT CustomerEODBalance
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessDate | int | YES | 31 | CODE-BACKED | Number of days to look back for new transactions. Default 31 days. Controls the processing window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatTransactionsStatuses | Read | Source of settled amounts |
| SELECT | dbo.FiatTransactions | Read | Transaction details |
| SELECT | dbo.FiatAccount | Read | Customer context |
| SELECT | dbo.FiatCurrencyBalances | Read | Currency info |
| INSERT/UPDATE | dbo.DailyMovements | Write | Daily aggregated movements |
| INSERT/UPDATE | dbo.CustomerEODBalance | Write | EOD balance snapshots |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DailyBalanceCalculation (procedure)
├── dbo.FiatTransactionsStatuses (table)
├── dbo.FiatTransactions (table)
├── dbo.FiatAccount (table)
├── dbo.FiatCurrencyBalances (table)
├── dbo.DailyMovements (table)
└── dbo.CustomerEODBalance (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactionsStatuses | Table | Source data |
| dbo.FiatTransactions | Table | Transaction details |
| dbo.FiatAccount | Table | Customer context |
| dbo.FiatCurrencyBalances | Table | Currency info |
| dbo.DailyMovements | Table | Write target |
| dbo.CustomerEODBalance | Table | Write target |

### 6.2 Objects That Depend On This

No dependents found (scheduled job).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run with default 31-day lookback
```sql
EXEC dbo.DailyBalanceCalculation;
```

### 8.2 Run with custom 7-day lookback
```sql
EXEC dbo.DailyBalanceCalculation @ProcessDate = 7;
```

### 8.3 Verify results after run
```sql
SELECT TOP 10 * FROM dbo.DailyMovements WITH (NOLOCK) ORDER BY Created DESC;
SELECT TOP 10 * FROM dbo.CustomerEODBalance WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB is a reporting database; balance calculation is the core ETL process |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.DailyBalanceCalculation | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.DailyBalanceCalculation.sql*
