# Column Lineage — DWH_dbo.V_Fact_SnapshotCustomer

## Source Mapping

| Target Column | Source Table | Source Column |
|--------------|-------------|---------------|
| DateKey | Dim_Date | DateKey (WHERE DateKey BETWEEN Dim_Range.FromDateID AND Dim_Range.ToDateID) |
| All others | Fact_SnapshotCustomer | a.* |

## Expands SCD2 ranges to daily rows. See [Fact_SnapshotCustomer.lineage.md](../Tables/Fact_SnapshotCustomer.lineage.md).
