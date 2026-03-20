# DWH_dbo.V_Dim_Instrument_Correlation

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Dim_Instrument_Correlation]` |
| **Type** | View |
| **Base Tables** | `Dim_Instrument_Correlation_Active` |
| **Purpose** | Filtered correlation view that provides the full symmetric Pearson correlation matrix from `Dim_Instrument_Correlation_Active` with a date-based partition split at `DateID > 20250202`. |

## 2. Business Context

This view sits between the raw `Dim_Instrument_Correlation_Active` table and downstream consumers. It reconstructs the full symmetric matrix (A→B + B→A) with a performance optimization: rows after 2025-02-02 get the symmetric expansion (UNION ALL with swapped pairs), while rows on or before 2025-02-02 pass through without expansion (pre-computed full matrix in older data).

This is distinct from the top-level `Dim_Instrument_Correlation` view (documented in Batch 12) which reads from `Dim_Instrument_Correlation_UnionedPartitions` (20 partition tables + Archive). This view reads directly from `Dim_Instrument_Correlation_Active` — a single consolidated table for the active rolling window.

## 3. View Definition

```sql
-- Recent data (after 2025-02-02): half-matrix → full symmetric
SELECT DateID, InstrumentID_a, InstrumentID_b, SampleSize, StandardDeviation_a,
       StandardDeviation_b, Covariance, PearsonCorrelation, InsertDate, UpdateDate
FROM DWH_dbo.Dim_Instrument_Correlation_Active B
WHERE DateID > 20250202
UNION ALL
-- Mirror pairs (a < b swapped)
SELECT DateID, InstrumentID_b, InstrumentID_a, SampleSize, StandardDeviation_b,
       StandardDeviation_a, Covariance, PearsonCorrelation, InsertDate, UpdateDate
FROM DWH_dbo.Dim_Instrument_Correlation_Active b
WHERE InstrumentID_a < InstrumentID_b AND DateID > 20250202
UNION ALL
-- Older data: already full matrix
SELECT DateID, InstrumentID_a, InstrumentID_b, SampleSize, StandardDeviation_a,
       StandardDeviation_b, Covariance, PearsonCorrelation, InsertDate, UpdateDate
FROM DWH_dbo.Dim_Instrument_Correlation_Active
WHERE DateID <= 20250202
```

## 4. Elements

Same 10 columns as `V_Dim_Instrument_Correlation_Test_Full`. See [Dim_Instrument_Correlation.md](Dim_Instrument_Correlation.md) for full column documentation.

## 5. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| Hardcoded date split | Low | `20250202` is hardcoded — when the Active table is fully repopulated with half-matrix data, this filter becomes unnecessary overhead. |

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DWH - Instrument Correlation Expansion HLD](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12944572417) | Synapse-side correlation expansion, 70K-instrument scale, ADF/DWH refactor context |
| [Asset Expansion Support - Risk Instrument Contribution](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13128106202) | Uses instrument correlations from DWH in portfolio risk (Cartesian matrix) |
| [Fallback (No Databricks) - Risk Instrument Contribution](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13212286977) | DWH table polling for new correlation records |

---
*Generated: 2026-03-19 | Quality: 7.8/10 | Filtered correlation view with date-partitioned symmetric expansion | Sources: 8/10*
