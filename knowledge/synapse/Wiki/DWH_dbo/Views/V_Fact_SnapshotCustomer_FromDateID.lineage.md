# Column Lineage — DWH_dbo.V_Fact_SnapshotCustomer_FromDateID

## Source Mapping

| Target Column | Source Table | Source Column |
|--------------|-------------|---------------|
| FromDateID | Dim_Range | FromDateID |
| ToDateID | Dim_Range | ToDateID |
| All others | Fact_SnapshotCustomer | SC.* |

## Thin JOIN view — no transformations. See [Fact_SnapshotCustomer.lineage.md](../Tables/Fact_SnapshotCustomer.lineage.md).
