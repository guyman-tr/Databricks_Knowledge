# Column Lineage: main.bi_output.bi_output_customer_compliance_mas_daily_client_metrics

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_customer_compliance_mas_daily_client_metrics` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_customer_compliance_mas_daily_client_metrics.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `Date` | `—` | `—` | `runtime_lineage` |
| 2 | `DateID` | `—` | `—` | `runtime_lineage` |
| 3 | `CID` | `—` | `—` | `runtime_lineage` |
| 4 | `GCID` | `—` | `—` | `runtime_lineage` |
| 5 | `Regulation_current` | `—` | `—` | `runtime_lineage` |
| 6 | `Region` | `—` | `—` | `runtime_lineage` |
| 7 | `Country` | `—` | `—` | `runtime_lineage` |
| 8 | `VerificationLevelID` | `—` | `—` | `runtime_lineage` |
| 9 | `PlayerStatus` | `—` | `—` | `runtime_lineage` |
| 10 | `PlayerStatusReason` | `—` | `—` | `runtime_lineage` |
| 11 | `PlayerStatusSubReason` | `—` | `—` | `runtime_lineage` |
| 12 | `Club` | `—` | `—` | `runtime_lineage` |
| 13 | `DateRangeID` | `—` | `—` | `runtime_lineage` |
| 14 | `RealizedEquity` | `—` | `—` | `runtime_lineage` |
| 15 | `RealizedEquity_club` | `—` | `—` | `runtime_lineage` |
| 16 | `ManualCFDopen_poscount` | `—` | `—` | `runtime_lineage` |
| 17 | `ManualCFDopen_amount` | `—` | `—` | `runtime_lineage` |
| 18 | `ManualCFDopen_leveraged_poscount` | `—` | `—` | `runtime_lineage` |
| 19 | `ManualCFDopen_leveraged_amount` | `—` | `—` | `runtime_lineage` |
| 20 | `ManualCFDopen_unleveraged_poscount` | `—` | `—` | `runtime_lineage` |
| 21 | `ManualCFDopen_unleveraged_amount` | `—` | `—` | `runtime_lineage` |
| 22 | `ManualCFDCryptoopen_poscount` | `—` | `—` | `runtime_lineage` |
| 23 | `ManualCFDCryptoopen_amount` | `—` | `—` | `runtime_lineage` |
| 24 | `ManualRealCryptoopen_poscount` | `—` | `—` | `runtime_lineage` |
| 25 | `ManualRealCryptoopen_amount` | `—` | `—` | `runtime_lineage` |
| 26 | `ManualETFopen_poscount` | `—` | `—` | `runtime_lineage` |
| 27 | `ManualETFopen_amount` | `—` | `—` | `runtime_lineage` |
| 28 | `ManualStocksopen_poscount` | `—` | `—` | `runtime_lineage` |
| 29 | `ManualStocksopen_amount` | `—` | `—` | `runtime_lineage` |
| 30 | `Deposit_Amount` | `—` | `—` | `runtime_lineage` |
| 31 | `Cashout_Amount` | `—` | `—` | `runtime_lineage` |
| 32 | `NetDeposit_Amount` | `—` | `—` | `runtime_lineage` |
| 33 | `ManualCFD_Commissions` | `—` | `—` | `runtime_lineage` |
| 34 | `ManualCFD_FullCommissions` | `—` | `—` | `runtime_lineage` |
| 35 | `ManualCFD_CommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 36 | `ManualCFD_FullCommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 37 | `ManualCFDcrypto_Commissions` | `—` | `—` | `runtime_lineage` |
| 38 | `ManualCFDcrypto_FullCommissions` | `—` | `—` | `runtime_lineage` |
| 39 | `ManualCFDcrypto_CommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 40 | `ManualCFDcrypto_FullCommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 41 | `ManualRealcrypto_Commissions` | `—` | `—` | `runtime_lineage` |
| 42 | `ManualRealcrypto_FullCommissions` | `—` | `—` | `runtime_lineage` |
| 43 | `ManualRealcrypto_CommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 44 | `ManualRealcrypto_FullCommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 45 | `ManualStocks_Commissions` | `—` | `—` | `runtime_lineage` |
| 46 | `ManualStocks_FullCommissions` | `—` | `—` | `runtime_lineage` |
| 47 | `ManualStocks_CommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 48 | `ManualStocks_FullCommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 49 | `ManualETF_Commissions` | `—` | `—` | `runtime_lineage` |
| 50 | `ManualETF_FullCommissions` | `—` | `—` | `runtime_lineage` |
| 51 | `ManualETF_CommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 52 | `ManualETF_FullCommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 53 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
