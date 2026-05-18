# Column Lineage: main.billing.bronze_etoro_billing_depositrollbacktracking

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_depositrollbacktracking` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-18 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bronze_etoro_billing_depositrollbacktracking.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `RollbackID` | `—` | `—` | `runtime_lineage` |
| 2 | `CID` | `—` | `—` | `runtime_lineage` |
| 3 | `DepositID` | `—` | `—` | `runtime_lineage` |
| 4 | `PaymentStatusID` | `—` | `—` | `runtime_lineage` |
| 5 | `TotalRollbackAmountInUSD` | `—` | `—` | `runtime_lineage` |
| 6 | `TotalRollbackAmountInCurrency` | `—` | `—` | `runtime_lineage` |
| 7 | `RollbackAmountInUSD` | `—` | `—` | `runtime_lineage` |
| 8 | `RollbackAmountInCurrency` | `—` | `—` | `runtime_lineage` |
| 9 | `CurrencyID` | `—` | `—` | `runtime_lineage` |
| 10 | `ExchangeRate` | `—` | `—` | `runtime_lineage` |
| 11 | `BaseExchangeRate` | `—` | `—` | `runtime_lineage` |
| 12 | `ExchangeFee` | `—` | `—` | `runtime_lineage` |
| 13 | `ReferenceNumber` | `—` | `—` | `runtime_lineage` |
| 14 | `RollbackReasonID` | `—` | `—` | `runtime_lineage` |
| 15 | `Comments` | `—` | `—` | `runtime_lineage` |
| 16 | `RollbackDate` | `—` | `—` | `runtime_lineage` |
| 17 | `CreateDate` | `—` | `—` | `runtime_lineage` |
| 18 | `ModificationDate` | `—` | `—` | `runtime_lineage` |
| 19 | `ManagerID` | `—` | `—` | `runtime_lineage` |
| 20 | `IsCanceled` | `—` | `—` | `runtime_lineage` |
