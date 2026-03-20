# Column Lineage: DWH_dbo.Dim_ClientWithdrawReason

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ClientWithdrawReason` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason` |
| **Primary Source** | `Dictionary.ClientWithdrawReason` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.ClientWithdrawReason (production)
  -> Generic Pipeline (daily Override)
  -> Bronze: general.bronze_etoro_dictionary_clientwithdrawreason
  -> DWH_staging.etoro_Dictionary_ClientWithdrawReason
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, Name->ClientWithdrawReasonName)
  -> DWH_dbo.Dim_ClientWithdrawReason
  -> Generic Pipeline (daily Override)
  -> Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ClientWithdrawReasonID | Dictionary.ClientWithdrawReason | ClientWithdrawReasonID | passthrough | PK in both layers |
| ClientWithdrawReasonName | Dictionary.ClientWithdrawReason | Name | rename | Production column `Name` -> DWH column `ClientWithdrawReasonName` |
| UpdateDate | - | - | ETL-computed | GETDATE() set by SP_Dictionaries_DL_To_Synapse on each load |

### Dropped Production Columns

| Production Column | Reason Dropped |
|-----------------|----------------|
| IsActive | Not loaded by SP_Dictionaries_DL_To_Synapse |
| DisplayOrder | Not loaded by SP_Dictionaries_DL_To_Synapse |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
