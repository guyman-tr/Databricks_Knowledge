# Column Lineage: DWH_dbo.Dim_GuruStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_GuruStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` |
| **Primary Source** | `etoro.Dictionary.GuruStatus` (`etoroDB-REAL`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.GuruStatus (etoroDB-REAL)
    |
    v
[Generic Pipeline - Bronze/etoro/Dictionary/GuruStatus/]
    |
    v
DWH_staging.etoro_Dictionary_GuruStatus
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 718)
    |
    v
DWH_dbo.Dim_GuruStatus (REPLICATE / CLUSTERED INDEX)
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
| GuruStatusID | etoro.Dictionary.GuruStatus | GuruStatusID | passthrough | int NOT NULL. 9 values: 0-8. |
| GuruStatusName | etoro.Dictionary.GuruStatus | Name | rename | Name -> GuruStatusName (added table prefix). varchar(50). |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. NOT NULL. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
