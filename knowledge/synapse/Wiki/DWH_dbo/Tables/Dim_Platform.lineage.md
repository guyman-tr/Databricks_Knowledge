# Column Lineage: DWH_dbo.Dim_Platform

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Platform` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform` |
| **Primary Source** | `Dictionary.Platform` (`etoro`) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Dictionary.Platform  (PK column = Id)
      |
      v (Generic Pipeline -- Override, daily, 1440 min)
  Bronze/etoro/Dictionary/Platform/
      |
      v (DWH staging import)
  DWH_staging.etoro_Dictionary_Platform  (column = Id)
      |
      v (SP_Dictionaries_DL_To_Synapse -- TRUNCATE + INSERT, Id -> PlatformID rename)
  DWH_dbo.Dim_Platform  (column = PlatformID)
      |
      v (Generic Pipeline -- Override, daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **rename** | Same value, different column name in DWH. |
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PlatformID | Dictionary.Platform | Id | rename | Production PK is `Id`; DWH renames to `PlatformID` (standardize *ID suffix pattern) |
| Platform | Dictionary.Platform | Platform | passthrough | Same name in both layers |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each reload; not from production source |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
