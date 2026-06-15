# Column Lineage: main.bi_dealing.bi_output_dealing_ib_recon_eod

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_ib_recon_eod` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_dealing_ib_recon_eod.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `InstrumentID` | `—` | `—` | `runtime_lineage` |
| 2 | `InstrumentDisplayName` | `—` | `—` | `runtime_lineage` |
| 3 | `ISINCode` | `—` | `—` | `runtime_lineage` |
| 4 | `IsBuy` | `—` | `—` | `runtime_lineage` |
| 5 | `CurrencyPrimary` | `—` | `—` | `runtime_lineage` |
| 6 | `Exchange` | `—` | `—` | `runtime_lineage` |
| 7 | `ClientAccountID` | `—` | `—` | `runtime_lineage` |
| 8 | `IB_Symbol` | `—` | `—` | `runtime_lineage` |
| 9 | `eToro_Symbol` | `—` | `—` | `runtime_lineage` |
| 10 | `IB_Units` | `—` | `—` | `runtime_lineage` |
| 11 | `eToro_Units` | `—` | `—` | `runtime_lineage` |
| 12 | `ClientUnits` | `—` | `—` | `runtime_lineage` |
| 13 | `IB-eToro_Units` | `—` | `—` | `runtime_lineage` |
| 14 | `IB-Clients_Units` | `—` | `—` | `runtime_lineage` |
| 15 | `IB_LocalAmount` | `—` | `—` | `runtime_lineage` |
| 16 | `IB_AmountUSD` | `—` | `—` | `runtime_lineage` |
| 17 | `eToroLocalAmount` | `—` | `—` | `runtime_lineage` |
| 18 | `eToroAmountUSD` | `—` | `—` | `runtime_lineage` |
| 19 | `Clients_AmountNOP` | `—` | `—` | `runtime_lineage` |
| 20 | `Reality-Supposed` | `—` | `—` | `runtime_lineage` |
| 21 | `Reality-Client` | `—` | `—` | `runtime_lineage` |
| 22 | `HedgeServerID` | `—` | `—` | `runtime_lineage` |
| 23 | `IB_Rate` | `—` | `—` | `runtime_lineage` |
| 24 | `FX_Rate` | `—` | `—` | `runtime_lineage` |
| 25 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
| 26 | `etr_y` | `—` | `—` | `runtime_lineage` |
| 27 | `etr_ym` | `—` | `—` | `runtime_lineage` |
| 28 | `etr_ymd` | `—` | `—` | `runtime_lineage` |
