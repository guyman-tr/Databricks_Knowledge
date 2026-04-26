# BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily

> 83K-row daily aggregated snapshot of open settled crypto positions held by German customers (CountryID=79, registered before 2023-07-13), grouped by instrument and currency. Sourced from DWH_dbo.Fact_SnapshotCustomer, BI_DB_PositionPnL, and Dim_Instrument via SP_BI_DB_German_Open_Real_Crypto_Positions_Daily. Date range: September 2023 to present. 189 distinct crypto instruments, $648M total equity on latest date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer + BI_DB_PositionPnL + Dim_Instrument via `BI_DB_dbo.SP_BI_DB_German_Open_Real_Crypto_Positions_Daily` |
| **Refresh** | Daily (SB_Daily), delete+insert by DateID |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_German_Open_Real_Crypto_Positions_Daily provides a **daily instrument-level summary** of open settled cryptocurrency positions for **German customers**. This table supports BaFin regulatory reporting and German market crypto exposure monitoring by aggregating customer count, total units held, and total equity per crypto instrument per day.

The population is restricted to:
- **German customers**: Fact_SnapshotCustomer.CountryID=79
- **Valid customers**: IsValidCustomer=1
- **Registered before 2023-07-13**: Dim_Customer.RegisteredReal < '2023-07-13' — this cutoff likely relates to a regulatory change date (MiCA or BaFin crypto custody transition)
- **Settled crypto positions only**: BI_DB_PositionPnL.IsSettled=1 AND Dim_Instrument.InstrumentTypeID=10

Each row represents one instrument on one day — aggregated across all qualifying customers.

**Key metrics**: 83,354 rows spanning DateID 20230919–20260412. Latest date: 189 distinct instruments, 180 distinct currencies, TotalCIDs range 1–59,983, total equity $648M. Top instruments include Bitcoin, Ethereum, Dogecoin, and Cardano.

---

## 2. Business Logic

### 2.1 German Customer Population

**What**: Identifies the eligible customer base for German crypto reporting.
**Columns Involved**: (population filter, not stored)
**Rules**:
- Fact_SnapshotCustomer WHERE CountryID=79 AND IsValidCustomer=1
- JOIN Dim_Customer ON GCID WHERE RegisteredReal < '2023-07-13'
- Dim_Range SCD resolution: @DateID BETWEEN FromDateID AND ToDateID

### 2.2 Crypto Position Aggregation

**What**: Aggregates open settled crypto positions by instrument and day.
**Columns Involved**: TotalCIDs, TotalUnits, TotalPositionsEquity
**Rules**:
- BI_DB_PositionPnL WHERE DateID=@DateID AND IsSettled=1
- Dim_Instrument WHERE InstrumentTypeID=10 (Crypto Currencies only)
- TotalCIDs = COUNT(DISTINCT RealCID) — unique customers holding this instrument
- TotalUnits = SUM(AmountInUnitsDecimal) — total crypto units across all positions
- TotalPositionsEquity = SUM(Amount + PositionPnL) — total position equity in USD
- GROUP BY Date, DateID, InstrumentDisplayName, BuyCurrency

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution, HEAP storage. Small table (83K rows) — full scans are fast. No index optimization needed. For time-series queries, filter by DateID for best performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Daily total German crypto exposure | `SELECT DateID, SUM(TotalPositionsEquity) FROM BI_DB_German_Open_Real_Crypto_Positions_Daily GROUP BY DateID ORDER BY DateID` |
| Top 10 instruments by equity | `SELECT TOP 10 InstrumentDisplayName, TotalPositionsEquity FROM ... WHERE DateID = @today ORDER BY TotalPositionsEquity DESC` |
| Customer count trend for Bitcoin | `SELECT DateID, TotalCIDs FROM ... WHERE InstrumentDisplayName = 'Bitcoin' ORDER BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Instrument | InstrumentDisplayName = InstrumentDisplayName | Full instrument details (InstrumentID, leverage rules) |

### 3.4 Gotchas

- **Registration date cutoff (2023-07-13)** — only customers registered before this date are included. Newer German crypto customers are excluded. This likely corresponds to a regulatory transition date (MiCA/Tangany). For total German crypto exposure including newer customers, use BI_DB_PositionPnL directly with country filtering.
- **Settled positions only** — IsSettled=1 filter excludes pending/unsettled positions. Total exposure may be slightly higher when including unsettled positions.
- **BuyCurrency is the crypto ticker** — not the fiat settlement currency. E.g., 'BTC', 'ETH', 'DOGE'. The 180 distinct values reflect all crypto instruments offered, not 180 fiat currencies.
- **No customer-level detail** — this is an aggregate table. For per-CID breakdown, query BI_DB_PositionPnL directly with the same population filters.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Domain expert input or ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Position snapshot date from BI_DB_PositionPnL. The calendar date for this daily aggregation. (Tier 2 — SP_BI_DB_German_Open_Real_Crypto_Positions_Daily) |
| 2 | DateID | int | YES | YYYYMMDD int of Date. Used for delete+insert idempotency and time-series filtering. Range: 20230919–20260412. (Tier 2 — SP_BI_DB_German_Open_Real_Crypto_Positions_Daily) |
| 3 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Chainlink', 'Bitcoin Cash', 'Dogecoin'). NULL for instruments without metadata entries. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 4 | BuyCurrency | varchar(50) | YES | Text abbreviation of BuyCurrencyID -- denormalized from Dictionary.Currency.Abbreviation via SP JOIN. Example: LINK, BCH, DOGE, BTC. DWH-added for query convenience. (Tier 2 — SP_Dim_Instrument) |
| 5 | TotalCIDs | int | YES | Count of distinct German customers (RealCID) holding open settled positions in this instrument on this date. Range: 1–59,983. (Tier 2 — SP_BI_DB_German_Open_Real_Crypto_Positions_Daily) |
| 6 | TotalUnits | numeric(38,2) | YES | Total crypto units held across all qualifying positions. SUM(AmountInUnitsDecimal) from BI_DB_PositionPnL. Represents aggregate holdings in native crypto units (e.g., 449,988.34 LINK, 97.6M DOGE). (Tier 2 — SP_BI_DB_German_Open_Real_Crypto_Positions_Daily) |
| 7 | TotalPositionsEquity | decimal(38,2) | YES | Total position equity in USD. SUM(Amount + PositionPnL) from BI_DB_PositionPnL. Includes unrealized PnL. Latest total: $648M across all instruments. (Tier 2 — SP_BI_DB_German_Open_Real_Crypto_Positions_Daily) |
| 8 | UpdateDate | date | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — SP_BI_DB_German_Open_Real_Crypto_Positions_Daily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Date | BI_DB_dbo.BI_DB_PositionPnL | Date | Passthrough |
| DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Passthrough (filtered to @DateID) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough |
| BuyCurrency | DWH_dbo.Dim_Instrument | BuyCurrency | Passthrough |
| TotalCIDs | DWH_dbo.Fact_SnapshotCustomer | RealCID | COUNT(DISTINCT) |
| TotalUnits | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM |
| TotalPositionsEquity | BI_DB_dbo.BI_DB_PositionPnL | Amount + PositionPnL | SUM |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic + Trade.PositionTbl + Trade.Instrument (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging (staging tables)
  |-- SP_Dim_Customer / SP_Dim_Position / SP_Dim_Instrument ---|
  v
DWH_dbo.Fact_SnapshotCustomer + Dim_Customer + Dim_Instrument + Dim_Range
  |
  |-- BI_DB_dbo.BI_DB_PositionPnL (dependency: daily position snapshot)
  |
  |-- SP_BI_DB_German_Open_Real_Crypto_Positions_Daily @Date ---|
  |   (German CountryID=79, registered<2023-07-13, crypto InstrumentTypeID=10, IsSettled=1)
  |   (GROUP BY instrument: COUNT(DISTINCT CID), SUM(units), SUM(equity))
  v
BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily (83K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| InstrumentDisplayName | DWH_dbo.Dim_Instrument.InstrumentDisplayName | Crypto instrument name |
| BuyCurrency | DWH_dbo.Dim_Instrument.BuyCurrency | Crypto ticker symbol |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the BI_DB_dbo codebase.

---

## 7. Sample Queries

### 7.1 Daily Total German Crypto Exposure

```sql
SELECT DateID,
       COUNT(DISTINCT InstrumentDisplayName) AS Instruments,
       SUM(TotalCIDs) AS TotalCustomerPositions,
       SUM(TotalPositionsEquity) AS TotalEquityUSD
FROM BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily
WHERE DateID >= 20260101
GROUP BY DateID
ORDER BY DateID DESC
```

### 7.2 Top Crypto Instruments by German Exposure

```sql
SELECT TOP 20 InstrumentDisplayName, BuyCurrency,
       TotalCIDs, TotalUnits, TotalPositionsEquity
FROM BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily)
ORDER BY TotalPositionsEquity DESC
```

### 7.3 Bitcoin Holders Trend Over Time

```sql
SELECT DateID, TotalCIDs, TotalUnits, TotalPositionsEquity
FROM BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily
WHERE InstrumentDisplayName = 'Bitcoin'
ORDER BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 1 T5 | Elements: 8/8, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily | Type: Table | Production Source: Fact_SnapshotCustomer + BI_DB_PositionPnL + Dim_Instrument via SP_BI_DB_German_Open_Real_Crypto_Positions_Daily*
