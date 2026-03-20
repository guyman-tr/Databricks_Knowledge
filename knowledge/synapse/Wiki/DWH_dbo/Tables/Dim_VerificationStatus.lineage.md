# Column Lineage: DWH_dbo.Dim_VerificationStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_VerificationStatus` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.VerificationStatus` (`UserApiDB`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
UserApiDB.Dictionary.VerificationStatus (UserApiDB, 3 rows)
  |
  v [Generic Pipeline — daily, Override, parquet]
Bronze/UserApiDB/Dictionary/VerificationStatus/
  |
  v [staging]
DWH_staging.UserApiDB_Dictionary_VerificationStatus
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT]
DWH_dbo.Dim_VerificationStatus (3 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| VerificationStatusID | UserApiDB.Dictionary.VerificationStatus | VerificationStatusID | passthrough | 3 distinct values |
| Name | UserApiDB.Dictionary.VerificationStatus | Name | passthrough | varchar(20) — may truncate long names |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
