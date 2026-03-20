# Column Lineage: DWH_dbo.Dim_CashoutStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CashoutStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus` |
| **Primary Source** | `Dictionary.CashoutStatus` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.CashoutStatus (17 rows in production)
  -> Generic Pipeline (daily Override)
  -> Bronze: general.bronze_etoro_dictionary_cashoutstatus
  -> DWH_staging.etoro_Dictionary_CashoutStatus (4 rows: IDs 1-4 only)
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT + ID=0 placeholder)
  -> DWH_dbo.Dim_CashoutStatus (5 rows: IDs 0-4)
  -> Generic Pipeline (daily Override)
  -> Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus
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
| CashoutStatusID | Dictionary.CashoutStatus | CashoutStatusID | passthrough | PK |
| Name | Dictionary.CashoutStatus | Name | passthrough | Same name, same value |
| DWHCashoutStatusID | Dictionary.CashoutStatus | CashoutStatusID | rename | DWHCashoutStatusID = CashoutStatusID (same value, different name) |
| StatusID | - | - | ETL-computed | Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse |
| UpdateDate | - | - | ETL-computed | GETDATE() for staging rows; CAST(GETDATE() AS DATE) for ID=0 placeholder |
| InsertDate | - | - | ETL-computed | GETDATE() for staging rows; CAST(GETDATE() AS DATE) for ID=0 placeholder |

### Dropped Production Columns

| Production Column | Reason Dropped |
|-----------------|----------------|
| IsFinishedWithoutMoneyTransfer | Not loaded by SP_Dictionaries_DL_To_Synapse |
| IsFinalStatus | Not loaded by SP_Dictionaries_DL_To_Synapse |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Rename** | 1 |
| **ETL-computed** | 3 |
| **Total** | 6 |
