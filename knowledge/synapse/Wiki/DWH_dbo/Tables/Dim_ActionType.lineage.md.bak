# Column Lineage: DWH_dbo.Dim_ActionType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ActionType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` |
| **Primary Source** | `Legacy DWH SQL Server` (DWH_Migration.Dim_ActionType) |
| **ETL SP** | None identified (manual/migration) |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
Legacy DWH SQL Server
  └-> DWH_Migration.Dim_ActionType (one-time migration, 2013)
        └-> DWH_dbo.Dim_ActionType (REPLICATE, Synapse)
              └-> Generic Pipeline (ID 960)
                    └-> Gold/sql_dp_prod_we/DWH_dbo/Dim_ActionType/
                          └-> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype (UC)

NOTE: etoro.Dictionary.ActionType -> Bronze/etoro/Dictionary/ActionType/
      is a DIFFERENT table (session events) - not the source of this DWH dimension.
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **cast/convert** | Type conversion only. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **join-enriched** | Joined from a secondary source table during ETL. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ActionTypeID | DWH_Migration.Dim_ActionType | ActionTypeID | cast/convert | varchar(10) in migration DDL -> smallint in DWH |
| Name | DWH_Migration.Dim_ActionType | Name | passthrough | varchar(100) in both |
| UpdateDate | DWH_Migration.Dim_ActionType | Updatedate | cast/convert | varchar(50) in migration -> datetime in DWH; production timestamp, not ETL load time |
| InsertDate | DWH_Migration.Dim_ActionType | InsertDate | cast/convert | varchar(50) in migration -> datetime in DWH |
| Category | DWH_Migration.Dim_ActionType | Category | passthrough | DWH-specific grouping column not in etoro.Dictionary.ActionType |
| CategoryID | DWH_Migration.Dim_ActionType | CategoryID | passthrough | DWH-specific grouping code not in etoro.Dictionary.ActionType |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 (Name, Category) |
| **Cast/Convert** | 4 (ActionTypeID, UpdateDate, InsertDate, CategoryID) |
| **ETL-computed** | 0 |
| **Join-enriched** | 0 |
| **Total** | 6 |
