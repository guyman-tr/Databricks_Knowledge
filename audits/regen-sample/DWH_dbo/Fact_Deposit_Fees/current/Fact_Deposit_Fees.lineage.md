# Column Lineage: DWH_dbo.Fact_Deposit_Fees

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_Deposit_Fees` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees` (expected) |
| **Primary Source** | `BackOffice.BillingDepositsPCIVersion` (SP) via `DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion` (staging table - no longer exists) |
| **ETL SP** | `DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse` |
| **Secondary Sources** | None (all columns from single staging source) |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
BackOffice.BillingDepositsPCIVersion (production SP, queries):
  - Billing.Deposit
  - History.Credit / History.ActiveCredit_BIGINT (date-dependent)
  - Payment processor tables (MID, 3DS, risk)
    |
    -> DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion (materialized staging, NOW GONE)
         -> SP_Fact_Deposit_Fees_DL_To_Synapse
              -> DWH_dbo.Fact_Deposit_Fees (14.4M rows, frozen 2024-06-30)

NOTE: Pipeline stopped ~July 2024. Data frozen at 2024-06-30.
      WHERE and DELETE clauses in SP are commented out (full load mode).
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **ETL-computed** | Derived by ETL, not from source. |

### Key Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CID | BackOffice.BillingDepositsPCIVersion | CID | passthrough | int; customer identifier |
| DepositID | BackOffice.BillingDepositsPCIVersion | DepositID | passthrough | int; deposit identifier |
| DepositStatus | BackOffice.BillingDepositsPCIVersion | DepositStatus | passthrough | nvarchar; 9 status values |
| DepositAmount | BackOffice.BillingDepositsPCIVersion | DepositAmount | passthrough | decimal(38,18) |
| Currency | BackOffice.BillingDepositsPCIVersion | Currency | passthrough | nvarchar; customer deposit currency |
| StatusModificationTime | BackOffice.BillingDepositsPCIVersion | StatusModificationTime | passthrough | datetime2(7); source for ModificationDateID |
| FeeinPIPs | BackOffice.BillingDepositsPCIVersion | FeeinPIPs | passthrough | int; deposit fee in PIPs (OPSE-236) |
| PIPsinUSD | BackOffice.BillingDepositsPCIVersion | PIPsinUSD | passthrough | decimal(38,18); USD fee value (OPSE-236) |
| FundingMethod | BackOffice.BillingDepositsPCIVersion | FundingMethod | passthrough | nvarchar; 19 payment methods |
| Depot | BackOffice.BillingDepositsPCIVersion | Depot | passthrough | nvarchar; payment processor/gateway |
| MID | BackOffice.BillingDepositsPCIVersion | MID | passthrough | nvarchar; merchant ID (MIMOPS-4487) |
| MIDName | BackOffice.BillingDepositsPCIVersion | MIDName | passthrough | nvarchar; MID description (MIMOPS-4487) |
| Regulation | BackOffice.BillingDepositsPCIVersion | Regulation | passthrough | nvarchar; regulatory jurisdiction |
| Brand | BackOffice.BillingDepositsPCIVersion | Brand | passthrough | nvarchar; card network brand |
| RollbackReason | BackOffice.BillingDepositsPCIVersion | RollbackReason | passthrough | nvarchar; added MIMOPSA-09421 |
| ExternalTransactionID | BackOffice.BillingDepositsPCIVersion | ExternalTransactionID | passthrough | nvarchar; added MIMOPSA-14499 |
| (all other 33 columns) | BackOffice.BillingDepositsPCIVersion | same name | passthrough | see DDL for full list |
| ModificationDateID | ETL computation from StatusModificationTime | - | ETL-computed | convert(int,convert(varchar,dateadd(day,datediff(day,0,StatusModificationTime),0),112)) -> YYYYMMDD integer |
| UpdateDate | ETL execution time | - | ETL-computed | getdate() at SP run time; range 2023-11-28 to 2024-07-01 |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 47 (all source columns) |
| **ETL-computed** | 2 (ModificationDateID, UpdateDate) |
| **Total** | 49 |
