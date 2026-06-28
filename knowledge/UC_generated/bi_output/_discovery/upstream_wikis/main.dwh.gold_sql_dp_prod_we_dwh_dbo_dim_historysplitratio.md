# DWH_dbo.Dim_HistorySplitRatio

> 16,014-row stock split ratio dimension table tracking price and amount adjustment ratios for every eToro stock instrument from 2000 to present. Sourced from `etoro.History.SplitRatio` via daily truncate/reload through `SP_Dim_HistorySplitRatio_DL_To_Synapse`. Carries the core ratio columns without operational completion flags.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.History.SplitRatio` via `SP_Dim_HistorySplitRatio_DL_To_Synapse` |
| **Refresh** | Daily (1440 min, Override/truncate-reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC, MinDate ASC, MaxDate ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, parquet) |

---

## 1. Business Meaning

`Dim_HistorySplitRatio` is the DWH copy of eToro's stock split ratio registry (`History.SplitRatio`). Each row represents one split-ratio period for one stock instrument, bounded by `MinDate`/`MaxDate`. The table stores two complementary adjustment ratios — `PriceRatio` (applied to prices) and `AmountRatio` (applied to position unit counts) — that the platform uses to adjust historical prices, open positions, and orders when a company undergoes a stock split or reverse split.

Of the 16,014 rows covering 15,037 distinct instruments, approximately 965 rows have a non-unity `PriceRatio` (representing actual split events). The remaining rows have `PriceRatio=1, AmountRatio=1` — these are initialization baselines for instruments that have never experienced a split, spanning the full default date range (`2000-01-01` to `2100-01-01`).

The production table has 28 columns including multi-phase completion flags (`IsCompletedOpenPositions`, `IsCompletedClosePositions`, etc.), raw unit counts (`UnitsBefore`/`UnitsAfter`), and ultra-high-precision ratio variants. The DWH dimension carries only the 8 core ratio/identity columns plus an ETL timestamp — the operational flags and audit columns are not needed for analytics use cases like historical price adjustment and position reconciliation.

Data flows from `etoro.History.SplitRatio` through the Generic Pipeline bronze export to `DWH_staging.etoro_History_SplitRatio`, then `SP_Dim_HistorySplitRatio_DL_To_Synapse` performs a daily truncate + full INSERT into this table, setting `UpdateDate = GETDATE()`.

---

## 2. Business Logic

### 2.1 Split Ratio Time-Series Pattern

**What**: Each instrument maintains a chain of non-overlapping split ratio records from its earliest history to the far future.

**Columns Involved**: `InstrumentID`, `MinDate`, `MaxDate`, `PriceRatio`, `AmountRatio`

**Rules**:
- `MinDate` = start of the period this ratio applies (inclusive)
- `MaxDate` = end of the period (exclusive); sentinel value `2100-01-01` = currently active
- For instruments with no split history, a single row spans `2000-01-01` to `2100-01-01` with ratios = 1
- When a new split occurs, the prior active row's `MaxDate` is set to the new split's `MinDate`, and a new row is inserted with `MaxDate = 2100-01-01`
- `PriceRatio` and `AmountRatio` are inversely related: for a 2-for-1 forward split, `AmountRatio=2, PriceRatio=0.5`

**Diagram**:
```
InstrumentID=1004 split history:
  Row 1: MinDate=2000-01-01, MaxDate=2025-01-01, Ratio=1 (no adjustment)
  Row 2: MinDate=2025-01-01, MaxDate=2025-01-20, PriceRatio=0.5, AmountRatio=2 (2-for-1 split)
  Row 3: MinDate=2025-01-20, MaxDate=2100-01-01, PriceRatio=1 (active, post-split baseline)
```

### 2.2 Adjusted vs. Unadjusted Ratios

**What**: Both the cumulative adjusted ratios and the original unadjusted values are stored for auditability and different consumption patterns.

**Columns Involved**: `PriceRatio`, `AmountRatio`, `PriceRatioUnAdjusted`, `AmountRatioUnAdjusted`

**Rules**:
- `PriceRatio` / `AmountRatio` are the cumulative ratios that reflect the product of all historical splits — these are what downstream consumers use
- `PriceRatioUnAdjusted` / `AmountRatioUnAdjusted` store the original per-event ratio before cumulative adjustment
- For instruments with multiple historical splits, the adjusted and unadjusted ratios will differ
- For initialization rows (no split), both adjusted and unadjusted are typically 1

### 2.3 Sentinel Date Conventions

**What**: Special date values encode state rather than actual calendar dates.

**Columns Involved**: `MinDate`, `MaxDate`

**Rules**:
- `MinDate = 2000-01-01`: instrument history starts from the beginning (default sentinel)
- `MaxDate = 2100-01-01`: currently active row — no end date set
- `MaxDate < 2100-01-01`: this split period has been superseded by a newer split event

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table uses `REPLICATE` distribution (small dimension, broadcast to all compute nodes) with a `CLUSTERED INDEX` on `(InstrumentID, MinDate, MaxDate)`. This means:
- JOINs on `InstrumentID` are co-located on every node — no data movement needed
- Point lookups for a specific instrument + date range are optimized by the clustered index
- The entire table (~16K rows) fits in memory on each node

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is stored as Delta (Gold export). No partitioning is applied. The table is small enough that full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get current active split ratio for an instrument | `WHERE InstrumentID = @id AND MaxDate = '2100-01-01'` |
| Get the applicable ratio at a specific historical date | `WHERE InstrumentID = @id AND @date >= MinDate AND @date < MaxDate` |
| Find all actual split events (non-initialization rows) | `WHERE PriceRatio != 1 OR AmountRatio != 1` |
| Instruments with the most split events | `GROUP BY InstrumentID HAVING COUNT(*) > 1 ORDER BY COUNT(*) DESC` |
| Adjust a historical price for splits | Multiply price by the `PriceRatio` for the applicable date range |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON d.InstrumentID = i.InstrumentID` | Resolve instrument name/symbol for split events |
| DWH_dbo.Fact_CurrencyPriceWithSplit | `ON d.InstrumentID = f.InstrumentID AND f.PriceDate >= d.MinDate AND f.PriceDate < d.MaxDate` | Apply split ratios to historical price data |

### 3.4 Gotchas

- **Most rows are initialization baselines**: ~15K of 16K rows have `PriceRatio=1, AmountRatio=1` — they represent instruments with no split history, not actual split events
- **MaxDate = 2100-01-01 is the "active" sentinel**: Do not treat it as a real future date. Filter with `MaxDate = '2100-01-01'` to find currently-active ratios
- **MinDate/MaxDate are nullable in DWH**: Unlike the production source where they are NOT NULL with defaults, the DWH DDL allows NULLs — though in practice no NULL values exist
- **Unadjusted ratios may differ from adjusted**: For instruments with multiple historical splits, `PriceRatioUnAdjusted` shows the per-event ratio while `PriceRatio` shows the cumulative result
- **Extreme ratio values exist**: PriceRatio ranges from 0.00004167 to 11,178,000 — these represent extreme split/reverse-split events

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★★ | Tier 1 | Upstream wiki verbatim — from `History.SplitRatio` wiki |
| ★★★ | Tier 2 | Synapse SP code — ETL-computed columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Integer primary key identifying each split ratio record. Not auto-incremented in the DWH; value is passed through from the staging source via SP_Dim_HistorySplitRatio_DL_To_Synapse. |
| 2 | InstrumentID | int | NO | The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 — only stock instruments (not forex or crypto). (Tier 1 — History.SplitRatio) |
| 3 | MinDate | datetime | YES | Start of the period this split ratio is effective. Default '2000-01-01' means "from the beginning of the instrument's history." The split adjustment applies to transactions from this date forward until MaxDate. (Tier 1 — History.SplitRatio) |
| 4 | MaxDate | datetime | YES | End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means "currently active — no end date set." When a new split occurs, the current active row's MaxDate is set to the new split's MinDate. (Tier 1 — History.SplitRatio) |
| 5 | PriceRatio | decimal(16,8) | NO | Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment. (Tier 1 — History.SplitRatio) |
| 6 | AmountRatio | decimal(16,8) | NO | Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment. (Tier 1 — History.SplitRatio) |
| 7 | PriceRatioUnAdjusted | decimal(19,4) | NO | Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison. DWH note: stored as decimal(19,4) in Synapse (money in production). (Tier 1 — History.SplitRatio) |
| 8 | AmountRatioUnAdjusted | decimal(19,4) | NO | Original unadjusted amount ratio stored as money type. Before cumulative adjustments. DWH note: stored as decimal(19,4) in Synapse (money in production). (Tier 1 — History.SplitRatio) |
| 9 | UpdateDate | datetime | NO | ETL load timestamp — set to GETDATE() on each truncate/reload by SP_Dim_HistorySplitRatio_DL_To_Synapse. All rows share the same value after each daily refresh. (Tier 2 — SP_Dim_HistorySplitRatio_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | History.SplitRatio | ID | None (passthrough) |
| InstrumentID | History.SplitRatio | InstrumentID | None (passthrough) |
| MinDate | History.SplitRatio | MinDate | None (passthrough) |
| MaxDate | History.SplitRatio | MaxDate | None (passthrough) |
| PriceRatio | History.SplitRatio | PriceRatio | None (passthrough) |
| AmountRatio | History.SplitRatio | AmountRatio | None (passthrough) |
| PriceRatioUnAdjusted | History.SplitRatio | PriceRatioUnAdjusted | Type cast: money → decimal(19,4) |
| AmountRatioUnAdjusted | History.SplitRatio | AmountRatioUnAdjusted | Type cast: money → decimal(19,4) |
| UpdateDate | — | — | ETL-computed: GETDATE() |

Full production documentation: see upstream wiki `DB_Schema/etoro/Wiki/History/Tables/History.SplitRatio.md`

### 5.2 ETL Pipeline

```
etoro.History.SplitRatio (production, etoroDB-REAL)
  |-- Generic Pipeline (Bronze export, daily Override) ---|
  v
DWH_staging.etoro_History_SplitRatio
  |-- SP_Dim_HistorySplitRatio_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_HistorySplitRatio (16,014 rows, REPLICATE)
  |-- Generic Pipeline (Override, parquet → delta) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio (UC Gold)
```

```text
UPSTREAM SEARCH LOG — Dim_HistorySplitRatio:
  Lineage source objects (from .lineage.md):
    1. History.SplitRatio (role: primary source — production)
    2. DWH_staging.etoro_History_SplitRatio (role: staging relay)
  For each source:
    History.SplitRatio
      (a) Local wiki search: knowledge/synapse/Wiki/ → NOT_FOUND (production table, not Synapse-resident)
          Read tool issued: N/A
      (b) Production wiki search: DB_Schema/etoro/Wiki/History/Tables/History.SplitRatio.md → FOUND (in pre-resolved bundle)
          Read tool issued: YES (via bundle)
      Effective upstream: DB_Schema/etoro/Wiki/History/Tables/History.SplitRatio.md
    DWH_staging.etoro_History_SplitRatio
      (a) Local wiki search: knowledge/synapse/Wiki/DWH_staging/ → NOT_FOUND (staging tables have no wikis)
          Read tool issued: N/A
      (b) Production wiki search: N/A (staging table)
      Effective upstream: none — staging relay, inherits from History.SplitRatio
  Columns expected to inherit Tier 1 from each source:
    History.SplitRatio: ID, InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio, PriceRatioUnAdjusted, AmountRatioUnAdjusted → 8 columns
  Tier-1-eligible columns identified: 8
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | Trade.Instrument (production) / DWH_dbo.Dim_Instrument (DWH) | The stock instrument this split applies to. Only stock instruments (InstrumentID > 1000) have split records. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_CurrencyPriceWithSplit | InstrumentID + date range | Uses split ratios to adjust historical currency/instrument prices |

---

## 7. Sample Queries

### 7.1 Get current active split ratio for a specific instrument
```sql
SELECT ID, InstrumentID, PriceRatio, AmountRatio,
       PriceRatioUnAdjusted, AmountRatioUnAdjusted, MinDate
FROM [DWH_dbo].[Dim_HistorySplitRatio]
WHERE InstrumentID = 1004
  AND MaxDate = '2100-01-01'
```

### 7.2 Find all actual stock split events (non-initialization rows)
```sql
SELECT ID, InstrumentID, MinDate, MaxDate,
       PriceRatio, AmountRatio
FROM [DWH_dbo].[Dim_HistorySplitRatio]
WHERE PriceRatio != 1 OR AmountRatio != 1
ORDER BY MinDate DESC
```

### 7.3 Get the applicable split ratio for a transaction at a specific date with instrument name
```sql
SELECT s.InstrumentID, i.Symbol, s.PriceRatio, s.AmountRatio,
       s.MinDate, s.MaxDate
FROM [DWH_dbo].[Dim_HistorySplitRatio] s
JOIN [DWH_dbo].[Dim_Instrument] i ON s.InstrumentID = i.InstrumentID
WHERE s.InstrumentID = 1004
  AND '2025-01-15' >= s.MinDate
  AND '2025-01-15' < s.MaxDate
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 9.2/10 (★★★★★) | Phases: 11/11*
*Tiers: 8 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_HistorySplitRatio | Type: Table | Production Source: etoro.History.SplitRatio*
