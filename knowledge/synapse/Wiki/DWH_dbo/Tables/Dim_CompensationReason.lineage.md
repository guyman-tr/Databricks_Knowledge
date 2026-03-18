# Lineage — DWH_dbo.Dim_CompensationReason

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| CompensationReasonID | BackOffice.CompensationReason.CompensationReasonID | Passthrough |
| ParentID | BackOffice.CompensationReason.ParentID | Passthrough |
| Name | BackOffice.CompensationReason.Name | Passthrough |
| DWHCompensationID | BackOffice.CompensationReason.CompensationReasonID | Redundant copy |
| StatusID | — | Hardcoded: `1` |
| UpdateDate | — | ETL-generated: `GETDATE()` |
| InsertDate | — | ETL-generated: `GETDATE()` |

## N/A Placeholder Row

`(0, NULL, 'N/A', 0, 1, @ddate, @ddate)`

## ETL Chain

```
etoro.BackOffice.CompensationReason → DWH_staging.etoro_BackOffice_CompensationReason
  → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT + N/A row) → DWH_dbo.Dim_CompensationReason
```

*Generated: 2026-03-18*
