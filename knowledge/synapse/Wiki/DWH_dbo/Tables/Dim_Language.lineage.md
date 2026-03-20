# Column Lineage: DWH_dbo.Dim_Language

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Language` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` |
| **Primary Source** | `etoro.Dictionary.Language` (etoroDB-REAL) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.Language  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_Language
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_Language  (29 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Language/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language)
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
| LanguageID | etoro.Dictionary.Language | LanguageID | passthrough | PK; platform language ID; 0=N/A placeholder |
| Name | etoro.Dictionary.Language | Name | passthrough | Language name; char(50) -- use RTRIM() |
| DWHLanguageID | etoro.Dictionary.Language | LanguageID | rename | Always = LanguageID; DWH redundancy pattern |
| StatusID | -- | -- | ETL-computed | Hardcoded 1 for all rows |
| UpdateDate | -- | -- | ETL-computed | GETDATE() at load time |
| InsertDate | -- | -- | ETL-computed | GETDATE() at load time; same as UpdateDate |
| IsoCode | etoro.Dictionary.Language | IsoCode | passthrough | ISO 639-1 two-letter code; nchar(10) padded |
| CultureCode | etoro.Dictionary.Language | CultureCode | passthrough | IETF BCP 47 locale tag; nchar(10) padded |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **Rename** | 1 |
| **ETL-computed** | 3 |
| **Total** | 8 |
