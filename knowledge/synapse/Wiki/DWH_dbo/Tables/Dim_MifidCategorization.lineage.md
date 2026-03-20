# Column Lineage: DWH_dbo.Dim_MifidCategorization

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_MifidCategorization` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` |
| **Primary Source** | `etoro.Dictionary.MifidCategorization` (etoroDB-REAL) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.MifidCategorization  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_MifidCategorization
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_MifidCategorization  (6 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_MifidCategorization/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization)
```

## Column Lineage

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| MifidCategorizationID | etoro.Dictionary.MifidCategorization | MifidCategorizationID | passthrough | PK; 0=None, 1=Retail, 2=Professional, 3=Elective professional, 4=Retail Pending, 5=Pending |
| Name | etoro.Dictionary.MifidCategorization | Name | passthrough | Tier name |
| UpdateDate | -- | -- | ETL-computed | GETDATE() at load time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
