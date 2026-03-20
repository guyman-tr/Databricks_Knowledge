# Column Lineage: DWH_dbo.Dim_ThreeDsResponseTypes

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ThreeDsResponseTypes` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.ThreeDsResponseTypes` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.ThreeDsResponseTypes (etoroDB-REAL, 15 rows)
  |
  v [Generic Pipeline — daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/ThreeDsResponseTypes/
  |
  v [staging]
DWH_staging.etoro_Dictionary_ThreeDsResponseTypes
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT]
DWH_dbo.Dim_ThreeDsResponseTypes (15 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **renamed** | Column copied with a different name. Same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ThreeDsResponseTypeID | Dictionary.ThreeDsResponseTypes | ThreeDsResponseTypeID | passthrough | PK; 0-14 sequential IDs |
| ThreeDsResponseTypesName | Dictionary.ThreeDsResponseTypes | Name | renamed | DWH adds plural suffix to column name |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Renamed** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
