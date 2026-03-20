# Column Lineage: DWH_dbo.Dim_RedeemReason

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_RedeemReason` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason` |
| **Primary Source** | `Dictionary.RedeemReason` (etoro) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.RedeemReason (production)
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/RedeemReason/
  -> DWH_staging.etoro_Dictionary_RedeemReason
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_RedeemReason
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| RedeemReasonID | Dictionary.RedeemReason | RedeemReasonID | passthrough | PK. 1-20, gap at 17. |
| RedeemReasonName | Dictionary.RedeemReason | Name | rename | Name -> RedeemReasonName |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP_Dictionaries reload time |

## Lost Columns (Production -> DWH)

| Production Column | Reason Dropped |
|-------------------|----------------|
| Description | Always NULL in production - no value to carry |
| DisplayName | Duplicates Name for all current rows - redundant |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
