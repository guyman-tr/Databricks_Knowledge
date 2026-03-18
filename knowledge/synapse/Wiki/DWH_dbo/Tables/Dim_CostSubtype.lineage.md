# Lineage — DWH_dbo.Dim_CostSubtype

## ETL Chain

```
HistoryCosts.Dictionary.CostSubtype → DWH_staging.HistoryCosts_Dictionary_CostSubtype
  → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) → DWH_dbo.Dim_CostSubtype
```

*Generated: 2026-03-18*
