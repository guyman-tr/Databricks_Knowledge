# Column Lineage: main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-06-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `LedgerClosingDate` | `—` | `—` | `runtime_lineage` |
| 2 | `LedgerOpeningDate` | `—` | `—` | `runtime_lineage` |
| 3 | `OptInClosingDate` | `—` | `—` | `runtime_lineage` |
| 4 | `OptInOpeningDate` | `—` | `—` | `runtime_lineage` |
| 5 | `LoansClosingDate` | `—` | `—` | `runtime_lineage` |
| 6 | `LoansOpeningDate` | `—` | `—` | `runtime_lineage` |
| 7 | `AS` | `—` | `—` | `runtime_lineage` |
| 8 | `CID` | `—` | `—` | `runtime_lineage` |
| 9 | `EquilendID` | `—` | `—` | `runtime_lineage` |
| 10 | `IsValidCustomer` | `—` | `—` | `runtime_lineage` |
| 11 | `IsCreditReportValidCB` | `—` | `—` | `runtime_lineage` |
| 12 | `InstrumentID` | `—` | `—` | `runtime_lineage` |
| 13 | `InstrumentName` | `—` | `—` | `runtime_lineage` |
| 14 | `InstrumentDisplayName` | `—` | `—` | `runtime_lineage` |
| 15 | `ISIN` | `—` | `—` | `runtime_lineage` |
| 16 | `Symbol` | `—` | `—` | `runtime_lineage` |
| 17 | `CUSIP` | `—` | `—` | `runtime_lineage` |
| 18 | `Currency` | `—` | `—` | `runtime_lineage` |
| 19 | `HedgeServerID` | `—` | `—` | `runtime_lineage` |
| 20 | `OpeningBalanceTotalCustodyUnits` | `—` | `—` | `runtime_lineage` |
| 21 | `ClosingBalanceTotalCustodyUnits` | `—` | `—` | `runtime_lineage` |
| 22 | `OpeningNonFCA` | `—` | `—` | `runtime_lineage` |
| 23 | `ClosingNonFCA` | `—` | `—` | `runtime_lineage` |
| 24 | `OpeningBalanceOmniUnits` | `—` | `—` | `runtime_lineage` |
| 25 | `ClosingBalanceOmniUnits` | `—` | `—` | `runtime_lineage` |
| 26 | `LendingTotalOpeningBalanceUnits` | `—` | `—` | `runtime_lineage` |
| 27 | `LendingTotalClosingBalanceUnits` | `—` | `—` | `runtime_lineage` |
| 28 | `LendingAvailiableOpeningUnits` | `—` | `—` | `runtime_lineage` |
| 29 | `LendingAvailiableClosingUnits` | `—` | `—` | `runtime_lineage` |
| 30 | `CustodyOut` | `—` | `—` | `runtime_lineage` |
| 31 | `CustodyIn` | `—` | `—` | `runtime_lineage` |
| 32 | `CustodyNetMove` | `—` | `—` | `runtime_lineage` |
| 33 | `CustodyOutAdjusted` | `—` | `—` | `runtime_lineage` |
| 34 | `CustodyInAdjusted` | `—` | `—` | `runtime_lineage` |
| 35 | `CustodyNetMoveAdjusted` | `—` | `—` | `runtime_lineage` |
| 36 | `CustodyBalanceDelta` | `—` | `—` | `runtime_lineage` |
| 37 | `IsGapBalance` | `—` | `—` | `runtime_lineage` |
| 38 | `PriceEstimated` | `—` | `—` | `runtime_lineage` |
| 39 | `IsZeroPrice` | `—` | `—` | `runtime_lineage` |
| 40 | `LendingNetMove` | `—` | `—` | `runtime_lineage` |
| 41 | `LendingOut` | `—` | `—` | `runtime_lineage` |
| 42 | `LendingIn` | `—` | `—` | `runtime_lineage` |
| 43 | `LoanCurrency` | `—` | `—` | `runtime_lineage` |
| 44 | `LoanUnits` | `—` | `—` | `runtime_lineage` |
| 45 | `LoansUnitsPrev` | `—` | `—` | `runtime_lineage` |
| 46 | `OpeningBalanceTotalCustodyUSD` | `—` | `—` | `runtime_lineage` |
| 47 | `ClosingBalanceTotalCustodyUSD` | `—` | `—` | `runtime_lineage` |
| 48 | `OpeningBalanceOmniUSD` | `—` | `—` | `runtime_lineage` |
| 49 | `ClosingBalanceOmniUSD` | `—` | `—` | `runtime_lineage` |
| 50 | `LendingTotalOpeningBalanceUSD` | `—` | `—` | `runtime_lineage` |
| 51 | `LendingTotalClosingBalanceUSD` | `—` | `—` | `runtime_lineage` |
| 52 | `LendingAvailiableOpeningUSD` | `—` | `—` | `runtime_lineage` |
| 53 | `LendingAvailiableClosingUSD` | `—` | `—` | `runtime_lineage` |
| 54 | `LoansUSD` | `—` | `—` | `runtime_lineage` |
| 55 | `IsMissingOpening` | `—` | `—` | `runtime_lineage` |
| 56 | `IsMissingClosing` | `—` | `—` | `runtime_lineage` |
| 57 | `NOP` | `—` | `—` | `runtime_lineage` |
| 58 | `UnitsWithSplitRatioClosing` | `—` | `—` | `runtime_lineage` |
| 59 | `PriceRatioClosing` | `—` | `—` | `runtime_lineage` |
| 60 | `UnitsWithSplitRatioOpening` | `—` | `—` | `runtime_lineage` |
| 61 | `PriceRatioOpening` | `—` | `—` | `runtime_lineage` |
| 62 | `ActivityAmountRatio` | `—` | `—` | `runtime_lineage` |
| 63 | `ActivityPriceRatio` | `—` | `—` | `runtime_lineage` |
| 64 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
| 65 | `IsRatio` | `—` | `—` | `runtime_lineage` |
| 66 | `etr_y` | `—` | `—` | `runtime_lineage` |
| 67 | `etr_ym` | `—` | `—` | `runtime_lineage` |
| 68 | `etr_ymd` | `—` | `—` | `runtime_lineage` |
| 69 | `ID` | `—` | `—` | `runtime_lineage` |
