# Column Lineage: DWH_dbo.Dim_AccountStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_AccountStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` |
| **Primary Source** | `Dictionary.AccountStatus` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Dictionary.AccountStatus (etoroDB-REAL)
  -> Generic Pipeline (Override, 1440min/daily)
  -> Bronze/etoro/Dictionary/AccountStatus/ (parquet)
  -> DWH_staging.etoro_Dictionary_AccountStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_AccountStatus
  -> Generic Pipeline (Override, 1440min/daily)
  -> Gold/sql_dp_prod_we/DWH_dbo/Dim_AccountStatus/
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus (UC)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **cast/convert** | Type conversion only. |
| **ETL-computed** | Derived/calculated by ETL SP. Not from any single source. |
| **join-enriched** | Joined from a secondary source table during ETL. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| AccountStatusID | Dictionary.AccountStatus | AccountStatusID | cast/convert | int in DWH vs tinyint in production |
| AccountStatusName | Dictionary.AccountStatus | AccountStatusName | passthrough | varchar(50) in both |
| StatusID | - | - | ETL-computed | Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows |
| UpdateDate | - | - | ETL-computed | GETDATE() on each reload run |
| InsertDate | - | - | ETL-computed | GETDATE() on each reload run, identical to UpdateDate |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Cast/Convert** | 1 |
| **ETL-computed** | 3 |
| **Total** | 5 |
