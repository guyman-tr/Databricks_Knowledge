# DWH_dbo.V_Dim_Instrument_Correlation_Test_Full

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Dim_Instrument_Correlation_Test_Full]` |
| **Type** | View |
| **Base Tables** | `Dim_Instrument_Correlation_Half_Records` (original undivided partition table) |
| **Purpose** | Test/development view that reconstructs the full symmetric Pearson correlation matrix from the single `Dim_Instrument_Correlation_Half_Records` table. Used for validation against the production 20-partition architecture. |

## 2. Business Context

This view exists for **testing and validation only**. It reconstructs the full symmetric correlation matrix (A→B + B→A) from the single `Dim_Instrument_Correlation_Half_Records` table, which predates the 20-partition split architecture.

The production equivalent is `Dim_Instrument_Correlation`, which reads from 20 `Half_Records_N` tables via `Dim_Instrument_Correlation_UnionedPartitions` plus the Archive table.

### Half-Matrix Reconstruction Logic
The half-matrix stores only pairs where `InstrumentID_a ≤ InstrumentID_b`. The UNION ALL:
1. First SELECT: returns all rows as-is (half-matrix)
2. Second SELECT: swaps `InstrumentID_a` ↔ `InstrumentID_b` and `StandardDeviation_a` ↔ `StandardDeviation_b` for pairs where `a < b` (creates the mirror half)

## 3. View Definition

```sql
SELECT * FROM (
  SELECT DateID, InstrumentID_a, InstrumentID_b, SampleSize, StandardDeviation_a,
         StandardDeviation_b, Covariance, PearsonCorrelation, InsertDate, UpdateDate
  FROM DWH_dbo.Dim_Instrument_Correlation_Half_Records b
  UNION ALL
  SELECT DateID, InstrumentID_b AS InstrumentID_a, InstrumentID_a AS InstrumentID_b,
         SampleSize, StandardDeviation_b AS StandardDeviation_a,
         StandardDeviation_a AS StandardDeviation_b, Covariance, PearsonCorrelation,
         InsertDate, UpdateDate
  FROM DWH_dbo.Dim_Instrument_Correlation_Half_Records b
  WHERE InstrumentID_a < InstrumentID_b
) a
```

## 4. Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | `DateID` | int | Correlation computation date (YYYYMMDD). (Tier 2 — view DDL) |
| 2 | `InstrumentID_a` | int | First instrument in the pair. FK to Dim_Instrument. (Tier 2 — view DDL) |
| 3 | `InstrumentID_b` | int | Second instrument in the pair. FK to Dim_Instrument. (Tier 2 — view DDL) |
| 4 | `SampleSize` | int | Number of hourly price observations used in the computation. (Tier 2 — view DDL) |
| 5 | `StandardDeviation_a` | float | Standard deviation of hourly returns for instrument A. (Tier 2 — view DDL) |
| 6 | `StandardDeviation_b` | float | Standard deviation of hourly returns for instrument B. (Tier 2 — view DDL) |
| 7 | `Covariance` | float | Covariance of hourly returns between instruments A and B. (Tier 2 — view DDL) |
| 8 | `PearsonCorrelation` | float | Pearson correlation coefficient (−1 to +1) between instruments A and B. (Tier 2 — view DDL) |
| 9 | `InsertDate` | datetime | Row creation timestamp. (Tier 2 — view DDL) |
| 10 | `UpdateDate` | datetime | Row last update timestamp. (Tier 2 — view DDL) |

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DWH - Instrument Correlation Expansion HLD](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12944572417) | Background on instrument correlation in Synapse/DWH and half/full matrix handling |
| [Asset Expansion Support - Risk Instrument Contribution](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13128106202) | Business use of full instrument correlation matrices from DWH |
| [POC - Risk Instrument Contribution - DataBricks](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13167722497) | Retrieves all instruments’ correlations from DWH for risk workflows |

---
*Generated: 2026-03-19 | Quality: 7.8/10 | Test view — production equivalent is Dim_Instrument_Correlation | Sources: 8/10*
