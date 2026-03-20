# Column Lineage: DWH_dbo.Dim_CalculationType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CalculationType` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.CalculationType` (`HistoryCosts`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
HistoryCosts.Dictionary.CalculationType (8 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/HistoryCosts/Dictionary/CalculationType/
  |
  v [staging]
DWH_staging.HistoryCosts_Dictionary_CalculationType
  |
  v [SP_Dictionaries_DL_To_Synapse - TRUNCATE + INSERT]
DWH_dbo.Dim_CalculationType (8 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough (renamed)** | Column copied as-is but given a different name in DWH. |
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CalculationTypeId | Dictionary.CalculationType | Id | passthrough (renamed) | Production Id renamed to CalculationTypeId in DWH |
| CalculationType | Dictionary.CalculationType | CalculationType | passthrough | varchar(50) in production, nvarchar(max) in DWH |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Passthrough (renamed)** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
