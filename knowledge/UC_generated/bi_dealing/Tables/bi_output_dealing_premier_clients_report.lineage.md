# Column Lineage: main.bi_dealing.bi_output_dealing_premier_clients_report

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_premier_clients_report` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_dealing_premier_clients_report.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `Date` | `—` | `—` | `runtime_lineage` |
| 2 | `PositionID` | `—` | `—` | `runtime_lineage` |
| 3 | `OriginalPositionID` | `—` | `—` | `runtime_lineage` |
| 4 | `InitExecutionID` | `—` | `—` | `runtime_lineage` |
| 5 | `EndExecutionID` | `—` | `—` | `runtime_lineage` |
| 6 | `InitHedgingType` | `—` | `—` | `runtime_lineage` |
| 7 | `EndHedgingType` | `—` | `—` | `runtime_lineage` |
| 8 | `CID` | `—` | `—` | `runtime_lineage` |
| 9 | `AccountManagerID` | `—` | `—` | `runtime_lineage` |
| 10 | `AccountManager` | `—` | `—` | `runtime_lineage` |
| 11 | `CountryID` | `—` | `—` | `runtime_lineage` |
| 12 | `Country_Name` | `—` | `—` | `runtime_lineage` |
| 13 | `Region` | `—` | `—` | `runtime_lineage` |
| 14 | `PlayerLevelID` | `—` | `—` | `runtime_lineage` |
| 15 | `Club` | `—` | `—` | `runtime_lineage` |
| 16 | `GuruStatusName` | `—` | `—` | `runtime_lineage` |
| 17 | `ClientCategory` | `—` | `—` | `runtime_lineage` |
| 18 | `InstrumentID` | `—` | `—` | `runtime_lineage` |
| 19 | `InstrumentType` | `—` | `—` | `runtime_lineage` |
| 20 | `Exchange` | `—` | `—` | `runtime_lineage` |
| 21 | `IsChild` | `—` | `—` | `runtime_lineage` |
| 22 | `IsParent` | `—` | `—` | `runtime_lineage` |
| 23 | `Symbol` | `—` | `—` | `runtime_lineage` |
| 24 | `HedgeServerID` | `—` | `—` | `runtime_lineage` |
| 25 | `Amount` | `—` | `—` | `runtime_lineage` |
| 26 | `Units` | `—` | `—` | `runtime_lineage` |
| 27 | `Initial_InvestedAmount` | `—` | `—` | `runtime_lineage` |
| 28 | `MirrorID` | `—` | `—` | `runtime_lineage` |
| 29 | `ClosePositionReasonID` | `—` | `—` | `runtime_lineage` |
| 30 | `ClosePositionReasonName` | `—` | `—` | `runtime_lineage` |
| 31 | `Duration_seconds` | `—` | `—` | `runtime_lineage` |
| 32 | `Duration_minutes` | `—` | `—` | `runtime_lineage` |
| 33 | `Duration` | `—` | `—` | `runtime_lineage` |
| 34 | `Leverage` | `—` | `—` | `runtime_lineage` |
| 35 | `Direction` | `—` | `—` | `runtime_lineage` |
| 36 | `IsMirror` | `—` | `—` | `runtime_lineage` |
| 37 | `ReaL_CFD` | `—` | `—` | `runtime_lineage` |
| 38 | `Total_daily_Volume` | `—` | `—` | `runtime_lineage` |
| 39 | `Volume` | `—` | `—` | `runtime_lineage` |
| 40 | `VolumeOnClose` | `—` | `—` | `runtime_lineage` |
| 41 | `Total_daily_clicks` | `—` | `—` | `runtime_lineage` |
| 42 | `Total_Daily_Commission` | `—` | `—` | `runtime_lineage` |
| 43 | `NetProfit` | `—` | `—` | `runtime_lineage` |
| 44 | `PositionPnL` | `—` | `—` | `runtime_lineage` |
| 45 | `previous_Position_PnL` | `—` | `—` | `runtime_lineage` |
| 46 | `NOP` | `—` | `—` | `runtime_lineage` |
| 47 | `DailyPnL` | `—` | `—` | `runtime_lineage` |
| 48 | `OpenOccurred` | `—` | `—` | `runtime_lineage` |
| 49 | `CloseOccurred` | `—` | `—` | `runtime_lineage` |
| 50 | `OpenDateID` | `—` | `—` | `runtime_lineage` |
| 51 | `CloseDateID` | `—` | `—` | `runtime_lineage` |
| 52 | `InitForexRate` | `—` | `—` | `runtime_lineage` |
| 53 | `EndForexRate` | `—` | `—` | `runtime_lineage` |
| 54 | `Price` | `—` | `—` | `runtime_lineage` |
| 55 | `Change_Price` | `—` | `—` | `runtime_lineage` |
| 56 | `RateBid` | `—` | `—` | `runtime_lineage` |
| 57 | `RateAsk` | `—` | `—` | `runtime_lineage` |
| 58 | `Previous_Price` | `—` | `—` | `runtime_lineage` |
| 59 | `Previous_Change_Price` | `—` | `—` | `runtime_lineage` |
| 60 | `Previous_Amount` | `—` | `—` | `runtime_lineage` |
| 61 | `Previous_Units` | `—` | `—` | `runtime_lineage` |
| 62 | `Previous_DailyPnL` | `—` | `—` | `runtime_lineage` |
| 63 | `PreviousBid` | `—` | `—` | `runtime_lineage` |
| 64 | `PreviousAsk` | `—` | `—` | `runtime_lineage` |
| 65 | `ConversionRate` | `—` | `—` | `runtime_lineage` |
| 66 | `StopRate` | `—` | `—` | `runtime_lineage` |
| 67 | `OverNightFee` | `—` | `—` | `runtime_lineage` |
| 68 | `TicketFees` | `—` | `—` | `runtime_lineage` |
| 69 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
| 70 | `IsPro` | `—` | `—` | `runtime_lineage` |
| 71 | `IsPremier` | `—` | `—` | `runtime_lineage` |
