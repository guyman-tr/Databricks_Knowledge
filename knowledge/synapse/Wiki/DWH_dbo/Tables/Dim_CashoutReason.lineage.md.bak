# Column Lineage: DWH_dbo.Dim_CashoutReason

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CashoutReason` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason` |
| **Primary Source** | `Dictionary.CashoutReason` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.CashoutReason (production)
  -> Generic Pipeline (daily Override)
  -> Bronze: general.bronze_etoro_dictionary_cashoutreason
  -> DWH_staging.etoro_Dictionary_CashoutReason
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_CashoutReason
  -> Generic Pipeline (daily Override)
  -> Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason
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
| CashoutReasonID | Dictionary.CashoutReason | CashoutReasonID | passthrough | PK in both layers |
| Name | Dictionary.CashoutReason | Name | passthrough | Same name, same value |
| UpdateDate | - | - | ETL-computed | GETDATE() set by SP_Dictionaries_DL_To_Synapse on each load |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
