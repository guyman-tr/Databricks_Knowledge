# Column Lineage — DWH_dbo.V_Dim_Instrument_Correlation_Test_Full

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| All 10 columns | Dim_Instrument_Correlation_Half_Records | UNION ALL with swapped instrument pairs (half-matrix → full symmetric matrix) |

## Test view — reads from the original undivided partition table. Production uses 20 partitioned tables.
