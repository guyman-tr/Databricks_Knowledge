# Column Lineage: DWH_dbo.Dim_AffiliateCostType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_AffiliateCostType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype` |
| **Primary Source** | `DWH_Migration.Dim_AffiliateCostType` (Legacy DWH SQL Server) |
| **ETL SP** | None — one-time migration load only |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
Legacy DWH SQL Server (on-prem)
  -> One-time DWH_Migration load (2024-09-16)
    -> DWH_Migration.Dim_AffiliateCostType (varchar staging)
      -> DWH_dbo.Dim_AffiliateCostType (typed: smallint PK, varchar(50) Name)
        -> [No active ETL refresh]
        -> Generic Pipeline (daily) -> Gold/sql_dp_prod_we/DWH_dbo/Dim_AffiliateCostType/
          -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype (UC)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **cast/convert** | Type conversion only. |
| **migration-null** | Column was never populated during the one-time migration load. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| AffiliateCostTypeID | DWH_Migration.Dim_AffiliateCostType | AffiliateCostTypeID | cast/convert | varchar(10) in migration staging -> smallint in DWH |
| Name | DWH_Migration.Dim_AffiliateCostType | Name | passthrough | varchar(50) in both |
| InsertDate | DWH_Migration.Dim_AffiliateCostType | InsertDate | migration-null | varchar(50) in staging, datetime in DWH, always NULL (never populated in migration) |
| UpdateDate | DWH_Migration.Dim_AffiliateCostType | UpdateDate | migration-null | varchar(50) in staging, datetime in DWH, always NULL (never populated in migration) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Cast/Convert** | 1 |
| **Migration-null** | 2 |
| **Total** | 4 |
