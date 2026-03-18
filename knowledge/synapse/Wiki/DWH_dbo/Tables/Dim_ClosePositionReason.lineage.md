# Lineage — DWH_dbo.Dim_ClosePositionReason

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| ClosePositionReasonID | Dictionary.ClosePositionActionType.ID | Renamed |
| Name | Dictionary.ClosePositionActionType.ClosePositionActionName | Renamed |
| StatusID | — | Hardcoded: `1` |
| UpdateDate | — | ETL-generated: `GETDATE()` |
| InsertDate | — | ETL-generated: `GETDATE()` |

## ETL Chain

```
etoro.Dictionary.ClosePositionActionType → DWH_staging.etoro_Dictionary_ClosePositionActionType
  → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) → DWH_dbo.Dim_ClosePositionReason
```

*Generated: 2026-03-18*
