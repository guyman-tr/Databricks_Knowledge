# Lineage — DWH_dbo.Dim_CountryBin

## ETL Chain

```
etoro.Dictionary.CountryBin → DWH_staging.etoro_Dictionary_CountryBin
  → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) → DWH_dbo.Dim_CountryBin
```

All 11 source columns passthrough; UpdateDate is ETL-generated (`GETDATE()`).

*Generated: 2026-03-18*
