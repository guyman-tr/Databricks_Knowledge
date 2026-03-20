# Column Lineage: DWH_dbo.Dim_PlayerStatusSubReasons

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PlayerStatusSubReasons` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` |
| **Primary Source** | `Dictionary.PlayerStatusSubReasons` (`etoro`) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Dictionary.PlayerStatusSubReasons  (2 data cols, 83 rows)
      |
      v (Generic Pipeline -- Override, daily, 1440 min)
  Bronze/etoro/Dictionary/PlayerStatusSubReasons/
      |
      v (DWH staging import -- Name stored as Name)
  DWH_staging.etoro_Dictionary_PlayerStatusSubReasons
      |
      v (SP_Dictionaries_DL_To_Synapse -- TRUNCATE + INSERT SELECT, Name -> PlayerStatusSubReasonName)
  DWH_dbo.Dim_PlayerStatusSubReasons  (3 cols, 83 rows)
      |
      v (Generic Pipeline -- Override, daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | PlayerStatusSubReasonID | passthrough | PK in both layers; DDL allows NULL in DWH (unusual) |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons | Name | rename | Production column `Name` renamed to `PlayerStatusSubReasonName` in DWH |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each SP_Dictionaries_DL_To_Synapse run |

## Dropped Production Columns (Schema Drift)

None -- all production columns are loaded into DWH (with Name renamed).

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Dropped from production** | 0 |
| **Total DWH columns** | 3 |
