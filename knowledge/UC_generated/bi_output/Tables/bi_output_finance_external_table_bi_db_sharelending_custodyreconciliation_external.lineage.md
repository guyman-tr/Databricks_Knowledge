# Column Lineage: main.bi_output.bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `ReportDate` | `—` | `—` | `runtime_lineage` |
| 2 | `OpeningBalanceDate` | `—` | `—` | `runtime_lineage` |
| 3 | `ReportDateID` | `—` | `—` | `runtime_lineage` |
| 4 | `InstrumentID` | `—` | `—` | `runtime_lineage` |
| 5 | `InstrumentDisplayName` | `—` | `—` | `runtime_lineage` |
| 6 | `InstrumentName` | `—` | `—` | `runtime_lineage` |
| 7 | `ISIN` | `—` | `—` | `runtime_lineage` |
| 8 | `Symbol` | `—` | `—` | `runtime_lineage` |
| 9 | `CUSIP` | `—` | `—` | `runtime_lineage` |
| 10 | `AccountID` | `—` | `—` | `runtime_lineage` |
| 11 | `Account_Name` | `—` | `—` | `runtime_lineage` |
| 12 | `BnyExchange` | `—` | `—` | `runtime_lineage` |
| 13 | `BnyLocalCurrency` | `—` | `—` | `runtime_lineage` |
| 14 | `BnyLocationCode` | `—` | `—` | `runtime_lineage` |
| 15 | `BnyCountryOfIncorporation` | `—` | `—` | `runtime_lineage` |
| 16 | `HedgeServerID` | `—` | `—` | `runtime_lineage` |
| 17 | `LiquidityAccountID` | `—` | `—` | `runtime_lineage` |
| 18 | `LiquidityAccountName` | `—` | `—` | `runtime_lineage` |
| 19 | `OpeningBalanceTotalCustody` | `—` | `—` | `runtime_lineage` |
| 20 | `ClosingBalanceTotalCustody` | `—` | `—` | `runtime_lineage` |
| 21 | `OpeningBalanceOmnibus` | `—` | `—` | `runtime_lineage` |
| 22 | `ClosingBalanceOmnibus` | `—` | `—` | `runtime_lineage` |
| 23 | `CalculatedClosingBalance` | `—` | `—` | `runtime_lineage` |
| 24 | `IsGapBalanceCalcVsOmniEOD` | `—` | `—` | `runtime_lineage` |
| 25 | `BNYOmniUnits` | `—` | `—` | `runtime_lineage` |
| 26 | `ClientUnitsEOD` | `—` | `—` | `runtime_lineage` |
| 27 | `HedgeActions` | `—` | `—` | `runtime_lineage` |
| 28 | `LendingEtoroOptIn` | `—` | `—` | `runtime_lineage` |
| 29 | `LendingEtoroOptInPrev` | `—` | `—` | `runtime_lineage` |
| 30 | `LendingBnyOptIn` | `—` | `—` | `runtime_lineage` |
| 31 | `ManualMoveOutOfOmni` | `—` | `—` | `runtime_lineage` |
| 32 | `ManualMoveInToOmni` | `—` | `—` | `runtime_lineage` |
| 33 | `ToLendingOptIn` | `—` | `—` | `runtime_lineage` |
| 34 | `FromLendingOptIn` | `—` | `—` | `runtime_lineage` |
| 35 | `LoansBNY` | `—` | `—` | `runtime_lineage` |
| 36 | `LoansEquilend` | `—` | `—` | `runtime_lineage` |
| 37 | `IsGapOmnibusEtoroVsBNY` | `—` | `—` | `runtime_lineage` |
| 38 | `IsGapLoansEquilendVsBNY` | `—` | `—` | `runtime_lineage` |
| 39 | `IsGapLendingOptInEtoroVsBNY` | `—` | `—` | `runtime_lineage` |
| 40 | `IsGapOpeningBalance` | `—` | `—` | `runtime_lineage` |
| 41 | `SpirePositionDate` | `—` | `—` | `runtime_lineage` |
| 42 | `LendingEtoroDate` | `—` | `—` | `runtime_lineage` |
| 43 | `TotalMovements` | `—` | `—` | `runtime_lineage` |
| 44 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
| 45 | `GapBalanceCalcVsOmni` | `—` | `—` | `runtime_lineage` |
| 46 | `BNYACAT` | `—` | `—` | `runtime_lineage` |
| 47 | `FromCorpAction` | `—` | `—` | `runtime_lineage` |
| 48 | `ToCorpAction` | `—` | `—` | `runtime_lineage` |
| 49 | `FromACAT` | `—` | `—` | `runtime_lineage` |
| 50 | `ToACAT` | `—` | `—` | `runtime_lineage` |
| 51 | `etr_y` | `—` | `—` | `runtime_lineage` |
| 52 | `etr_ym` | `—` | `—` | `runtime_lineage` |
| 53 | `etr_ymd` | `—` | `—` | `runtime_lineage` |
