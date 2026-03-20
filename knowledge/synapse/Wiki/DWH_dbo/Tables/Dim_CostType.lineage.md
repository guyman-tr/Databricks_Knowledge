# Column Lineage: DWH_dbo.Dim_CostType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CostType` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `HistoryCosts.Dictionary.CostType` (HistoryCosts) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
HistoryCosts.Dictionary.CostType
  -> [direct load - not via Generic Pipeline]
  -> DWH_staging.HistoryCosts_Dictionary_CostType (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_CostType (4 rows)
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
| CostTypeId | HistoryCosts.Dictionary.CostType | Id | rename | Source column is `Id` (int). Renamed to CostTypeId for semantic clarity. |
| CostType | HistoryCosts.Dictionary.CostType | CostType | passthrough | Same column name in source and DWH. |
| UpdateDate | - | - | ETL-computed | Set to GETDATE() by SP_Dictionaries_DL_To_Synapse. Not from source. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
