# Column Lineage: DWH_dbo.Dim_CashoutFeeGroup

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CashoutFeeGroup` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.CashoutFeeGroup` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Dictionary.CashoutFeeGroup (etoroDB-REAL, 3 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/CashoutFeeGroup/
  |
  v [staging]
DWH_staging.etoro_Dictionary_CashoutFeeGroup
  |
  v [SP_Dictionaries_DL_To_Synapse - TRUNCATE + INSERT]
DWH_dbo.Dim_CashoutFeeGroup (3 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **passthrough (renamed)** | Column copied as-is but given a different name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | CashoutFeeGroupID | passthrough | 1=Default, 2=Exempt, 3=Discount |
| CashoutFeeGroupName | Dictionary.CashoutFeeGroup | Name | passthrough (renamed) | Production column Name renamed to CashoutFeeGroupName in DWH |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Passthrough (renamed)** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
