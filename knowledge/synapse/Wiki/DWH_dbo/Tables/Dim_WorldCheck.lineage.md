# Column Lineage: DWH_dbo.Dim_WorldCheck

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_WorldCheck` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.WorldCheck` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.WorldCheck (etoroDB-REAL, 5 rows)
  |
  v [Generic Pipeline — daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/WorldCheck/
  |
  v [staging]
DWH_staging.etoro_Dictionary_WorldCheck
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT]
DWH_dbo.Dim_WorldCheck (5 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **type-widened** | Same value, data type widened (TINYINT → INT). |
| **ETL-computed** | Derived/calculated by ETL SP. Not from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| WorldCheckID | Dictionary.WorldCheck | WorldCheckID | type-widened | Source is TINYINT; DWH is INT. Values: 0-4 |
| WorldCheckName | Dictionary.WorldCheck | WorldCheckName | passthrough | ID=0 has empty string (not NULL) |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Type-widened** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
