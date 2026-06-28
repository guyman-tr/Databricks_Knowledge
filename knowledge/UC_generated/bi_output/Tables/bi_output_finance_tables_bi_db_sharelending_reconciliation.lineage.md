# Column Lineage: main.bi_output.bi_output_finance_tables_bi_db_sharelending_reconciliation

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_finance_tables_bi_db_sharelending_reconciliation` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-06-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_finance_tables_bi_db_sharelending_reconciliation.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `ReportDate` | `—` | `—` | `runtime_lineage` |
| 2 | `ReportDateID` | `—` | `—` | `runtime_lineage` |
| 3 | `DateToCallClosingBalance` | `—` | `—` | `runtime_lineage` |
| 4 | `DateToCallOpeningBalance` | `—` | `—` | `runtime_lineage` |
| 5 | `ISIN` | `—` | `—` | `runtime_lineage` |
| 6 | `CUSIP` | `—` | `—` | `runtime_lineage` |
| 7 | `Symbol` | `—` | `—` | `runtime_lineage` |
| 8 | `BNYOpeningLendingOptIn` | `—` | `—` | `runtime_lineage` |
| 9 | `BNYClosingLendingOptIn` | `—` | `—` | `runtime_lineage` |
| 10 | `eToroLendingOpeningBalance` | `—` | `—` | `runtime_lineage` |
| 11 | `eToroLendingClosingBalance` | `—` | `—` | `runtime_lineage` |
| 12 | `TotalLoans` | `—` | `—` | `runtime_lineage` |
| 13 | `LoansBNY` | `—` | `—` | `runtime_lineage` |
| 14 | `QuantityOut` | `—` | `—` | `runtime_lineage` |
| 15 | `QuantityIn` | `—` | `—` | `runtime_lineage` |
| 16 | `ClosedLoans` | `—` | `—` | `runtime_lineage` |
| 17 | `NewLoans` | `—` | `—` | `runtime_lineage` |
| 18 | `PartialClosure` | `—` | `—` | `runtime_lineage` |
| 19 | `ClosingLendingCalcBny` | `—` | `—` | `runtime_lineage` |
| 20 | `ClosingLendingCalcEtoro` | `—` | `—` | `runtime_lineage` |
| 21 | `IsGapLoansBNYvsEquilend` | `—` | `—` | `runtime_lineage` |
| 22 | `IsGapOptInBNYvsEtoro` | `—` | `—` | `runtime_lineage` |
| 23 | `IsGapClosingVsCalc` | `—` | `—` | `runtime_lineage` |
| 24 | `IsGapOpeningBalance` | `—` | `—` | `runtime_lineage` |
| 25 | `ManualMovement` | `—` | `—` | `runtime_lineage` |
| 26 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
| 27 | `ExistingLoans` | `—` | `—` | `runtime_lineage` |
| 28 | `eToroOptInClosingPool` | `—` | `—` | `runtime_lineage` |
| 29 | `PartialOpening` | `—` | `—` | `runtime_lineage` |
