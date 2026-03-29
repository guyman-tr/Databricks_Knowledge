# Column Lineage — DWH_dbo.V_Dim_Instrument_Correlation

## Source

| Property | Value |
|----------|-------|
| **Base Tables** | DWH_dbo.Dim_Instrument_Correlation_Active |
| **View Type** | Symmetric matrix reconstruction (3-leg UNION ALL with date-based partition split) |
| **Date Split** | DateID > 20250202 = half-matrix → symmetric; DateID <= 20250202 = full-matrix pass-through |

## Column Mapping

| # | View Column | Type | Source Table | Source Column | Transform | Upstream Wiki |
|---|------------|------|-------------|---------------|-----------|---------------|
| 1 | DateID | int | Dim_Instrument_Correlation_Active | DateID | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 2 | InstrumentID_a | int | Dim_Instrument_Correlation_Active | InstrumentID_a / InstrumentID_b | Pass-through + swapped (Leg 2: b→a where a<b) | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 3 | InstrumentID_b | int | Dim_Instrument_Correlation_Active | InstrumentID_b / InstrumentID_a | Pass-through + swapped (Leg 2: a→b where a<b) | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 4 | SampleSize | int | Dim_Instrument_Correlation_Active | SampleSize | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 5 | StandardDeviation_a | decimal(38,20) | Dim_Instrument_Correlation_Active | StandardDeviation_a / StandardDeviation_b | Pass-through + swapped (Leg 2: b→a) | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 6 | StandardDeviation_b | decimal(38,20) | Dim_Instrument_Correlation_Active | StandardDeviation_b / StandardDeviation_a | Pass-through + swapped (Leg 2: a→b) | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 7 | Covariance | decimal(38,20) | Dim_Instrument_Correlation_Active | Covariance | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 8 | PearsonCorrelation | decimal(38,20) | Dim_Instrument_Correlation_Active | PearsonCorrelation | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 9 | InsertDate | datetime | Dim_Instrument_Correlation_Active | InsertDate | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |
| 10 | UpdateDate | datetime | Dim_Instrument_Correlation_Active | UpdateDate | Pass-through | [Dim_Instrument_Correlation_UnionedPartitions.md](Dim_Instrument_Correlation_UnionedPartitions.md) — Tier 1 inherited |

## Upstream Dependency Graph

```
DWH_dbo.V_Dim_Instrument_Correlation
└── DWH_dbo.Dim_Instrument_Correlation_Active [WIKI: ✗ not documented separately]
    └── Same column structure as Dim_Instrument_Correlation_UnionedPartitions [WIKI: ✓]
```
