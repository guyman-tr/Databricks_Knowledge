# Column Lineage: main.bi_dealing.bi_output_dealing_daily_bmll_slippage_latency_compensation

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_daily_bmll_slippage_latency_compensation` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_dealing_daily_bmll_slippage_latency_compensation.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `trade_id` | `—` | `—` | `runtime_lineage` |
| 2 | `Date` | `—` | `—` | `runtime_lineage` |
| 3 | `Regulation` | `—` | `—` | `runtime_lineage` |
| 4 | `PositionID` | `—` | `—` | `runtime_lineage` |
| 5 | `CID` | `—` | `—` | `runtime_lineage` |
| 6 | `GCID` | `—` | `—` | `runtime_lineage` |
| 7 | `InstrumentID` | `—` | `—` | `runtime_lineage` |
| 8 | `InstrumentDisplayName` | `—` | `—` | `runtime_lineage` |
| 9 | `InstrumentTypeID` | `—` | `—` | `runtime_lineage` |
| 10 | `InstrumentType` | `—` | `—` | `runtime_lineage` |
| 11 | `HedgeServerID` | `—` | `—` | `runtime_lineage` |
| 12 | `IsBuy` | `—` | `—` | `runtime_lineage` |
| 13 | `Units` | `—` | `—` | `runtime_lineage` |
| 14 | `ForexRate` | `—` | `—` | `runtime_lineage` |
| 15 | `Occurred` | `—` | `—` | `runtime_lineage` |
| 16 | `ExecutionID` | `—` | `—` | `runtime_lineage` |
| 17 | `ActionType` | `—` | `—` | `runtime_lineage` |
| 18 | `IsTriggeredPosition` | `—` | `—` | `runtime_lineage` |
| 19 | `IsOpen` | `—` | `—` | `runtime_lineage` |
| 20 | `RequestOccurred` | `—` | `—` | `runtime_lineage` |
| 21 | `HedgingType` | `—` | `—` | `runtime_lineage` |
| 22 | `ExecutionTime` | `—` | `—` | `runtime_lineage` |
| 23 | `RequestTime` | `—` | `—` | `runtime_lineage` |
| 24 | `IsSettled` | `—` | `—` | `runtime_lineage` |
| 25 | `OrderID` | `—` | `—` | `runtime_lineage` |
| 26 | `RoutedTime` | `—` | `—` | `runtime_lineage` |
| 27 | `Volume` | `—` | `—` | `runtime_lineage` |
| 28 | `ConversionRate` | `—` | `—` | `runtime_lineage` |
| 29 | `ClientToDbLatency` | `—` | `—` | `runtime_lineage` |
| 30 | `ClientToExecutionLatency` | `—` | `—` | `runtime_lineage` |
| 31 | `TradingToExecutionLatency` | `—` | `—` | `runtime_lineage` |
| 32 | `ClientToRoutedLatency` | `—` | `—` | `runtime_lineage` |
| 33 | `OpenTimeUTC` | `—` | `—` | `runtime_lineage` |
| 34 | `WithinFirst5Minutes_MarketHours` | `—` | `—` | `runtime_lineage` |
| 35 | `WithinFirst7Minutes_MarketHours` | `—` | `—` | `runtime_lineage` |
| 36 | `Markup` | `—` | `—` | `runtime_lineage` |
| 37 | `MarketReceivedTime` | `—` | `—` | `runtime_lineage` |
| 38 | `LiquidityAccountID` | `—` | `—` | `runtime_lineage` |
| 39 | `Bid` | `—` | `—` | `runtime_lineage` |
| 40 | `Ask` | `—` | `—` | `runtime_lineage` |
| 41 | `PriceExistsFlag` | `—` | `—` | `runtime_lineage` |
| 42 | `History_Price_Rate` | `—` | `—` | `runtime_lineage` |
| 43 | `SlippageInDollar` | `—` | `—` | `runtime_lineage` |
| 44 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
| 45 | `ListingId` | `—` | `—` | `runtime_lineage` |
| 46 | `bid_stf` | `—` | `—` | `runtime_lineage` |
| 47 | `ask_stf` | `—` | `—` | `runtime_lineage` |
| 48 | `bid_tob` | `—` | `—` | `runtime_lineage` |
| 49 | `ask_tob` | `—` | `—` | `runtime_lineage` |
| 50 | `ReportDateID` | `—` | `—` | `runtime_lineage` |
| 51 | `etr_y` | `—` | `—` | `runtime_lineage` |
| 52 | `etr_ym` | `—` | `—` | `runtime_lineage` |
| 53 | `etr_ymd` | `—` | `—` | `runtime_lineage` |
| 54 | `BMLL_stf_Rate` | `—` | `—` | `runtime_lineage` |
| 55 | `BMLL_tob_Rate` | `—` | `—` | `runtime_lineage` |
| 56 | `SlippageInDollar_bmll_stf` | `—` | `—` | `runtime_lineage` |
| 57 | `SlippageInDollar_bmll_tob` | `—` | `—` | `runtime_lineage` |
