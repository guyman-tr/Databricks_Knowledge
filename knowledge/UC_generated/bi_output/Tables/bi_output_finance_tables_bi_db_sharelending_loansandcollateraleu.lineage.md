# Column Lineage: main.bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-06-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `ReportDate` | `—` | `—` | `runtime_lineage` |
| 2 | `LoanCurrency` | `—` | `—` | `runtime_lineage` |
| 3 | `ISIN` | `—` | `—` | `runtime_lineage` |
| 4 | `TICKER` | `—` | `—` | `runtime_lineage` |
| 5 | `CUSIP` | `—` | `—` | `runtime_lineage` |
| 6 | `EquilendID` | `—` | `—` | `runtime_lineage` |
| 7 | `IsUK` | `—` | `—` | `runtime_lineage` |
| 8 | `RealCID` | `—` | `—` | `runtime_lineage` |
| 9 | `InstrumentID` | `—` | `—` | `runtime_lineage` |
| 10 | `CollateralPercent` | `—` | `—` | `runtime_lineage` |
| 11 | `CollateralPercentCalc` | `—` | `—` | `runtime_lineage` |
| 12 | `CollateralPriceCalc` | `—` | `—` | `runtime_lineage` |
| 13 | `LoanPriceCalc` | `—` | `—` | `runtime_lineage` |
| 14 | `LoanValueUSD` | `—` | `—` | `runtime_lineage` |
| 15 | `CollateralValueUSD` | `—` | `—` | `runtime_lineage` |
| 16 | `LoanQuantity` | `—` | `—` | `runtime_lineage` |
| 17 | `PrevBidSpreaded` | `—` | `—` | `runtime_lineage` |
| 18 | `PrevBid` | `—` | `—` | `runtime_lineage` |
| 19 | `PrevPriceDate` | `—` | `—` | `runtime_lineage` |
| 20 | `PrevDatePriceRatio` | `—` | `—` | `runtime_lineage` |
| 21 | `PrevUSD_CR_Computed` | `—` | `—` | `runtime_lineage` |
| 22 | `PrevPriceUSDeToro` | `—` | `—` | `runtime_lineage` |
| 23 | `BidSpreaded` | `—` | `—` | `runtime_lineage` |
| 24 | `Bid` | `—` | `—` | `runtime_lineage` |
| 25 | `PriceDate` | `—` | `—` | `runtime_lineage` |
| 26 | `PriceRatio` | `—` | `—` | `runtime_lineage` |
| 27 | `USD_CR_Computed` | `—` | `—` | `runtime_lineage` |
| 28 | `SellCurrencyID` | `—` | `—` | `runtime_lineage` |
| 29 | `PriceUSDeToro` | `—` | `—` | `runtime_lineage` |
| 30 | `LoanUSDByEtoroPrice` | `—` | `—` | `runtime_lineage` |
| 31 | `LoanUSDByPrevEtoroPrice` | `—` | `—` | `runtime_lineage` |
| 32 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
| 33 | `etr_y` | `—` | `—` | `runtime_lineage` |
| 34 | `etr_ym` | `—` | `—` | `runtime_lineage` |
| 35 | `etr_ymd` | `—` | `—` | `runtime_lineage` |
