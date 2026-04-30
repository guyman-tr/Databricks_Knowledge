# BI_DB_dbo.BI_DB_NOP_Risk_Daily

> Daily aggregated Net Open Position (NOP) table by instrument, settlement type, and trade direction — ~359K rows spanning a rolling 1-month window (20231216–20240116 as of last load), sourced from BI_DB_PositionPnL and Dim_Instrument via SP_NOP_TradingActivity_Risk_Daily.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL (aggregated) + DWH_dbo.Dim_Instrument (lookup) via SP_NOP_TradingActivity_Risk_Daily |
| **Refresh** | Daily (delete + insert for @Date1; purge data older than 1 month) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | _Not_Migrated (no generic pipeline mapping found) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_NOP_Risk_Daily is a daily risk reporting table that aggregates the Net Open Position (NOP) across all open positions per instrument, settlement type (real vs CFD), and trade direction (Buy/Sell). Each row represents the total NOP in USD for a specific combination of DateID + InstrumentID + IsSettled + SellBuy on a given snapshot date.

The table is populated by Step 04 of `SP_NOP_TradingActivity_Risk_Daily`, which reads from `BI_DB_dbo.BI_DB_PositionPnL` (the canonical daily position P&L snapshot) and joins to `DWH_dbo.Dim_Instrument` for instrument classification. The SP sums `NOP` values from BI_DB_PositionPnL for the run date, grouped by instrument, settlement type, instrument type category, and direction.

Data retention is a rolling 1-month window: on each run, the SP deletes the target date's rows and any rows older than 1 month (`DateID < @DateINT3` where `@DateINT3 = DATEADD(MONTH,-1,@Date1)`). As of the last load (2024-01-17), the table contains ~359K rows spanning 32 distinct dates (20231216–20240116) across 4,816 instruments.

The SP also populates the sibling table `BI_DB_TradingActivity_Risk_Daily` (opened/closed position volumes) in the same execution — Steps 01–03 handle trading activity while Step 04 handles NOP.

---

## 2. Business Logic

### 2.1 InstrumentType Classification

**What**: Categorizes each instrument into one of 7 asset class buckets based on InstrumentTypeID and settlement type.

**Columns Involved**: `InstrumentType`, `IsSettled`, `Dim_Instrument.InstrumentTypeID`

**Rules**:
- InstrumentTypeID IN (5,6) AND IsSettled=1 → 'RealStocksETF'
- InstrumentTypeID IN (5,6) AND IsSettled=0 → 'CFDStocksETF'
- InstrumentTypeID IN (10) AND IsSettled=1 → 'RealCrypto'
- InstrumentTypeID IN (10) AND IsSettled=0 → 'CFDCrypto'
- InstrumentTypeID IN (1) → 'Currencies'
- InstrumentTypeID IN (2) → 'Commodities'
- InstrumentTypeID IN (4) → 'Indecies' (note: typo preserved from SP)
- All others → 'Check'

**Live distribution** (359K rows): CFDStocksETF=203K (56.5%), RealStocksETF=141K (39.3%), CFDCrypto=6K, Currencies=3.3K, RealCrypto=2.6K, Commodities=2K, Indecies=1.4K.

### 2.2 NOP Aggregation

**What**: Net Open Position is summed per group from position-level NOP values.

**Columns Involved**: `NOP`, `DateID`, `InstrumentID`, `IsSettled`, `SellBuy`

**Rules**:
- NOP = CAST(SUM(dp.NOP) AS BIGINT) where dp = BI_DB_PositionPnL
- Grouped by DateID, InstrumentID, IsSettled, InstrumentType, InstrumentDisplayName, SellBuy
- Source NOP in BI_DB_PositionPnL is per-position: units x pair rate x direction x USD conversion
- Negative NOP values indicate short (Sell) exposure

### 2.3 SellBuy Direction

**What**: Converts the boolean IsBuy flag into a human-readable direction label.

**Columns Involved**: `SellBuy`, `BI_DB_PositionPnL.IsBuy`

**Rules**:
- IsBuy=1 → 'Buy'
- IsBuy=0 → 'Sell'

**Live distribution**: Buy=264K (73.4%), Sell=96K (26.6%).

### 2.4 Rolling Window Retention

**What**: The SP maintains only the last ~1 month of data.

**Columns Involved**: `DateID`

**Rules**:
- On each run for @Date1: DELETE WHERE DateID = @DateINT1 OR DateID < @DateINT3
- @DateINT3 = DATEADD(MONTH,-1,@Date1) converted to YYYYMMDD int
- Current window: 20231216–20240116 (32 dates)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution means rows are evenly spread across distributions without hash affinity. CLUSTERED INDEX on DateID supports date-range scans efficiently. For queries filtering by InstrumentID, expect cross-distribution movement since the table is not hash-distributed on InstrumentID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total NOP for a date | `WHERE DateID = @dateID` — leverages clustered index |
| NOP by instrument type | `GROUP BY InstrumentType WHERE DateID = @dateID` |
| Real vs CFD exposure | `GROUP BY IsSettled WHERE DateID = @dateID` |
| Long/Short breakdown | `GROUP BY SellBuy WHERE DateID = @dateID` |
| Single instrument NOP history | `WHERE InstrumentID = @id ORDER BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve additional instrument metadata (symbol, exchange, asset class) |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar dimensions (year, month, quarter) |
| BI_DB_dbo.BI_DB_TradingActivity_Risk_Daily | ON DateID, InstrumentID | Combine NOP with trading volume/activity |

### 3.4 Gotchas

- **Rolling 1-month window**: Data older than 1 month is purged on each run. Do not expect historical data beyond ~30 days.
- **'Indecies' typo**: The InstrumentType value for indices is spelled 'Indecies' (with an 'e'), preserved from the SP CASE logic. Filter accordingly.
- **NOP can be negative**: Sell-side (short) positions produce negative NOP values. SUM across Buy and Sell for net exposure.
- **InstrumentDisplayName is varchar(200)**: The DDL declares varchar(200), wider than the upstream Dim_Instrument column (varchar(100)). No truncation risk but values will never exceed 100 characters in practice.
- **No UC target**: This table is not exported to Unity Catalog. Query only in Synapse.
- **DateID is NOT a partition key in Synapse**: Despite being the clustered index column, there is no PARTITION clause in the DDL. The table is a single partition with a clustered index on DateID.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|---------|
| ★★★★★ | Tier 5 | `(Tier 5 — domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 — source)` | Verbatim from upstream wiki |
| ★★★☆☆ | Tier 2 | `(Tier 2 — source)` | ETL-computed from SP code |
| ★★☆☆☆ | Tier 3 | `(Tier 3 — source)` | From live data / DDL structure |
| ★☆☆☆☆ | Tier 4 | `(Tier 4 — [UNVERIFIED])` | Inferred from name, needs review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NO | Snapshot date as YYYYMMDD; partition key. (Tier 1 — BI_DB_PositionPnL) |
| 2 | InstrumentID | int | NO | Traded instrument. (Tier 1 — BI_DB_PositionPnL) |
| 3 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable. (Tier 1 — BI_DB_PositionPnL) |
| 4 | InstrumentType | varchar(50) | YES | ETL-computed asset class + settlement category. CASE on Dim_Instrument.InstrumentTypeID and IsSettled: RealStocksETF, CFDStocksETF, RealCrypto, CFDCrypto, Currencies, Commodities, Indecies, Check. (Tier 2 — BI_DB_PositionPnL / Dim_Instrument) |
| 5 | InstrumentDisplayName | varchar(200) | YES | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. Passthrough from Dim_Instrument. (Tier 1 — Trade.InstrumentMetaData) |
| 6 | SellBuy | varchar(50) | YES | ETL-computed direction label. CASE WHEN IsBuy=1 THEN 'Buy' ELSE 'Sell'. Derived from BI_DB_PositionPnL.IsBuy. (Tier 2 — BI_DB_PositionPnL) |
| 7 | NOP | bigint | YES | Net open position in USD. SUM of per-position NOP from BI_DB_PositionPnL, CAST to BIGINT. Negative values indicate short exposure. (Tier 2 — BI_DB_PositionPnL) |
| 8 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() at insert. Not a business date. (Tier 2 — SP_NOP_TradingActivity_Risk_Daily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| DateID | BI_DB_PositionPnL | DateID | Passthrough |
| InstrumentID | BI_DB_PositionPnL | InstrumentID | Passthrough |
| IsSettled | BI_DB_PositionPnL | IsSettled | Passthrough |
| InstrumentType | BI_DB_PositionPnL + Dim_Instrument | IsSettled, InstrumentTypeID | CASE mapping (7 categories) |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | Dim-lookup passthrough via InstrumentID |
| SellBuy | BI_DB_PositionPnL | IsBuy | CASE: 1='Buy', 0='Sell' |
| NOP | BI_DB_PositionPnL | NOP | SUM + CAST(BIGINT) |
| UpdateDate | SP_NOP_TradingActivity_Risk_Daily | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (open positions)
  |-- SP_PositionPnL @dt (daily snapshot) --|
  v
BI_DB_dbo.BI_DB_PositionPnL (per-position NOP)
  |
  |-- SP_NOP_TradingActivity_Risk_Daily @Date1 (Step 04) --|
  |   JOIN DWH_dbo.Dim_Instrument (InstrumentTypeID, InstrumentDisplayName)
  |   GROUP BY DateID, InstrumentID, IsSettled, InstrumentType, SellBuy
  |   SUM(NOP) → BIGINT
  v
BI_DB_dbo.BI_DB_NOP_Risk_Daily (~359K rows, rolling 1-month window)
```

| Step | Object | Description |
|------|--------|-------------|
| Upstream | BI_DB_dbo.BI_DB_PositionPnL | Daily per-position NOP snapshot |
| Lookup | DWH_dbo.Dim_Instrument | InstrumentTypeID + InstrumentDisplayName |
| Writer | SP_NOP_TradingActivity_Risk_Daily (Step 04) | DELETE for @DateINT1 + older than 1 month; INSERT aggregated NOP |
| Target | BI_DB_dbo.BI_DB_NOP_Risk_Daily | Rolling 1-month aggregated NOP |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata (name, type, symbol) |
| DateID | DWH_dbo.Dim_Date | Calendar dimensions |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| No known consumers | — | No SPs, views, or downstream tables reference this table in the SSDT repo |

---

## 7. Sample Queries

### 7.1 Total NOP by instrument type for a given date

```sql
SELECT InstrumentType,
       SellBuy,
       SUM(NOP) AS TotalNOP,
       COUNT(*) AS InstrumentCount
FROM BI_DB_dbo.BI_DB_NOP_Risk_Daily
WHERE DateID = 20240116
GROUP BY InstrumentType, SellBuy
ORDER BY ABS(SUM(NOP)) DESC;
```

### 7.2 Top 10 instruments by absolute NOP exposure

```sql
SELECT InstrumentID,
       InstrumentDisplayName,
       InstrumentType,
       SellBuy,
       NOP
FROM BI_DB_dbo.BI_DB_NOP_Risk_Daily
WHERE DateID = 20240116
ORDER BY ABS(NOP) DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 7.3 Daily NOP trend for a single instrument

```sql
SELECT DateID,
       SellBuy,
       IsSettled,
       NOP
FROM BI_DB_dbo.BI_DB_NOP_Risk_Daily
WHERE InstrumentID = 1001
ORDER BY DateID, SellBuy;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 4 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_NOP_Risk_Daily | Type: Table | Production Source: BI_DB_PositionPnL + Dim_Instrument via SP_NOP_TradingActivity_Risk_Daily*
