# Column Lineage: DWH_dbo.Dim_PaymentStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PaymentStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` |
| **Primary Source** | `etoro.Dictionary.PaymentStatus` (etoroDB-REAL) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None (PaymentStatusID=-1 is a manually-inserted sentinel) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.PaymentStatus  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_PaymentStatus
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_PaymentStatus  (40 rows; 39 from SP + 1 manual sentinel)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_PaymentStatus/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **rename** | Same value, different column name. |
| **ETL-computed** | Derived by SP logic; not from any source column. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PaymentStatusID | etoro.Dictionary.PaymentStatus | PaymentStatusID | passthrough | PK; -1 row manually inserted (not from SP) |
| Name | etoro.Dictionary.PaymentStatus | Name | passthrough | Payment status display name |
| DWHPaymentStatusID | etoro.Dictionary.PaymentStatus | PaymentStatusID | rename | Always = PaymentStatusID for IDs >= 1; exception: -1 row has DWHPaymentStatusID=0 |
| StatusID | -- | -- | ETL-computed | Hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed | GETDATE() for SP rows; midnight for manual -1 row |
| InsertDate | -- | -- | ETL-computed | GETDATE(); same as UpdateDate |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Rename** | 1 |
| **ETL-computed** | 3 |
| **Total** | 6 |
