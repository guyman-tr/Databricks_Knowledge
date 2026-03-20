# Column Lineage — DWH_dbo.V_Fact_SnapshotEquity_FromDateID

## Source Mapping

| Target Column | Source Table | Source Column |
|--------------|-------------|---------------|
| FromDateID | Dim_Range | FromDateID |
| ToDateID | Dim_Range | ToDateID |
| CID..TotalStockMarginLoanValue | Fact_SnapshotEquity | SE.* (all columns) |

## View is a thin JOIN — no transformations. See [Fact_SnapshotEquity.lineage.md](../Tables/Fact_SnapshotEquity.lineage.md) for upstream lineage.
