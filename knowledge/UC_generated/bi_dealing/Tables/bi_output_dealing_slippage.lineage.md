# Column Lineage: main.bi_dealing.bi_output_dealing_slippage

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_slippage` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_dealing_slippage.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `Date` | `—` | `—` | `runtime_lineage` |
| 2 | `ExecutionID` | `—` | `—` | `runtime_lineage` |
| 3 | `PositionID` | `—` | `—` | `runtime_lineage` |
| 4 | `InstrumentID` | `—` | `—` | `runtime_lineage` |
| 5 | `HedgeServerID` | `—` | `—` | `runtime_lineage` |
| 6 | `InstrumentTypeID` | `—` | `—` | `runtime_lineage` |
| 7 | `InstrumentType` | `—` | `—` | `runtime_lineage` |
| 8 | `Exchange` | `—` | `—` | `runtime_lineage` |
| 9 | `Symbol` | `—` | `—` | `runtime_lineage` |
| 10 | `SellCurrency` | `—` | `—` | `runtime_lineage` |
| 11 | `S_LiquidityAccountID` | `—` | `—` | `runtime_lineage` |
| 12 | `G_Orders_ExecutionTime` | `—` | `—` | `runtime_lineage` |
| 13 | `G_OMS_ExecutionTime` | `—` | `—` | `runtime_lineage` |
| 14 | `S_CurrencyPrice_OccurredAtServer` | `—` | `—` | `runtime_lineage` |
| 15 | `S_CurrencyPrice_StartTime` | `—` | `—` | `runtime_lineage` |
| 16 | `G_LEG` | `—` | `—` | `runtime_lineage` |
| 17 | `S_LEG` | `—` | `—` | `runtime_lineage` |
| 18 | `G_IsBuy` | `—` | `—` | `runtime_lineage` |
| 19 | `S_IsBuy` | `—` | `—` | `runtime_lineage` |
| 20 | `ExecutionUnits` | `—` | `—` | `runtime_lineage` |
| 21 | `PositionUnits` | `—` | `—` | `runtime_lineage` |
| 22 | `G_ExecutionRate` | `—` | `—` | `runtime_lineage` |
| 23 | `S_ExecutionRate` | `—` | `—` | `runtime_lineage` |
| 24 | `G_ExecutionRateUSD` | `—` | `—` | `runtime_lineage` |
| 25 | `S_ExecutionRateUSD` | `—` | `—` | `runtime_lineage` |
| 26 | `G_OMS_IMPricingRate` | `—` | `—` | `runtime_lineage` |
| 27 | `G_OMS_IMPricingRateUSD` | `—` | `—` | `runtime_lineage` |
| 28 | `S_Bid` | `—` | `—` | `runtime_lineage` |
| 29 | `S_Ask` | `—` | `—` | `runtime_lineage` |
| 30 | `S_BidUSD` | `—` | `—` | `runtime_lineage` |
| 31 | `S_AskUSD` | `—` | `—` | `runtime_lineage` |
| 32 | `G_CustomerRate` | `—` | `—` | `runtime_lineage` |
| 33 | `S_CustomerRate` | `—` | `—` | `runtime_lineage` |
| 34 | `G_CustomerRateUSD` | `—` | `—` | `runtime_lineage` |
| 35 | `S_CustomerRateUSD` | `—` | `—` | `runtime_lineage` |
| 36 | `G_Slippage_OMSPrice` | `—` | `—` | `runtime_lineage` |
| 37 | `G_Slippage_OMSPriceUSD` | `—` | `—` | `runtime_lineage` |
| 38 | `S_Slippage_1PriceUSD` | `—` | `—` | `runtime_lineage` |
| 39 | `G_Slippage_1` | `—` | `—` | `runtime_lineage` |
| 40 | `S_Slippage_1USD` | `—` | `—` | `runtime_lineage` |
| 41 | `G_Slippage_1USD` | `—` | `—` | `runtime_lineage` |
| 42 | `Volume` | `—` | `—` | `runtime_lineage` |
| 43 | `FullCommission` | `—` | `—` | `runtime_lineage` |
| 44 | `G_Ranking` | `—` | `—` | `runtime_lineage` |
| 45 | `G_Ranking2` | `—` | `—` | `runtime_lineage` |
| 46 | `G_MaxRanking` | `—` | `—` | `runtime_lineage` |
| 47 | `G_MaxRanking2` | `—` | `—` | `runtime_lineage` |
| 48 | `Size_Of_Ticket` | `—` | `—` | `runtime_lineage` |
| 49 | `CID` | `—` | `—` | `runtime_lineage` |
| 50 | `MirrorID` | `—` | `—` | `runtime_lineage` |
| 51 | `CountryID` | `—` | `—` | `runtime_lineage` |
| 52 | `Country_Name` | `—` | `—` | `runtime_lineage` |
| 53 | `Region` | `—` | `—` | `runtime_lineage` |
| 54 | `PlayerLevelID` | `—` | `—` | `runtime_lineage` |
| 55 | `Club` | `—` | `—` | `runtime_lineage` |
| 56 | `GuruStatusName` | `—` | `—` | `runtime_lineage` |
| 57 | `Regulation` | `—` | `—` | `runtime_lineage` |
| 58 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
| 59 | `G_OMS_IMPricingRate2` | `—` | `—` | `runtime_lineage` |
| 60 | `G_OMS_IMPricingRateUSD2` | `—` | `—` | `runtime_lineage` |
| 61 | `G_RankingDESC` | `—` | `—` | `runtime_lineage` |
| 62 | `IsSlipped` | `—` | `—` | `runtime_lineage` |
| 63 | `HedgeExecutionModeID` | `—` | `—` | `runtime_lineage` |
| 64 | `ExecutionPriceRateID` | `—` | `—` | `runtime_lineage` |
| 65 | `AccountManagerID` | `—` | `—` | `runtime_lineage` |
| 66 | `AccountManager` | `—` | `—` | `runtime_lineage` |
| 67 | `ClosePositionReasonID` | `—` | `—` | `runtime_lineage` |
| 68 | `G_Order_CustomerRate` | `—` | `—` | `runtime_lineage` |
| 69 | `G_Order_CustomerRateUSD` | `—` | `—` | `runtime_lineage` |
| 70 | `EventPayloadRowData_Orderstate` | `—` | `—` | `runtime_lineage` |
| 71 | `IsValidCustomerRate` | `—` | `—` | `runtime_lineage` |
| 72 | `Y_LiquidityAccountID` | `—` | `—` | `runtime_lineage` |
| 73 | `Y_Occurred` | `—` | `—` | `runtime_lineage` |
| 74 | `Y_Bid` | `—` | `—` | `runtime_lineage` |
| 75 | `Y_Ask` | `—` | `—` | `runtime_lineage` |
| 76 | `Y_BidSpreaded` | `—` | `—` | `runtime_lineage` |
| 77 | `Y_AskSpreaded` | `—` | `—` | `runtime_lineage` |
| 78 | `Y_LEG` | `—` | `—` | `runtime_lineage` |
| 79 | `Y_IsBuy` | `—` | `—` | `runtime_lineage` |
| 80 | `IsCFD` | `—` | `—` | `runtime_lineage` |
| 81 | `Y_ExecutionRate` | `—` | `—` | `runtime_lineage` |
| 82 | `Y_ExecutionRateUSD` | `—` | `—` | `runtime_lineage` |
| 83 | `Y_CustomerRate` | `—` | `—` | `runtime_lineage` |
| 84 | `Y_CustomerRateUSD` | `—` | `—` | `runtime_lineage` |
| 85 | `G_TotalExecutionSlippage` | `—` | `—` | `runtime_lineage` |
| 86 | `G_TotalExecutionSlippageUSD` | `—` | `—` | `runtime_lineage` |
| 87 | `Y_SlippagePrice_Spreaded` | `—` | `—` | `runtime_lineage` |
| 88 | `Y_SlippagePrice_Unspreaded` | `—` | `—` | `runtime_lineage` |
| 89 | `Y_Slippage_1_Spreaded` | `—` | `—` | `runtime_lineage` |
| 90 | `Y_Slippage_1_Unspreaded` | `—` | `—` | `runtime_lineage` |
| 91 | `Y_Slippage_1_SpreadedUSD` | `—` | `—` | `runtime_lineage` |
| 92 | `Y_Slippage_1_UnspreadedUSD` | `—` | `—` | `runtime_lineage` |
| 93 | `ConversionRate_Final` | `—` | `—` | `runtime_lineage` |
