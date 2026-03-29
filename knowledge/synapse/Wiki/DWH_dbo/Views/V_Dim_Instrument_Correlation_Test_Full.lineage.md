# Column Lineage — DWH_dbo.V_Dim_Instrument_Correlation_Test_Full

## Source

| Property | Value |
|----------|-------|
| **Base Tables** | DWH_dbo.Dim_Instrument_Correlation_Half_Records |
| **View Type** | Symmetric matrix reconstruction (2-leg UNION ALL, no date split) |

## Column Mapping

| # | View Column | Type | Source Table | Source Column | Transform | Upstream Wiki |
|---|------------|------|-------------|---------------|-----------|---------------|
| 1 | DateID | int | Dim_Instrument_Correlation_Half_Records | DateID | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 2 | InstrumentID_a | int | Dim_Instrument_Correlation_Half_Records | InstrumentID_a / _b | Pass-through + swapped (Leg 2: b→a where a<b) | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 3 | InstrumentID_b | int | Dim_Instrument_Correlation_Half_Records | InstrumentID_b / _a | Pass-through + swapped (Leg 2: a→b where a<b) | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 4 | SampleSize | int | Dim_Instrument_Correlation_Half_Records | SampleSize | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 5 | StandardDeviation_a | decimal(38,20) | Dim_Instrument_Correlation_Half_Records | StandardDeviation_a / _b | Pass-through + swapped (Leg 2: b→a) | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 6 | StandardDeviation_b | decimal(38,20) | Dim_Instrument_Correlation_Half_Records | StandardDeviation_b / _a | Pass-through + swapped (Leg 2: a→b) | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 7 | Covariance | decimal(38,20) | Dim_Instrument_Correlation_Half_Records | Covariance | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 8 | PearsonCorrelation | decimal(38,20) | Dim_Instrument_Correlation_Half_Records | PearsonCorrelation | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 9 | InsertDate | datetime | Dim_Instrument_Correlation_Half_Records | InsertDate | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 10 | UpdateDate | datetime | Dim_Instrument_Correlation_Half_Records | UpdateDate | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
