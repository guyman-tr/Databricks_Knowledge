# Column Lineage: main.billing.bronze_moneybusdb_moneybus_transactions

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_moneybusdb_moneybus_transactions` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-18 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bronze_moneybusdb_moneybus_transactions.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `ID` | `—` | `—` | `runtime_lineage` |
| 2 | `GCID` | `—` | `—` | `runtime_lineage` |
| 3 | `Created` | `—` | `—` | `runtime_lineage` |
| 4 | `CreditorTypeID` | `—` | `—` | `runtime_lineage` |
| 5 | `DebitorTypeID` | `—` | `—` | `runtime_lineage` |
| 6 | `StatusID` | `—` | `—` | `runtime_lineage` |
| 7 | `GroupID` | `—` | `—` | `runtime_lineage` |
| 8 | `ReferenceID` | `—` | `—` | `runtime_lineage` |
| 9 | `Amount` | `—` | `—` | `runtime_lineage` |
| 10 | `CurrencyID` | `—` | `—` | `runtime_lineage` |
| 11 | `Modified` | `—` | `—` | `runtime_lineage` |
| 12 | `CreditorAccountID` | `—` | `—` | `runtime_lineage` |
| 13 | `DebitorAccountID` | `—` | `—` | `runtime_lineage` |
| 14 | `StatusReasonID` | `—` | `—` | `runtime_lineage` |
| 15 | `PartitionCol` | `—` | `—` | `runtime_lineage` |
| 16 | `Trace` | `—` | `—` | `runtime_lineage` |
| 17 | `ValidFrom` | `—` | `—` | `runtime_lineage` |
| 18 | `ValidTo` | `—` | `—` | `runtime_lineage` |
| 19 | `CreditorReferenceID` | `—` | `—` | `runtime_lineage` |
| 20 | `DebitorReferenceID` | `—` | `—` | `runtime_lineage` |
| 21 | `BaseExchangeRate` | `—` | `—` | `runtime_lineage` |
| 22 | `ExchangeRate` | `—` | `—` | `runtime_lineage` |
| 23 | `ExchangeFee` | `—` | `—` | `runtime_lineage` |
| 24 | `FlowID` | `—` | `—` | `runtime_lineage` |
| 25 | `ExtraData` | `—` | `—` | `runtime_lineage` |
| 26 | `CreditorBaseExchangeRate` | `—` | `—` | `runtime_lineage` |
| 27 | `CreditorExchangeFee` | `—` | `—` | `runtime_lineage` |
| 28 | `CreditorExchangeRate` | `—` | `—` | `runtime_lineage` |
| 29 | `DebitorBaseExchangeRate` | `—` | `—` | `runtime_lineage` |
| 30 | `DebitorExchangeFee` | `—` | `—` | `runtime_lineage` |
| 31 | `DebitorExchangeRate` | `—` | `—` | `runtime_lineage` |
| 32 | `etr_y` | `—` | `—` | `runtime_lineage` |
| 33 | `etr_ym` | `—` | `—` | `runtime_lineage` |
| 34 | `etr_ymd` | `—` | `—` | `runtime_lineage` |
| 35 | `HoldReferenceID` | `—` | `—` | `runtime_lineage` |
| 36 | `ReconciliationReservedUntil` | `—` | `—` | `runtime_lineage` |
| 37 | `ReconciliationAttemptCount` | `—` | `—` | `runtime_lineage` |
