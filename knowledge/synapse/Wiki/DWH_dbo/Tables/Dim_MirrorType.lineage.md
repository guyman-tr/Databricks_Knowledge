# Column Lineage: DWH_dbo.Dim_MirrorType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_MirrorType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype` |
| **Primary Source** | `etoro.Dictionary.MirrorType` (etoroDB-REAL) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.MirrorType  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_MirrorType
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_MirrorType  (4 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_MirrorType/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype)
```

## Column Lineage

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| MirrorTypeID | etoro.Dictionary.MirrorType | MirrorTypeID | passthrough | PK; 1=Regular, 2=CopyMe, 3=Social Index, 4=Fund |
| MirrorTypeName | etoro.Dictionary.MirrorType | MirrorTypeName | passthrough | Type display name |
| UpdateDate | -- | -- | ETL-computed | GETDATE() at load time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
