# DWH_dbo.Dim_Instrument_Correlation

> Full symmetric Pearson correlation matrix between all tradeable instrument pairs, computed from 3-month rolling hourly price changes. Reconstructed from half-matrix storage across 20 physical partition tables plus an archive.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Production Source** | DWH-computed (no production equivalent) |
| **Refresh** | Daily — correlations recomputed for current date from 3-month price window |
| | |
| **Synapse Distribution** | N/A (view over 20 ROUND_ROBIN tables + ROUND_ROBIN archive) |
| **Synapse Index** | N/A (underlying tables: CLUSTERED INDEX DateID DESC, InstrumentID_a, InstrumentID_b) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Instrument_Correlation` is the materialized Pearson correlation matrix between all actively traded instruments on the eToro platform. For any pair of instruments (A, B) on any date, it provides the statistical correlation coefficient along with the underlying standard deviations, covariance, and sample size — enabling portfolio risk analysis, diversification scoring, and regulatory risk reporting.

The correlation is computed from hourly price change data over a **rolling 3-month window**. The price change is calculated as `(AskLast - AskFirst) / AskFirst` from 60-minute price candles. Only instrument pairs where both have non-zero standard deviation (i.e., both actually moved in the period) are included.

### Why the complex architecture?

The correlation matrix is an N×N computation where N = number of instruments. With hundreds of instruments, this produces millions of rows per day. To handle this at Synapse scale:

1. **Half-matrix optimization**: Only one triangle of the symmetric matrix is stored (where `InstrumentID_a <= InstrumentID_b`). The view reconstructs the full matrix by UNION ALL with swapped columns.
2. **Manual partitioning**: Data is distributed across 20 physical tables (`Dim_Instrument_Correlation_Half_Records_1` through `_20`) rather than relying on Synapse's native partitioning. Each table handles a subset of instrument groups.
3. **Instrument grouping**: `SP_Dim_Instrument_Correlation_Build_GroupsInstruments` dynamically partitions instruments into groups, targeting approximately 89 groups per run to keep each computation manageable.
4. **Archive separation**: Historical correlations are moved to `Dim_Instrument_Correlation_Archive` to keep the active tables performant.

### Consumers

- `SP_Fact_CustomerUnrealized_PnL` — uses correlations for portfolio-level risk calculations
- Risk reporting dashboards
- Portfolio diversification analysis

---

## 2. Business Logic

### 2.1 Symmetric Matrix Reconstruction

**What**: The view reconstructs the full N×N correlation matrix from half-matrix storage.

**Columns Involved**: InstrumentID_a, InstrumentID_b, StandardDeviation_a, StandardDeviation_b

**Rules**:
```
Part 1: Original rows from UnionedPartitions (includes self-correlations a=b and all a<b, a>b from storage)
  UNION ALL
Part 2: Swapped rows where InstrumentID_a < InstrumentID_b (excludes self-correlations)
         → InstrumentID_b becomes InstrumentID_a, and vice versa
         → StandardDeviation_b becomes StandardDeviation_a, and vice versa
  UNION ALL
Part 3: Same as Part 1, from Archive table
  UNION ALL
Part 4: Same as Part 2, from Archive table
```

This means: for a pair (AAPL=100, GOOG=200), the storage has one row with `(100, 200)`. The view exposes both `(100, 200)` and `(200, 100)` with appropriately swapped standard deviations.

### 2.2 Pearson Correlation Computation

**What**: Computed in `SP_Dim_Instrument_Correlation_FilterByInstrumentID`

**Formula**:
```
PriceChange = (AskLast - AskFirst) / AskFirst    -- hourly returns

Covariance = SUM(PriceChange_a * PriceChange_b) / N 
           - SUM(PriceChange_a) * SUM(PriceChange_b) / N²

PearsonCorrelation = Covariance / NULLIF(STDEVP(PriceChange_a) * STDEVP(PriceChange_b), 0)
```

**Window**: 3-month rolling (`DATEADD(mm, -3, @auxdate)` to `@auxdate`)

**Source**: `Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted` — hourly price candle data

### 2.3 Instrument Group Assignment

**What**: `SP_Dim_Instrument_Correlation_Build_GroupsInstruments` dynamically partitions instruments into groups.

**Rules**:
- Count distinct instruments active in the 3-month window
- Compute target rows per group: `(N² / 2) / 89` (aiming for ~89 groups)
- Assign groups using cumulative sum of remaining pair counts per instrument
- Result stored in `Dim_Instrument_Correlation_GroupsInstruments`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, the underlying 20 tables are all ROUND_ROBIN with CLUSTERED INDEX (DateID DESC, InstrumentID_a, InstrumentID_b). The view performs 4 UNION ALL operations, which means queries fan out across all 20 tables plus the archive. Always filter on DateID first for partition pruning.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Correlation between two specific instruments | `WHERE DateID = @dt AND InstrumentID_a = @id1 AND InstrumentID_b = @id2` |
| Most correlated instruments for a given instrument | `WHERE DateID = @dt AND InstrumentID_a = @id ORDER BY PearsonCorrelation DESC` |
| Correlation changes over time for a pair | `WHERE InstrumentID_a = @id1 AND InstrumentID_b = @id2 AND DateID BETWEEN @from AND @to` |
| Low-correlation pairs for diversification | `WHERE DateID = @dt AND ABS(PearsonCorrelation) < 0.2` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID_a = InstrumentID | Resolve instrument names/asset classes |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar attributes |
| DWH_dbo.Fact_CustomerUnrealized_PnL | Used indirectly | Portfolio risk weighting |

### 3.4 Gotchas

- **Double counting**: The view exposes the full symmetric matrix — pair (A,B) appears as BOTH `(A,B)` and `(B,A)`. Aggregations must filter to one triangle (e.g., `WHERE InstrumentID_a < InstrumentID_b`)
- **Self-correlations**: Rows where `InstrumentID_a = InstrumentID_b` exist (correlation = 1.0 by definition). Exclude these for pair analysis
- **NULL PearsonCorrelation**: When either instrument has zero standard deviation (flat price), correlation is NULL due to `NULLIF(..., 0)` protection
- **Performance**: Querying without DateID filter scans ALL 20 tables + archive. Always filter DateID
- **SampleSize meaning**: Count of matching hourly candle pairs in the 3-month window. Low sample size = less reliable correlation

---

## 4. Elements

| # | Column | Type | Nullable | Source | Description |
|---|--------|------|----------|--------|-------------|
| 1 | DateID | int | NO | UnionedPartitions.DateID + Archive.DateID | Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performance. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 2 | InstrumentID_a | int | NO | UnionedPartitions.InstrumentID_a (+ swapped _b) | ID of the first financial instrument in the pair. In the full-symmetric view, this can be any instrument (not limited to <= InstrumentID_b). Resolves to Dim_Currency.CurrencyID for the instrument name. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 3 | InstrumentID_b | int | NO | UnionedPartitions.InstrumentID_b (+ swapped _a) | ID of the second financial instrument in the pair. In the full-symmetric view, this can be any instrument (not limited to >= InstrumentID_a). Resolves to Dim_Currency.CurrencyID for the instrument name. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 4 | SampleSize | int | NO | UnionedPartitions.SampleSize + Archive.SampleSize | Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 5 | StandardDeviation_a | decimal(38,20) | NO | UnionedPartitions.StandardDeviation_a (+ swapped _b) | Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_b in the symmetric reconstruction leg. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 6 | StandardDeviation_b | decimal(38,20) | NO | UnionedPartitions.StandardDeviation_b (+ swapped _a) | Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_a in the symmetric reconstruction leg. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 7 | Covariance | decimal(38,20) | NO | UnionedPartitions.Covariance + Archive.Covariance | Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 8 | PearsonCorrelation | decimal(38,20) | YES | UnionedPartitions.PearsonCorrelation + Archive.PearsonCorrelation | Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (StandardDeviation_a * StandardDeviation_b). (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 9 | InsertDate | datetime | YES | UnionedPartitions.InsertDate + Archive.InsertDate | Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 10 | UpdateDate | datetime | YES | UnionedPartitions.UpdateDate + Archive.UpdateDate | Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation). (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |

---

## 5. Lineage

### 5.1 Pipeline Architecture

```
Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted (hourly candles)
    │
    ├─ SP_Dim_Instrument_Correlation_Build_GroupsInstruments
    │   → Dim_Instrument_Correlation_GroupsInstruments (group ranges)
    │
    └─ SP_Dim_Instrument_Correlation_ByGroupRange (orchestrator)
        └─ SP_Dim_Instrument_Correlation_FilterByInstrumentID (per-group)
            → Dim_Instrument_Correlation_Half_Records_1..20 (storage)
            
    Dim_Instrument_Correlation_UnionedPartitions (UNION ALL of 20 tables)
        │
        └─ Dim_Instrument_Correlation (symmetric reconstruction + archive)
```

### 5.2 Key Objects

| Object | Role |
|--------|------|
| `Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted` | Source: 60-minute price candles with Ask prices |
| `Dim_Instrument_Correlation_GroupsInstruments` | Lookup: instrument-to-group assignment |
| `Dim_Instrument_Correlation_Half_Records_1..20` | Storage: active correlation data (one triangle only) |
| `Dim_Instrument_Correlation_Archive` | Storage: historical correlation data |
| `Dim_Instrument_Correlation_UnionedPartitions` | View: UNION ALL of 20 partition tables |
| `Dim_Instrument_Correlation` | View: full symmetric matrix + archive |

---

## 6. Relationships

### 6.1 References To (this view reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (all) | DWH_dbo.Dim_Instrument_Correlation_Half_Records_1..20 | Active correlation data via UnionedPartitions view |
| (all) | DWH_dbo.Dim_Instrument_Correlation_Archive | Historical correlation data |
| InstrumentID_a, InstrumentID_b | DWH_dbo.Dim_Instrument | Instrument reference (implicit FK) |

### 6.2 Referenced By (consumers)

| Source Object | Description |
|--------------|-------------|
| DWH_dbo.SP_Fact_CustomerUnrealized_PnL | Portfolio risk computation using correlation matrix |
| DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse | ETL for unrealized PnL fact table |

---

## 7. Sample Queries

### 7.1 Top 10 most correlated pairs for latest date

```sql
SELECT TOP 10
    ic.InstrumentID_a,
    ia.InstrumentName AS Instrument_A,
    ic.InstrumentID_b,
    ib.InstrumentName AS Instrument_B,
    ic.PearsonCorrelation,
    ic.SampleSize
FROM DWH_dbo.Dim_Instrument_Correlation ic
JOIN DWH_dbo.Dim_Instrument ia ON ic.InstrumentID_a = ia.InstrumentID
JOIN DWH_dbo.Dim_Instrument ib ON ic.InstrumentID_b = ib.InstrumentID
WHERE ic.DateID = (SELECT MAX(DateID) FROM DWH_dbo.Dim_Instrument_Correlation)
  AND ic.InstrumentID_a < ic.InstrumentID_b  -- one triangle only
  AND ic.PearsonCorrelation IS NOT NULL
ORDER BY ic.PearsonCorrelation DESC;
```

### 7.2 Correlation between two specific instruments over time

```sql
SELECT
    DateID,
    PearsonCorrelation,
    SampleSize,
    Covariance
FROM DWH_dbo.Dim_Instrument_Correlation
WHERE InstrumentID_a = @instA
  AND InstrumentID_b = @instB
  AND DateID BETWEEN 20250101 AND 20260319
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched — DWH-internal computation with no external business context needed.

---

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Phases: 7/14 (view — P2,P3 skipped) | Batch: 16*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10*
*Object: DWH_dbo.Dim_Instrument_Correlation | Type: View | Production Source: DWH-computed from price candles*
