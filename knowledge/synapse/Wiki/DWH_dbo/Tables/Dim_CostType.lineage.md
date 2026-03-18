# Lineage — DWH_dbo.Dim_CostType

## ETL Chain

```
HistoryCosts.Dictionary.CostType → DWH_staging.HistoryCosts_Dictionary_CostType
  → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) → DWH_dbo.Dim_CostType
```

*Generated: 2026-03-18*
