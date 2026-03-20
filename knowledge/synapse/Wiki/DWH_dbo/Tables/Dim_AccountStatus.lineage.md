# Column Lineage: DWH_dbo.Dim_AccountStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_AccountStatus` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.AccountStatus` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Dictionary.AccountStatus (etoroDB-REAL, 2 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/AccountStatus/
  |
  v [staging]
DWH_staging.etoro_Dictionary_AccountStatus
  |
  v [SP_Dictionaries_DL_To_Synapse - TRUNCATE + INSERT + ID=0 placeholder]
DWH_dbo.Dim_AccountStatus (3 rows)
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
| AccountStatusID | Dictionary.AccountStatus | AccountStatusID | passthrough | Also has ID=0 row added as DWH placeholder |
| AccountStatusName | Dictionary.AccountStatus | AccountStatusName | passthrough | 'N/A' for ID=0 placeholder |
| StatusID | - | - | ETL-computed | Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time |
| InsertDate | - | - | ETL-computed | GETDATE() at SP execution time (always equals UpdateDate) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 3 |
| **Total** | 5 |
