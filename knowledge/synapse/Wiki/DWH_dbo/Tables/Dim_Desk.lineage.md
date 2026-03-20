# Column Lineage: DWH_dbo.Dim_Desk

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Desk` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk` |
| **Primary Source** | `DWH_Migration.Dim_Desk` (Legacy DWH SQL Server, migrated 2024-09-16) |
| **ETL SP** | None -- one-time migration load only |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
Legacy DWH SQL Server (on-prem)
  -> One-time DWH_Migration load (2024-09-16)
    -> DWH_Migration.Dim_Desk (staging)
      -> DWH_dbo.Dim_Desk (6526 rows, frozen)
        -> [No active ETL refresh]
        -> Generic Pipeline (daily Override) -> Gold/sql_dp_prod_we/DWH_dbo/Dim_Desk/
          -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk (UC)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| LanguageID | DWH_Migration.Dim_Desk | LanguageID | passthrough | int NOT NULL. LanguageID=0 is default/catch-all. Part of composite natural key. |
| CountryID | DWH_Migration.Dim_Desk | CountryID | passthrough | int NOT NULL. Part of composite natural key. |
| CFKey | DWH_Migration.Dim_Desk | CFKey | passthrough | int NOT NULL. Numeric desk identifier 1-10. CF = Customer Facing. |
| CFDesk | DWH_Migration.Dim_Desk | CFDesk | passthrough | varchar(50) NOT NULL. Human-readable desk name. 10 values: Arabic, China, English, French, German, Italian, Russian, South & Central America, Spanish, Israel. |
| InsertDate | DWH_Migration.Dim_Desk | InsertDate | passthrough | datetime NULL. Always NULL -- static migration load. |
| UpdateDate | DWH_Migration.Dim_Desk | UpdateDate | passthrough | datetime NULL. Always NULL -- static migration load. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 6 |
| **Total** | 6 |
