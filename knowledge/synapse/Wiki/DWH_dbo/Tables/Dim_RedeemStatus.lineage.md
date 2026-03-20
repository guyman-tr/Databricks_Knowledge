# Column Lineage: DWH_dbo.Dim_RedeemStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_RedeemStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus` |
| **Primary Source** | `Dictionary.RedeemStatus` (etoro) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.RedeemStatus (production)
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/RedeemStatus/
  -> DWH_staging.etoro_Dictionary_RedeemStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
     + additional INSERT for ID=0 sentinel (@ddate)
  -> DWH_dbo.Dim_RedeemStatus
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus
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
| RedeemStatusID | Dictionary.RedeemStatus | RedeemStatusID | passthrough | PK. ID=0 added by ETL as sentinel. |
| Name | Dictionary.RedeemStatus | Name | passthrough | Internal state code name |
| DisplayName | Dictionary.RedeemStatus | DisplayName | passthrough | User-facing label |
| IsCancelable | Dictionary.RedeemStatus | IsCancelable | passthrough | Cancellability flag |
| InsertDate | - | - | ETL-computed | GETDATE() at INSERT time; midnight (@ddate) for ID=0 sentinel. Not in production source. |
| UpdateDate | - | - | ETL-computed | GETDATE() at each TRUNCATE+INSERT reload |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 2 |
| **Total** | 6 |
