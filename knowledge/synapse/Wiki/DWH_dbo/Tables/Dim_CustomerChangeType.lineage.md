# Column Lineage: DWH_dbo.Dim_CustomerChangeType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CustomerChangeType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype` |
| **Primary Source** | `DWH_Migration.Dim_CustomerChangeType` (Legacy DWH SQL Server, 2018) |
| **ETL SP** | None — one-time migration load only |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
Legacy DWH SQL Server (on-prem, data from 2018-10-02)
  -> One-time DWH_Migration load (2024-09-16)
    -> DWH_Migration.Dim_CustomerChangeType (staging)
      -> DWH_dbo.Dim_CustomerChangeType (16 rows, frozen)
        -> [No active ETL refresh]
        -> Generic Pipeline (daily Override) -> Gold/sql_dp_prod_we/DWH_dbo/Dim_CustomerChangeType/
          -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CustomerChangeTypeID | DWH_Migration.Dim_CustomerChangeType | CustomerChangeTypeID | passthrough | tinyint, values 1-16 |
| Name | DWH_Migration.Dim_CustomerChangeType | Name | passthrough | Dim_Customer field names (e.g., "CountryID", "PlayerStatusID") |
| UpdateDate | DWH_Migration.Dim_CustomerChangeType | UpdateDate | passthrough | 2018-10-02 timestamp preserved from legacy DWH |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **Total** | 3 |
