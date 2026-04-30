# dbo.DailyMovements

> Daily aggregated transaction movements per customer per currency, used as the input for end-of-day balance calculation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

DailyMovements stores the net aggregated transaction amount for each customer, per currency, per business day. Each row represents the total money movement (deposits minus withdrawals, payments, transfers, etc.) for a single customer in a single currency on a single day. This table is the primary input for the EOD balance calculation.

This table exists because calculating end-of-day balances requires knowing each day's net movement. Rather than scanning all individual transactions each time, movements are pre-aggregated into this table, making the DailyBalanceCalculation procedure efficient and the daily balance formula simple: EODBalance(today) = EODBalance(yesterday) + DailyMovements(today).

Data is created by the dbo.DailyBalanceCalculation procedure, which aggregates settled transactions from dbo.FiatTransactionsStatuses by customer and currency. The DailyBalanceSync procedure handles catch-up and reconciliation.

---

## 2. Business Logic

### 2.1 Daily Movement Aggregation

**What**: Pre-aggregated net transaction amount per customer per currency per day.

**Columns/Parameters Involved**: `GCID`, `MovementsDate`, `DailyMovmentsAmount`, `COIN`, `DateId`

**Rules**:
- DailyMovmentsAmount is the NET sum: positive values indicate net inflows (more deposits/credits than withdrawals/debits), negative values indicate net outflows
- One row per customer (GCID) per currency (COIN) per date (MovementsDate)
- COIN stores the ISO 4217 numeric currency code (e.g., 978=EUR, 036=AUD)
- DateId is the YYYYMMDD integer for efficient filtering
- A day with zero net movement may still have a row if transactions occurred but cancelled out

**Diagram**:
```
FiatTransactionsStatuses (settled transactions)
      |
      v
DailyBalanceCalculation SP (aggregation)
      |
      v
SUM(amounts) GROUP BY GCID, COIN, Date
      |
      v
INSERT INTO dbo.DailyMovements
      |
      v
Used by DailyBalanceCalculation to compute EODBalance
```

---

## 3. Data Overview

| Id | DateId | MovementsDate | GCID | DailyMovmentsAmount | COIN | Meaning |
|---|---|---|---|---|---|---|
| 11209281 | 20260413 | 2026-04-13 | 21640521 | 628.62 | 036 | Customer 21640521 had AUD 628.62 net inflow on 2026-04-13 |
| 11209280 | 20260413 | 2026-04-13 | 29410297 | 5.00 | 036 | Customer 29410297 had AUD 5.00 net inflow on 2026-04-13 |
| 11209279 | 20260413 | 2026-04-13 | 29685685 | -0.52 | 036 | Customer 29685685 had AUD 0.52 net outflow on 2026-04-13 (e.g., a small fee) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | DateId | int | NO | - | CODE-BACKED | Numeric date key in YYYYMMDD format (e.g., 20260413). Enables efficient integer-based date filtering in reporting queries. |
| 3 | MovementsDate | date | NO | - | CODE-BACKED | The business date for which these movements are aggregated. Combined with GCID and COIN, uniquely identifies a movement record. |
| 4 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer whose daily movement is recorded. |
| 5 | DailyMovmentsAmount | decimal(36,18) | YES | - | CODE-BACKED | Net aggregated transaction amount for the day. Positive = net inflow, negative = net outflow. NULL if calculation could not complete. Note: column name contains a misspelling ("Movments" instead of "Movements") preserved from original DDL. |
| 6 | COIN | nvarchar(10) | YES | - | CODE-BACKED | ISO 4217 numeric currency code for the movement currency. E.g., 978=EUR, 826=GBP, 036=AUD. See [ISO Currency Info](../../_glossary.md#iso-currency-info). |
| 7 | MarketRateSymbol | nvarchar(10) | YES | - | NAME-INFERRED | Market rate pair symbol for USD conversion reference (e.g., "AUDUSD"). Captured at aggregation time. |
| 8 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when this movement record was calculated and inserted. |
| 9 | LastDailyTransactionCreated | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the most recent individual transaction that contributed to this daily aggregate. Used to track data freshness and identify if late-arriving transactions were missed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (standalone reporting table).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.DailyBalanceCalculation | FROM | Reader/Writer | Reads movements to calculate EOD balances, writes aggregated movements |
| dbo.DailyBalanceCalculation_backup | FROM | Reader/Writer | Backup version of the calculation procedure |
| dbo.DailyBalanceSync | FROM | Reader/Writer | Syncs and seeds movement data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.DailyBalanceCalculation | Stored Procedure | Reads to calculate EOD balances, writes aggregated movements |
| dbo.DailyBalanceCalculation_backup | Stored Procedure | Backup calculation procedure |
| dbo.DailyBalanceSync | Stored Procedure | Syncs movement data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DailyMovements | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_DailyMovements_Created | DEFAULT | getutcdate() - Auto-sets Created to current UTC time on insert |

---

## 8. Sample Queries

### 8.1 Get a customer's daily movements for the last week
```sql
SELECT MovementsDate, COIN, DailyMovmentsAmount, LastDailyTransactionCreated
FROM dbo.DailyMovements WITH (NOLOCK)
WHERE GCID = 21640521 AND MovementsDate >= DATEADD(DAY, -7, GETDATE())
ORDER BY MovementsDate DESC, COIN;
```

### 8.2 Get total daily movements across all customers for a date
```sql
SELECT COIN, COUNT(*) AS CustomerCount, SUM(DailyMovmentsAmount) AS TotalMovement
FROM dbo.DailyMovements WITH (NOLOCK)
WHERE DateId = 20260413
GROUP BY COIN
ORDER BY COIN;
```

### 8.3 Find customers with largest daily outflows
```sql
SELECT TOP 10 GCID, COIN, DailyMovmentsAmount
FROM dbo.DailyMovements WITH (NOLOCK)
WHERE DateId = 20260413 AND DailyMovmentsAmount < 0
ORDER BY DailyMovmentsAmount ASC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB is a reporting database for client balances, transactions, and provider mapping |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 8.9/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.DailyMovements | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.DailyMovements.sql*
