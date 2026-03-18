# Lineage — DWH_dbo.Dim_CountryIP

## ETL Chain

```
etoro.Dictionary.CountryIP → DWH_staging.etoro_Dictionary_CountryIP
  → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) → DWH_dbo.Dim_CountryIP
```

All 4 source columns passthrough; UpdateDate is ETL-generated (`GETDATE()`).

*Generated: 2026-03-18*
