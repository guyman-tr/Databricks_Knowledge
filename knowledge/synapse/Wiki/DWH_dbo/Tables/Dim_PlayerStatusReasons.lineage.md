# Column Lineage: DWH_dbo.Dim_PlayerStatusReasons

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PlayerStatusReasons` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` |
| **Primary Source** | `Dictionary.PlayerStatusReasons` (`etoro`) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Dictionary.PlayerStatusReasons  (2 data cols, 44 rows)
      |
      v (Generic Pipeline -- Override, daily, 1440 min)
  Bronze/etoro/Dictionary/PlayerStatusReasons/
      |
      v (DWH staging import -- passthrough)
  DWH_staging.etoro_Dictionary_PlayerStatusReasons
      |
      v (SP_Dictionaries_DL_To_Synapse -- TRUNCATE + INSERT SELECT)
  DWH_dbo.Dim_PlayerStatusReasons  (3 cols, 44 rows)
      |
      v (Generic Pipeline -- Override, daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | PlayerStatusReasonID | passthrough | PK in both layers; ID=0 (None) comes from production |
| Name | Dictionary.PlayerStatusReasons | Name | passthrough | Nullable in both layers |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each SP_Dictionaries_DL_To_Synapse run |

## Dropped Production Columns (Schema Drift)

None -- all production columns are loaded into DWH.

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Dropped from production** | 0 |
| **Total DWH columns** | 3 |
