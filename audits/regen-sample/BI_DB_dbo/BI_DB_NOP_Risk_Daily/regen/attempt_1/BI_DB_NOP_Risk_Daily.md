# BI_DB_dbo.BI_DB_NOP_Risk_Daily

> Daily aggregated Net Open Position (NOP) table for risk reporting, summarizing open-position USD exposure by instrument, settlement type (real vs CFD), and direction (Buy/Sell). 180K rows across a rolling ~1 month window (2023-12-16 to 2024-01-16 as of last load), covering 4,816 instruments. Populated by SP_NOP_TradingActivity_Risk_Daily Step 04, which aggregates from BI_DB_PositionPnL.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL (aggregated) + DWH_dbo.Dim_Instrument (display names, type classification) |
| **Refresh** | Daily via SP_NOP_TradingActivity_Risk_Daily @Date1; rolling 1-month retention |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | _Not yet mapped (not found in generic pipeline mapping)_ |

---

## 1. Business Meaning

BI_DB_NOP_Risk_Daily provides a daily instrument-level summary of Net Open Position (NOP) in USD for risk monitoring. Each row represents the total NOP for a specific combination of date, instrument, settlement type (real asset vs CFD), and trade direction (Buy/Sell). The NOP value represents the aggregated USD exposure across all open positions of valid customers for that instrument segment on a given day.

The table is populated by Step 04 of `SP_NOP_TradingActivity_Risk_Daily`, which:
1. Reads from `BI_DB_dbo.BI_DB_PositionPnL` for the report date (`@DateINT1`), filtered by valid instruments via `DWH_dbo.Dim_Instrument`
2. Aggregates position-level NOP into instrument/settlement/direction groups using `SUM(dp.NOP)`
3. Classifies instruments into composite asset types (RealStocksETF, CFDStocksETF, RealCrypto, CFDCrypto, Currencies, Commodities, Indecies) based on `InstrumentTypeID` and `IsSettled`

Data retention is a rolling ~1 month: the SP deletes rows where `DateID < @DateINT3` (one month before `@Date1`) on each run. As of the last load (2024-01-17), the table holds 180,577 rows spanning 32 dates (2023-12-16 to 2024-01-16) across 4,816 distinct instruments.

**Grain**: One row per (DateID, InstrumentID, IsSettled, SellBuy).

---

## 2. Business Logic

### 2.1 Instrument Type Classification

**What**: Composite asset class label derived from two inputs: the instrument's base type and its settlement mode.

**Columns Involved**: `InstrumentType`, `IsSettled`, `InstrumentTypeID` (from Dim_Instrument)

**Rules**:
- InstrumentTypeID IN (5,6) AND IsSettled=1 → `RealStocksETF`
- InstrumentTypeID IN (5,6) AND IsSettled=0 → `CFDStocksETF`
- InstrumentTypeID IN (10) AND IsSettled=1 → `RealCrypto`
- InstrumentTypeID IN (10) AND IsSettled=0 → `CFDCrypto`
- InstrumentTypeID IN (1) → `Currencies`
- InstrumentTypeID IN (2) → `Commodities`
- InstrumentTypeID IN (4) → `Indecies` (note: typo preserved from SP)
- All others → `Check`

**Distribution (single-day sample, DateID=20240116)**:
- CFDStocksETF: 6,355 rows (56%)
- RealStocksETF: 4,479 rows (40%)
- CFDCrypto: 188, Currencies: 104, RealCrypto: 83, Commodities: 64, Indecies: 43

### 2.2 NOP Aggregation

**What**: Net Open Position is summed from individual position-level NOP values per instrument/settlement/direction group.

**Columns Involved**: `NOP`, `InstrumentID`, `IsSettled`, `SellBuy`

**Rules**:
- `NOP = CAST(SUM(dp.NOP) AS BIGINT)` where dp = BI_DB_PositionPnL
- Buy-side NOP values are positive; Sell-side are negative (reflecting net exposure direction)
- Grouped by DateID, InstrumentID, IsSettled, and SellBuy (IsBuy mapped to Buy/Sell label)

### 2.3 Rolling Retention Window

**What**: The table retains only the most recent ~1 month of data.

**Columns Involved**: `DateID`

**Rules**:
- On each run, the SP deletes: `WHERE DateID = @DateINT1 OR DateID < @DateINT3`
- `@DateINT3 = DATEADD(MONTH, -1, @Date1)` — one calendar month before the run date
- This means: replace today's data + purge anything older than 1 month

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID ASC. Date-range queries are efficient. Since there is no hash distribution key, JOINs to other tables (e.g., Dim_Instrument) require data movement — but with only ~180K rows, this is negligible.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| NOP for all instruments on a date | `WHERE DateID = @dateID` |
| NOP for a specific instrument | `WHERE DateID = @dateID AND InstrumentID = @id` |
| Top instruments by absolute NOP | `WHERE DateID = @dateID ORDER BY ABS(NOP) DESC` |
| NOP trend for an instrument over time | `WHERE InstrumentID = @id ORDER BY DateID` |
| Total NOP by asset class | `SELECT InstrumentType, SUM(NOP) ... GROUP BY InstrumentType WHERE DateID = @dateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Full instrument metadata (symbol, exchange, ISIN) |
| BI_DB_dbo.BI_DB_TradingActivity_Risk_Daily | ON DateID, InstrumentID | Combine NOP with trading volume/trades/customers |

### 3.4 Gotchas

- **Rolling 1-month window**: Data older than 1 month is deleted on each SP run. Do not expect historical data beyond the retention window.
- **"Indecies" is a typo**: The InstrumentType value for indices is spelled `Indecies` (not "Indices") — preserved from the SP CASE statement. Filter accordingly.
- **NOP is signed**: Buy-side NOP is positive, Sell-side is negative. Use `ABS(NOP)` for absolute exposure comparisons.
- **Last load January 2024**: As of sampling, the most recent data is from 2024-01-16 (loaded 2024-01-17). The SP may not be actively running.
- **"Check" type**: If `InstrumentTypeID` does not match any known category, the type defaults to `Check`. Investigate any rows with this value.
- **Grain includes IsSettled**: The same InstrumentID can appear multiple times per date — once for real (IsSettled=1) and once for CFD (IsSettled=0), and each of those split by Buy/Sell direction.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki — description copied from documented source |
| Tier 2 | ETL-computed — transform documented from SP code |
| Tier 5 | Expert-confirmed domain knowledge |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NO | Snapshot date as YYYYMMDD integer; clustered index key. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 2 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. Passthrough from BI_DB_PositionPnL. (Tier 1 — Trade.PositionTbl) |
| 3 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Passthrough from BI_DB_PositionPnL. (Tier 5 — Expert Review) |
| 4 | InstrumentType | varchar(50) | YES | Composite asset class label combining InstrumentTypeID and IsSettled: RealStocksETF, CFDStocksETF, RealCrypto, CFDCrypto, Currencies, Commodities, Indecies (typo preserved), Check. (Tier 2 — BI_DB_PositionPnL / Dim_Instrument) |
| 5 | InstrumentDisplayName | varchar(200) | YES | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. Passthrough from Dim_Instrument. (Tier 1 — Trade.InstrumentMetaData) |
| 6 | SellBuy | varchar(50) | YES | Direction label: 'Buy' when IsBuy=1 (long), 'Sell' when IsBuy=0 (short). Derived from BI_DB_PositionPnL.IsBuy. (Tier 2 — BI_DB_PositionPnL) |
| 7 | NOP | bigint | YES | Net open position in USD, aggregated SUM per instrument/settlement/direction from daily position-level NOP values. Buy-side positive, Sell-side negative. (Tier 2 — BI_DB_PositionPnL) |
| 8 | UpdateDate | datetime | NO | ETL load timestamp set to GETDATE() at insert. Not a business date. (Tier 2 — SP_NOP_TradingActivity_Risk_Daily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Passthrough (GROUP BY key) |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | Passthrough (GROUP BY key) |
| IsSettled | BI_DB_dbo.BI_DB_PositionPnL | IsSettled | Passthrough (GROUP BY key) |
| InstrumentType | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument | IsSettled + InstrumentTypeID | CASE mapping (7 categories + fallback) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough via JOIN |
| SellBuy | BI_DB_dbo.BI_DB_PositionPnL | IsBuy | CASE: 1='Buy', 0='Sell' |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | CAST(SUM(NOP) AS BIGINT) |
| UpdateDate | ETL-computed | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (daily position P&L snapshot, ~millions of rows)
  + DWH_dbo.Dim_Instrument (instrument dimension, 15K rows, REPLICATE)
  |
  |-- SP_NOP_TradingActivity_Risk_Daily @Date1 (Step 04: #dailynop)
  |   DELETE WHERE DateID=@DateINT1 OR DateID<@DateINT3
  |   INSERT aggregated NOP per instrument/settlement/direction
  v
BI_DB_dbo.BI_DB_NOP_Risk_Daily (~180K rows, rolling 1-month window)
```

| Step | Object | Description |
|------|--------|-------------|
| Upstream | BI_DB_dbo.BI_DB_PositionPnL | Daily open-position P&L snapshot (depends on SP_PositionPnL) |
| Dimension | DWH_dbo.Dim_Instrument | Instrument metadata for type classification and display names |
| ETL | SP_NOP_TradingActivity_Risk_Daily Step 04 | Aggregate NOP by instrument/settlement/direction; delete+insert for current date; purge >1 month |
| Target | BI_DB_dbo.BI_DB_NOP_Risk_Daily | Rolling 1-month NOP aggregation table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, symbol, type, asset class |
| DateID | DWH_dbo.Dim_Date (via DateID) | Calendar dimension (year, month, quarter) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Risk reporting dashboards | DateID, InstrumentID | Daily NOP exposure monitoring |

---

## 7. Sample Queries

### 7.1 Top 10 instruments by absolute NOP on a given date
```sql
SELECT
    InstrumentID,
    InstrumentDisplayName,
    InstrumentType,
    SellBuy,
    NOP
FROM [BI_DB_dbo].[BI_DB_NOP_Risk_Daily]
WHERE DateID = 20240116
ORDER BY ABS(NOP) DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 7.2 Total NOP by asset class and direction
```sql
SELECT
    InstrumentType,
    SellBuy,
    SUM(NOP) AS TotalNOP,
    COUNT(*) AS InstrumentCount
FROM [BI_DB_dbo].[BI_DB_NOP_Risk_Daily]
WHERE DateID = 20240116
GROUP BY InstrumentType, SellBuy
ORDER BY ABS(SUM(NOP)) DESC;
```

### 7.3 NOP trend for Bitcoin over the retention window
```sql
SELECT
    DateID,
    SellBuy,
    NOP
FROM [BI_DB_dbo].[BI_DB_NOP_Risk_Daily]
WHERE InstrumentID = 100000  -- Bitcoin
ORDER BY DateID, SellBuy;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 2 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 8/8, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_NOP_Risk_Daily | Type: Table | Production Source: BI_DB_PositionPnL (aggregated via SP_NOP_TradingActivity_Risk_Daily)*
