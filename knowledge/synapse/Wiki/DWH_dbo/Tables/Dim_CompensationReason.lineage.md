# Column Lineage: DWH_dbo.Dim_CompensationReason

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CompensationReason` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason` |
| **Primary Source** | `BackOffice.CompensationReason` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.BackOffice.CompensationReason (production, 130+ rows)
  -> Generic Pipeline (daily Override)
  -> Bronze: general.bronze_etoro_backoffice_compensationreason
  -> DWH_staging.etoro_BackOffice_CompensationReason
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, CompensationReasonID->DWHCompensationID, StatusID=1)
  -> SP_Dictionaries_DL_To_Synapse (INSERT ID=0 placeholder with @ddate)
  -> DWH_dbo.Dim_CompensationReason (133 rows)
  -> Generic Pipeline (daily Override)
  -> Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason
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
| CompensationReasonID | BackOffice.CompensationReason | CompensationReasonID | passthrough | PK in both layers |
| ParentID | BackOffice.CompensationReason | ParentID | passthrough | Self-reference for 2-level hierarchy |
| Name | BackOffice.CompensationReason | Name | passthrough | Same name, same value |
| DWHCompensationID | BackOffice.CompensationReason | CompensationReasonID | rename | DWHCompensationID = CompensationReasonID (identical values, redundant column) |
| StatusID | - | - | ETL-computed | Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse |
| UpdateDate | - | - | ETL-computed | GETDATE() for standard rows; CAST(GETDATE() AS DATE) for ID=0 placeholder |
| InsertDate | - | - | ETL-computed | GETDATE() for standard rows; CAST(GETDATE() AS DATE) for ID=0 placeholder |

### Dropped Production Columns

| Production Column | Reason Dropped |
|-----------------|----------------|
| DisplayName | Not loaded by SP_Dictionaries_DL_To_Synapse |
| IsShownInHistory | Not loaded by SP_Dictionaries_DL_To_Synapse |
| IsCashflowForGain | Not loaded by SP_Dictionaries_DL_To_Synapse |
| IsTaxable | Not loaded by SP_Dictionaries_DL_To_Synapse |
| IsActive | Not loaded by SP_Dictionaries_DL_To_Synapse |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **Rename** | 1 |
| **ETL-computed** | 3 |
| **Total** | 7 |
