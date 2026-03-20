# Column Lineage: DWH_dbo.Dim_VerificationLevel

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_VerificationLevel` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.VerificationLevel` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.VerificationLevel (etoroDB-REAL, 4 rows: ID 0-3)
  |
  v [Generic Pipeline — daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/VerificationLevel/
  |
  v [staging]
DWH_staging.etoro_Dictionary_VerificationLevel
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT + sentinel row]
DWH_dbo.Dim_VerificationLevel (5 rows: ID -1,0,1,2,3)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **alias-copy** | Same source value, mapped to a different column name. |
| **ETL-computed** | Derived/calculated by ETL SP. Not from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ID | Dictionary.VerificationLevel | ID | passthrough | -1 row added as DWH sentinel |
| Name | Dictionary.VerificationLevel | Name | passthrough | "Level 0"-"Level 3"; NULL for sentinel row |
| DWHVerificationLevelID | Dictionary.VerificationLevel | ID | alias-copy | `[ID] AS [DWHVerificationLevelID]` in SP |
| StatusID | — | — | ETL-computed | Hardcoded to 1 for all rows; 0 for sentinel |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution time |
| InsertDate | — | — | ETL-computed | GETDATE() at SP execution time (equals UpdateDate) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Alias-copy** | 1 |
| **ETL-computed** | 3 |
| **Total** | 6 |
