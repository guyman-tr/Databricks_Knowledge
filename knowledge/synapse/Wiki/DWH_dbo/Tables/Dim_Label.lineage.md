# Column Lineage: DWH_dbo.Dim_Label

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Label` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label` |
| **Primary Source** | `etoro.Dictionary.Label` (etoroDB-REAL) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.Label  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_Label
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_Label  (26 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Label/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **rename** | Same value, different column name. |
| **ETL-computed** | Derived by SP logic; not from any source column. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| LabelID | etoro.Dictionary.Label | LabelID | passthrough | PK; white-label brand ID |
| Name | etoro.Dictionary.Label | Name | passthrough | Brand name |
| DWHLabelID | etoro.Dictionary.Label | LabelID | rename | Always = LabelID; DWH redundancy pattern |
| StatusID | -- | -- | ETL-computed | Hardcoded 1 for all rows |
| UpdateDate | -- | -- | ETL-computed | GETDATE() at load time |
| InsertDate | -- | -- | ETL-computed | GETDATE() at load time; same as UpdateDate |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Rename** | 1 |
| **ETL-computed** | 3 |
| **Total** | 6 |
