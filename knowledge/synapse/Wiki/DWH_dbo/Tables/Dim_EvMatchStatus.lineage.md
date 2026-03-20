# Column Lineage: DWH_dbo.Dim_EvMatchStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_EvMatchStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus` |
| **Primary Source** | `UserApiDB.Dictionary.EvMatchStatus` (`UserApiDB`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
UserApiDB.Dictionary.EvMatchStatus (UserApiDB-REAL)
    |
    v
[Staging pipeline - mechanism unknown]
    |
    v
DWH_staging.UserApiDB_Dictionary_EvMatchStatus (HEAP/ROUND_ROBIN)
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
    |
    v
DWH_dbo.Dim_EvMatchStatus (REPLICATE / CLUSTERED INDEX)
    |
    v
Gold/sql_dp_prod_we/DWH_dbo/Dim_EvMatchStatus/ (daily export)
    |
    v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus (UC Gold)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **cast/convert** | Type conversion only. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| EvMatchStatusID | UserApiDB.Dictionary.EvMatchStatus | EvMatchStatusId | rename | Case change only: Id -> ID (lowercase d to uppercase D) |
| EvMatchStatusName | UserApiDB.Dictionary.EvMatchStatus | Name | rename | Name -> EvMatchStatusName (added table prefix) |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. Not from source. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 0 |
| **Rename** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
