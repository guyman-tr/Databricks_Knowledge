# DWH_dbo.Dim_Instrument_Correlation_UnionedPartitions

> Union view assembling 3.8 billion instrument pair correlation records from 20 physical partition tables into a single queryable surface for the active rolling ~66-day correlation window.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Production Source** | Derived - computed from hourly price candles (DWH-internal calculation) |
| **Refresh** | Daily (written by SP_Dim_Instrument_Correlation_Half_Records) |
| | |
| **Synapse Distribution** | N/A (View - underlying tables are REPLICATE/HASH) |
| **Synapse Index** | N/A (View) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Instrument_Correlation_UnionedPartitions` is the primary access layer for the **Pearson correlation matrix** of all eToro financial instruments. Each row represents the statistical correlation between a pair of instruments for a given date, computed from 3 months of hourly price candle data. With 3.8 billion rows, this is one of the largest analytical datasets in the DWH.

The data is **DWH-computed** - there is no upstream production source. The ETL SP (`SP_Dim_Instrument_Correlation_Half_Records`) ingests hourly price candles from `Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted`, performs a cross-join to create all instrument pairs, and computes Pearson correlation coefficients. The result is stored as the "lower-triangle" half-matrix (InstrumentID_a <= InstrumentID_b) to halve storage.

This view is an **active rolling window** (approximately 66 days). Older correlations are archived in `Dim_Instrument_Correlation_Archive` (blacklisted from docs). The `Dim_Instrument_Correlation` view wraps this view to provide the full symmetric matrix (adding the transposed rows where InstrumentID_a > InstrumentID_b) plus archive data. Do NOT query this view directly for production analytics - use `Dim_Instrument_Correlation` instead.

---

## 2. Business Logic

### 2.1 Half-Matrix Storage Pattern (Synapse Partition Workaround)

**What**: Synapse MPP cannot efficiently REPLICATE tables with hundreds of millions of rows. To work around this, the correlation data is physically stored across 20 separate REPLICATE tables (`Dim_Instrument_Correlation_Half_Records_1` through `_20`), each holding a subset of the data. This view UNIONs all 20 tables into a unified surface.

**Columns Involved**: All columns (inherited from the underlying partition tables)

**Rules**:
- Only the lower-triangle half of the correlation matrix is stored here (InstrumentID_a <= InstrumentID_b)
- `Dim_Instrument_Correlation` adds the reflected upper-triangle rows to produce a full symmetric matrix
- Each partition table is REPLICATE distributed, allowing each DWH node to evaluate correlations locally
- The 20-partition design was chosen so each partition stays under the per-table REPLICATE size limit

**Diagram**:
```
Physical storage (half-matrix per day):
  [Half_Records_1] UNION ALL [Half_Records_2] ... UNION ALL [Half_Records_20]
       |                                                          |
       +---------------------- THIS VIEW -----------------------+
                                    |
                   [Dim_Instrument_Correlation view]
                   Adds transposed rows for full symmetry + Archive
```

### 2.2 Pearson Correlation Computation

**What**: The Pearson correlation coefficient (r) measures the linear relationship between two instruments' price returns. Range -1.0 (perfect inverse) to +1.0 (perfect positive).

**Columns Involved**: `PearsonCorrelation`, `Covariance`, `StandardDeviation_a`, `StandardDeviation_b`, `SampleSize`

**Rules**:
- Formula: `r = Covariance / (StdDev_a * StdDev_b)` where 0 is excluded (NULLIF guard)
- `SampleSize` = number of hourly candles in the 3-month lookback window where both instruments had prices
- Both standard deviations must be > 0 (HAVING clause excludes zero-variance instruments)
- Computed on price return: `(AskLast - AskFirst) / AskFirst` per 1-hour candle

**Diagram**:
```
For each (InstrumentID_a, InstrumentID_b, Date):
  Take 3 months of hourly candle data
  Compute returns: (AskLast-AskFirst)/AskFirst per hour
  Cross-join instrument pairs (a.DateFrom = b.DateFrom)
  Calculate: Covariance, StdDev_a, StdDev_b, PearsonCorrelation
  Store if StdDev_a > 0 AND StdDev_b > 0
```

---

## 3. Query Advisory

### 3.0 Data Preview

Sample rows from this view (5 rows):

| DateID | InstrumentID_a | InstrumentID_b | SampleSize | PearsonCorrelation | Meaning |
|--------|---------------|---------------|------------|-------------------|---------|
| 20260221 | 1076 | 15379 | 141 | -0.1067 | Slight negative correlation (IDs 1076/15379) |
| 20260106 | 71 | 3258 | 418 | -0.0127 | Near-zero correlation |
| 20260103 | 58 | 9838 | 432 | +0.0368 | Slight positive correlation |
| 20260107 | 58 | 6848 | 432 | -0.1153 | Weak negative correlation |
| 20260216 | 338 | 4029 | 358 | +0.1556 | Weak positive correlation |

Most pairs show low correlation, which is expected for diverse instrument universe.

### 3.1 Synapse Distribution & Index

**In Synapse**, this is a VIEW over 20 REPLICATE partition tables. Queries must always include a `DateID` filter to avoid full 3.8B-row scans. Without `DateID`, the query will scan all 20 tables for the entire date range.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the underlying data will likely be partitioned by `DateID` for partition pruning. Always filter by `DateID` (or use a date range) in Databricks queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find correlated pairs on a specific date | `WHERE DateID = 20260310 AND PearsonCorrelation > 0.7` |
| Top correlated pairs for an instrument | `WHERE DateID = @date AND (InstrumentID_a = @id OR InstrumentID_b = @id) ORDER BY ABS(PearsonCorrelation) DESC` |
| Full symmetric matrix for a date | Use `Dim_Instrument_Correlation` instead (adds transposed rows) |
| Correlation trend for a pair over time | `WHERE InstrumentID_a = @a AND InstrumentID_b = @b ORDER BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Currency | `ON InstrumentID_a = Dim_Currency.CurrencyID` | Resolve instrument name for InstrumentID_a |
| DWH_dbo.Dim_Currency | `ON InstrumentID_b = Dim_Currency.CurrencyID` | Resolve instrument name for InstrumentID_b |

### 3.4 Gotchas

- **3.8 BILLION rows** - ALWAYS filter by `DateID`. A full table scan will time out or consume massive compute.
- **Use COUNT_BIG not COUNT** - COUNT(*) with no filter will overflow INT (arithmetic overflow error).
- **Half-matrix only** - InstrumentID_a <= InstrumentID_b always. For pair (A, B) where A > B, query `Dim_Instrument_Correlation` (the full-symmetric view) or swap the IDs manually.
- **Active window only** - this view covers only the rolling ~66-day window. Historical correlations are in `Dim_Instrument_Correlation_Archive` (accessed via `Dim_Instrument_Correlation` view).
- **Freshness** - data is stale by ~8 days as of 2026-03-19 (MaxInsert: 2026-03-11). Investigate SP execution logs if freshness is critical.
- **SampleSize interpretation** - a low SampleSize (< 100) means unreliable correlation due to sparse price data. Filter `SampleSize >= 100` for reliable pairs.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★ | Tier 2 | Synapse SP code (computed formula verified) |
| ★★ | Tier 3 | Live data sampling + DDL structure |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NULL | Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performance. (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 2 | InstrumentID_a | int | NULL | ID of the first financial instrument in the pair (always <= InstrumentID_b in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name. (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 3 | InstrumentID_b | int | NULL | ID of the second financial instrument in the pair (always >= InstrumentID_a in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name. (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 4 | SampleSize | int | NULL | Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data. (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 5 | StandardDeviation_a | decimal(38,20) | NULL | Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 6 | StandardDeviation_b | decimal(38,20) | NULL | Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 7 | Covariance | decimal(38,20) | NULL | Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula. (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 8 | PearsonCorrelation | decimal(38,20) | NULL | Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (StandardDeviation_a * StandardDeviation_b). (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 9 | InsertDate | datetime | NULL | Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP. (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |
| 10 | UpdateDate | datetime | NULL | Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation). (Tier 2 — SP_Dim_Instrument_Correlation_Half_Records) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateID | Derived | @auxdate parameter | cast to int YYYYMMDD |
| InstrumentID_a/b | Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | InstrumentID | self-join cross product |
| SampleSize | Computed | — | COUNT(*) of matching candle pairs |
| StandardDeviation_a/b | Computed | AskLast, AskFirst | STDEVP((AskLast-AskFirst)/AskFirst) |
| Covariance | Computed | — | sum(pa*pb)/n - sum(pa)*sum(pb)/n^2 |
| PearsonCorrelation | Computed | — | Covariance / (StdDev_a * StdDev_b) |
| InsertDate / UpdateDate | ETL-computed | — | GETDATE() |

No upstream production wiki (data is DWH-derived from price calculations).

### 5.2 ETL Pipeline

```
Price Server -> Candle data -> Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted
  -> SP_Dim_Instrument_Correlation_Half_Records (Pearson calculation, daily)
  -> Dim_Instrument_Correlation_Half_Records (base partition table)
  -> Distributed across Dim_Instrument_Correlation_Half_Records_1..._20
  -> THIS VIEW (UNION ALL of 20 partitions)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Price candle data | Hourly bid/ask prices from eToro price server |
| Staging | Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | Staged price candles with 3-month lookback |
| ETL | SP_Dim_Instrument_Correlation_Half_Records | Computes Pearson correlation via cross-join |
| Base | Dim_Instrument_Correlation_Half_Records | Single logical table, physically split 20 ways |
| View | THIS VIEW | UNION ALL of 20 partition tables |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID_a, InstrumentID_b | DWH_dbo.Dim_Currency | Resolve instrument names (Dim_Currency is the universal instrument registry) |
| Base data | Dim_Instrument_Correlation_Half_Records_1..._20 | 20 physical partition tables holding the actual data |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Instrument_Correlation | — | Wraps this view with transposed rows for full symmetric matrix + archive |
| DWH_dbo.SP_Check_Dim_Instrument_Correlation_Differences | — | Data quality check SP comparing partition tables |
| DWH_dbo.Fact_CustomerUnrealized_PnL | — | Uses correlation data for PnL risk calculations (via Dim_Instrument_Correlation) |
| DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI | — | Same PnL use case via UserAPI path |

---

## 7. Sample Queries

### 7.1 Top correlated instrument pairs for a specific date
```sql
SELECT TOP 20
    c.DateID,
    a.CurrencyName AS Instrument_A,
    b.CurrencyName AS Instrument_B,
    c.PearsonCorrelation,
    c.SampleSize
FROM [DWH_dbo].[Dim_Instrument_Correlation_UnionedPartitions] c
JOIN [DWH_dbo].[Dim_Currency] a ON c.InstrumentID_a = a.CurrencyID
JOIN [DWH_dbo].[Dim_Currency] b ON c.InstrumentID_b = b.CurrencyID
WHERE c.DateID = 20260310
  AND c.SampleSize >= 100
ORDER BY ABS(c.PearsonCorrelation) DESC;
```

### 7.2 Correlation trend over time for a specific instrument pair
```sql
SELECT DateID, PearsonCorrelation, SampleSize
FROM [DWH_dbo].[Dim_Instrument_Correlation_UnionedPartitions]
WHERE InstrumentID_a = 58
  AND InstrumentID_b = 9838
ORDER BY DateID;
```

### 7.3 Count instrument pairs per date (scale check)
```sql
SELECT DateID, COUNT_BIG(*) AS PairCount
FROM [DWH_dbo].[Dim_Instrument_Correlation_UnionedPartitions]
GROUP BY DateID
ORDER BY DateID DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.4/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Instrument_Correlation_UnionedPartitions | Type: View | Production Source: Derived (DWH-computed Pearson correlation)*
