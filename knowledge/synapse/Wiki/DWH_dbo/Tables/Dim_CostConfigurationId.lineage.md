# Lineage — DWH_dbo.Dim_CostConfigurationId

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| CostConfigurationId | HistoryCosts.Dictionary.CostConfigurationId.Id | Renamed |
| CostConfiguration | HistoryCosts.Dictionary.CostConfigurationId.CostConfigurationId | Renamed (source column confusingly named) |
| UpdateDate | — | ETL-generated: `GETDATE()` |

## ETL Chain

```
HistoryCosts.Dictionary.CostConfigurationId → DWH_staging.HistoryCosts_Dictionary_CostConfigurationId
  → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) → DWH_dbo.Dim_CostConfigurationId
```

*Generated: 2026-03-18*
