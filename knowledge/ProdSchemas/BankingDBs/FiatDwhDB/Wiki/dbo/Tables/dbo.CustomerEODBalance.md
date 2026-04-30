# dbo.CustomerEODBalance

> End-of-day balance snapshot table that records each customer's fiat currency balance at market close for historical reporting and reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

CustomerEODBalance stores the end-of-day (EOD) balance for each customer's fiat currency holdings. Each row represents a single customer's balance in a single currency at the close of a specific business day. This provides a complete historical record of customer balances over time, enabling trend analysis, regulatory reporting, and balance reconciliation.

This table exists because FiatDwhDB is a reporting/data warehouse database. While the operational database (FiatWalletDB/FiatCustodianDB) tracks real-time balances, this table captures a daily snapshot for historical analysis. Without it, reconstructing historical balances would require replaying all transactions - an expensive and error-prone operation.

Data is created by the dbo.DailyBalanceCalculation stored procedure, which runs as a scheduled job. It calculates each customer's EOD balance by taking the previous day's balance and adding the day's net movements (from dbo.DailyMovements). The DailyBalanceSync procedure handles initial seeding and catch-up scenarios.

---

## 2. Business Logic

### 2.1 EOD Balance Calculation

**What**: Daily snapshot of each customer's fiat balance, computed from previous balance plus daily movements.

**Columns/Parameters Involved**: `GCID`, `EODBalanceDate`, `EODBalanceAmount`, `COIN`, `DateId`, `LastDailyMovementCreated`

**Rules**:
- EODBalance(today) = EODBalance(yesterday) + DailyMovements(today)
- One row per customer (GCID) per currency (COIN) per date (EODBalanceDate)
- DateId is a numeric date key in YYYYMMDD format for efficient partitioning/filtering
- COIN stores the ISO numeric currency code (e.g., 978=EUR, 826=GBP, 036=AUD)
- LastDailyMovementCreated tracks the most recent transaction that contributed to this balance

**Diagram**:
```
DailyBalanceCalculation SP (scheduled job)
      |
      v
Previous EODBalance + DailyMovements = New EODBalance
      |
      v
INSERT INTO dbo.CustomerEODBalance
```

### 2.2 Currency Conversion Reference

**What**: Market rate information captured alongside the balance for USD-equivalent reporting.

**Columns/Parameters Involved**: `MarketRateSymbol`, `RateConverstionToUSD`

**Rules**:
- MarketRateSymbol stores the market rate pair symbol (e.g., EURUSD) for the currency
- RateConverstionToUSD (note: misspelling preserved from DDL) stores the conversion rate at EOD
- These enable reporting balances in a common USD-equivalent format

---

## 3. Data Overview

| Id | DateId | EODBalanceDate | GCID | EODBalanceAmount | COIN | Meaning |
|---|---|---|---|---|---|---|
| 11196084 | 20260413 | 2026-04-13 | 8842221 | 1369.45 | 978 | Customer 8842221 had EUR 1,369.45 balance at close of 2026-04-13 |
| 11196083 | 20260413 | 2026-04-13 | 36438435 | 5.96 | 978 | Customer 36438435 had EUR 5.96 balance at close of 2026-04-13 |
| 11196082 | 20260413 | 2026-04-13 | 41911388 | 193.92 | 978 | Customer 41911388 had EUR 193.92 balance at close of 2026-04-13 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | DateId | int | NO | - | CODE-BACKED | Numeric date key in YYYYMMDD format (e.g., 20260413). Used for efficient date-based filtering and partitioning in reporting queries. |
| 3 | EODBalanceDate | date | NO | - | CODE-BACKED | The business date for this end-of-day balance snapshot. Combined with GCID and COIN, uniquely identifies a balance record. |
| 4 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer whose balance is recorded. Shared across all eToro platforms. |
| 5 | EODBalanceAmount | decimal(36,18) | YES | - | CODE-BACKED | The customer's fiat balance amount in the specified currency at end of day. NULL if balance could not be calculated (edge case). High precision supports multi-currency calculations. |
| 6 | COIN | nvarchar(10) | YES | - | CODE-BACKED | ISO 4217 numeric currency code identifying the balance currency. E.g., 978=EUR, 826=GBP, 036=AUD, 840=USD. See [ISO Currency Info](../../_glossary.md#iso-currency-info). |
| 7 | MarketRateSymbol | nvarchar(10) | YES | - | NAME-INFERRED | Market rate pair symbol used for USD conversion reporting (e.g., "EURUSD", "GBPUSD"). Captured at EOD for historical rate tracking. |
| 8 | RateConverstionToUSD | nvarchar(10) | YES | - | NAME-INFERRED | Exchange rate to USD at end of day. Stored as string for display purposes. Note: column name contains a misspelling ("Converstion" instead of "Conversion") preserved from original DDL. |
| 9 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when this EOD balance record was calculated and inserted by DailyBalanceCalculation. |
| 10 | LastDailyMovementCreated | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the most recent daily movement record that contributed to this EOD balance calculation. Used to determine data freshness and identify if movements were missed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (standalone reporting table).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.DailyBalanceCalculation | FROM/INSERT | Writer | Calculates and inserts daily EOD balances |
| dbo.DailyBalanceCalculation_backup | FROM/INSERT | Writer | Backup version of the balance calculation procedure |
| dbo.DailyBalanceSync | FROM/INSERT/UPDATE | Writer/Reader | Syncs and seeds EOD balance data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.DailyBalanceCalculation | Stored Procedure | Calculates and inserts daily EOD balances |
| dbo.DailyBalanceCalculation_backup | Stored Procedure | Backup version of balance calculation |
| dbo.DailyBalanceSync | Stored Procedure | Syncs and seeds EOD balance data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EODbalance | CLUSTERED | Id ASC | - | - | Active |
| IX_CustomerEODBalance_EODBalanceDate | NONCLUSTERED | EODBalanceDate ASC | GCID, EODBalanceAmount | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_EODbalance_Created | DEFAULT | getutcdate() - Auto-sets Created to current UTC time on insert |

---

## 8. Sample Queries

### 8.1 Get a customer's EOD balance history for the last 30 days
```sql
SELECT EODBalanceDate, COIN, EODBalanceAmount, MarketRateSymbol, RateConverstionToUSD
FROM dbo.CustomerEODBalance WITH (NOLOCK)
WHERE GCID = 8842221 AND EODBalanceDate >= DATEADD(DAY, -30, GETDATE())
ORDER BY EODBalanceDate DESC, COIN;
```

### 8.2 Get all customer balances for a specific date
```sql
SELECT GCID, COIN, EODBalanceAmount
FROM dbo.CustomerEODBalance WITH (NOLOCK)
WHERE DateId = 20260413
ORDER BY GCID, COIN;
```

### 8.3 Find customers with largest EUR balances on a given date
```sql
SELECT TOP 10 GCID, EODBalanceAmount
FROM dbo.CustomerEODBalance WITH (NOLOCK)
WHERE DateId = 20260413 AND COIN = '978'
ORDER BY EODBalanceAmount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB is "mostly used for reporting, we can see the report of client's balance, transactions, provider mapping" |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CustomerEODBalance | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.CustomerEODBalance.sql*
