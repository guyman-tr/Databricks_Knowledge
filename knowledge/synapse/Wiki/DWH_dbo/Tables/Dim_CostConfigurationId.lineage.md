# Column Lineage: DWH_dbo.Dim_CostConfigurationId

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CostConfigurationId` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `HistoryCosts.Dictionary.CostConfigurationId` (HistoryCosts) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
HistoryCosts.Dictionary.CostConfigurationId
  -> [direct load - not via Generic Pipeline]
  -> DWH_staging.HistoryCosts_Dictionary_CostConfigurationId (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_CostConfigurationId (4 rows)
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
| CostConfigurationId | HistoryCosts.Dictionary.CostConfigurationId | Id | rename | Source column is `Id` (int). Renamed to CostConfigurationId in DWH for semantic clarity. |
| CostConfiguration | HistoryCosts.Dictionary.CostConfigurationId | CostConfigurationId | rename | Source column is also named `CostConfigurationId` (nvarchar(max)) - the display name string. Renamed to CostConfiguration in DWH to avoid collision with the integer PK. |
| UpdateDate | - | - | ETL-computed | Set to GETDATE() by SP_Dictionaries_DL_To_Synapse. Not from source. Reflects ETL run time. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 0 |
| **Rename** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
