# DWH_dbo.V_Dim_Instrument_Correlation

> Filtered correlation view over `Dim_Instrument_Correlation_Active` that provides the full symmetric Pearson correlation matrix with a date-based partition split at DateID 20250202 — separating half-matrix (recent) from pre-computed full-matrix (legacy) data.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Tables** | DWH_dbo.Dim_Instrument_Correlation_Active |
| **Purpose** | Active-window symmetric instrument correlation matrix for portfolio risk and analytics |

---

## 1. Business Meaning

`V_Dim_Instrument_Correlation` provides the full symmetric Pearson correlation matrix from the `Dim_Instrument_Correlation_Active` table. It is distinct from the top-level `Dim_Instrument_Correlation` view (which reads from 20 partition tables + archive via `UnionedPartitions`). This view reads directly from a single consolidated `Dim_Instrument_Correlation_Active` table.

The view applies a date-based partition split at `DateID > 20250202`:
- **Recent data** (after 2025-02-02): stored as half-matrix (InstrumentID_a <= InstrumentID_b). The view adds the symmetric mirror (swapping a/b and StdDev_a/b where a < b) via UNION ALL.
- **Legacy data** (on or before 2025-02-02): already stored as full symmetric matrix. Passed through without expansion.

---

## 2. Elements

| # | Column | Type | Nullable | Source | Description |
|---|--------|------|----------|--------|-------------|
| 1 | DateID | int | NULL | Active.DateID | Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performance. (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 2 | InstrumentID_a | int | NULL | Active.InstrumentID_a (+ swapped _b) | ID of the first financial instrument in the pair (always <= InstrumentID_b in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name. (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 3 | InstrumentID_b | int | NULL | Active.InstrumentID_b (+ swapped _a) | ID of the second financial instrument in the pair (always >= InstrumentID_a in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name. (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 4 | SampleSize | int | NULL | Active.SampleSize | Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data. (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 5 | StandardDeviation_a | decimal(38,20) | NULL | Active.StandardDeviation_a (+ swapped _b) | Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 6 | StandardDeviation_b | decimal(38,20) | NULL | Active.StandardDeviation_b (+ swapped _a) | Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 7 | Covariance | decimal(38,20) | NULL | Active.Covariance | Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula. (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 8 | PearsonCorrelation | decimal(38,20) | NULL | Active.PearsonCorrelation | Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (StandardDeviation_a * StandardDeviation_b). (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 9 | InsertDate | datetime | NULL | Active.InsertDate | Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP. (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |
| 10 | UpdateDate | datetime | NULL | Active.UpdateDate | Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation). (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Instrument_Correlation_Active | Source table (3 UNION ALL legs) | Base table | Inbound |
| DWH_dbo.Dim_Currency | `ON InstrumentID_a = CurrencyID` / `ON InstrumentID_b = CurrencyID` | Instrument name resolution | Logical |

---

## 4. ETL & Data Pipeline

No ETL — computed view. Data freshness depends on `Dim_Instrument_Correlation_Active` table population.

---

## 5. Business Logic & Patterns

### Date-Partitioned Symmetric Expansion

```sql
-- Leg 1: Recent half-matrix rows (pass-through)
SELECT ... FROM Active WHERE DateID > 20250202
UNION ALL
-- Leg 2: Recent mirrored rows (a/b swapped where a < b)
SELECT DateID, InstrumentID_b AS a, InstrumentID_a AS b,
       SampleSize, StdDev_b AS a, StdDev_a AS b, ...
FROM Active WHERE InstrumentID_a < InstrumentID_b AND DateID > 20250202
UNION ALL
-- Leg 3: Legacy full-matrix (no expansion needed)
SELECT ... FROM Active WHERE DateID <= 20250202
```

The hardcoded date `20250202` marks the cutover point when the `Active` table switched from full-matrix to half-matrix storage format.

---

## 6. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| Hardcoded date split | Low | `20250202` is hardcoded — when the Active table is fully repopulated with half-matrix data, this filter becomes unnecessary overhead. |

---

## 7. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DWH - Instrument Correlation Expansion HLD](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12944572417) | Synapse-side correlation expansion, 70K-instrument scale, ADF/DWH refactor context |
| [Asset Expansion Support - Risk Instrument Contribution](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13128106202) | Uses instrument correlations from DWH in portfolio risk (Cartesian matrix) |
| [Fallback (No Databricks) - Risk Instrument Contribution](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13212286977) | DWH table polling for new correlation records |

---

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Phases: 8/14 | Batch: 16*
*Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.V_Dim_Instrument_Correlation | Type: View | Base Tables: DWH_dbo.Dim_Instrument_Correlation_Active*
