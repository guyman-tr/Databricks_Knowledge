# Column Lineage: DWH_dbo.Dim_DocumentStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_DocumentStatus` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `etoro.Dictionary.DocumentStatus` (etoro) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.DocumentStatus
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_DocumentStatus (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_DocumentStatus (7 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DocumentStatusID | etoro.Dictionary.DocumentStatus | DocumentStatusID | passthrough | int PK. 7 values (0-6). |
| DocumentStatusName | etoro.Dictionary.DocumentStatus | DocumentStatusName | passthrough | Same column name in source and DWH. 7 KYC states. |
| UpdateDate | - | - | ETL-computed | GETDATE() on each reload. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
