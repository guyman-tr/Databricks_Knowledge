# Column Lineage: DWH_dbo.Dim_ClosePositionReason

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ClosePositionReason` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason` |
| **Primary Source** | `Dictionary.ClosePositionActionType` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.ClosePositionActionType (production, 27 rows)
  -> Generic Pipeline (daily Override)
  -> Bronze: general.bronze_etoro_dictionary_closepositionactiontype
  -> DWH_staging.etoro_Dictionary_ClosePositionActionType
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ID->ClosePositionReasonID, ClosePositionActionName->Name)
  -> DWH_dbo.Dim_ClosePositionReason
  -> Generic Pipeline (daily Override)
  -> Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason
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
| ClosePositionReasonID | Dictionary.ClosePositionActionType | ID | rename | Production `ID` -> DWH `ClosePositionReasonID` |
| Name | Dictionary.ClosePositionActionType | ClosePositionActionName | rename | Production `ClosePositionActionName` -> DWH `Name` |
| StatusID | - | - | ETL-computed | Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse |
| UpdateDate | - | - | ETL-computed | GETDATE() set by SP_Dictionaries_DL_To_Synapse on each load |
| InsertDate | - | - | ETL-computed | GETDATE() set by SP_Dictionaries_DL_To_Synapse on each load |

### Dropped Production Columns

None. Production Dictionary.ClosePositionActionType has only ID and ClosePositionActionName; both are loaded (renamed).

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 0 |
| **Rename** | 2 |
| **ETL-computed** | 3 |
| **Total** | 5 |
