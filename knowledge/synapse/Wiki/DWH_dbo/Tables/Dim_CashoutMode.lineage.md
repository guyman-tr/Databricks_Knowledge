# Column Lineage: DWH_dbo.Dim_CashoutMode

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CashoutMode` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.CashoutMode` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Dictionary.CashoutMode (etoroDB-REAL, 4 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/CashoutMode/
  |
  v [staging]
DWH_staging.etoro_Dictionary_CashoutMode
  |
  v [SP_Dictionaries_DL_To_Synapse - TRUNCATE + INSERT]
DWH_dbo.Dim_CashoutMode (4 rows)
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
| CashoutModeID | Dictionary.CashoutMode | CashoutModeID | passthrough | 0=Manual, 1=Auto Create, 2=Mass Auto Create, 3=Instant Withdrawal |
| CashoutModeName | Dictionary.CashoutMode | CashoutModeName | passthrough | Unique mode name |
| CashoutModeWeight | Dictionary.CashoutMode | CashoutModeWeight | passthrough | Processing priority weight (higher = first) |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **ETL-computed** | 1 |
| **Total** | 4 |
