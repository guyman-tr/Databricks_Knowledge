# Column Lineage: Dealing_dbo.Dealing_Daily_Latency_Compensation

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_Latency_Report
**⚠️ Pipeline status**: POTENTIALLY DECOMMISSIONED — max date 2025-01-11

## Pipeline Summary

```
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders  ─┐ (LP EMS execution log — Async)
DWH_dbo.Dim_Position                         ─┤
Dealing_Daily_Slippage_Positions (Dealing_dbo)─┤─► SP_Latency_Report ──► Dealing_Daily_Latency_Compensation
CopyFromLake.PriceLog_History_CurrencyPrice  ─┤   (latency > 1000ms   (DELETE+INSERT by Date)
Dealing_staging.External_CalendarDB_Market_MergedDailySchedules─┘    threshold)
                                                          │
                                                          └──► Dealing_Best_Execution_Compensation_CBH/HBC
                                                               (read by SP_Best_Execution)
```

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| Date | @StartDate parameter | — | Report date |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via customer snapshot RegulationID |
| HedgingType | — | LP routing logic | 'CBH' or 'HBC' derived from EMS routing |
| PositionID | DWH_dbo.Dim_Position | PositionID | Direct join |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Direct |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct join |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | Direct |
| AmountInUnitsDecimal | DWH_dbo.Dim_Position | AmountInUnitsDecimal | Direct (split-adjusted) |
| ForexRate | DWH_dbo.Dim_Position | OpenForexRate / CloseForexRate | Open or close rate depending on action |
| Occurred | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | Action timestamp |
| ActionName | DWH_dbo.Dim_Position | ActionType | Open / Manual Close / Take Profit / Stop Loss / OpenOpen |
| ConversionRate | DWH_dbo.Dim_Position | InitForexRate / EndForexRate | FX conversion to USD |
| eToroTime | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | OccurredAtServer | eToro system timestamp |
| LiquidityAccountID | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | LiquidityAccountID | Direct from EMS |
| Price_Requested | Client request data / Dim_Position | RequestedRate | Client's submitted price |
| Spread | DWH_dbo.Dim_Position | InitForex_AskSpreaded/Bid (CBH) or CommissionByUnits (HBC) | Bid-ask spread at execution |
| KustoTime | CopyFromLake.PriceLog_History_CurrencyPrice | Occurred | LP price tick timestamp |
| Kusto_Rate | CopyFromLake.PriceLog_History_CurrencyPrice | Ask / Bid | LP price at execution time |
| SlippageInDollar | Dealing_dbo.Dealing_Daily_Slippage_Positions | SlippageInDollar | Direct from slippage table (same date) |
| UpdateDate | GETDATE() | — | Batch timestamp |
| RequestOccurred | DWH_dbo.Dim_Position | RequestOpenOccurred / RequestCloseOccurred | Client request time |
| ExecutionTime | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | ExecutionTime | LP execution timestamp |
| RequestTimeFromEMS | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | RequestTime | EMS request timestamp |
| ExecutionID | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | ExecutionID | LP order execution ID |
| CID | DWH_dbo.Dim_Position | CID | Customer ID |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | 1=Real, 0=CFD |
| PnLVersion | DWH_dbo.Dim_Position | PnLVersion | P&L version flag |
| OrderID | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | OrderID | EMS order ID |
| ClientToDbLatency | — | Computed from timestamps | Ms from request to DB entry |
| ClientToExecutionLatency | — | ExecutionTime − RequestOccurred | Ms from request to LP execution |
| TradingToExecutionLatency | — | ExecutionTime − eToroTime | Ms from trading engine to LP execution |
| OpenMarketTime | Dealing_staging.External_CalendarDB_Market_MergedDailySchedules | OpenTimeUTC | Exchange open time |
| WithinFirst5Minutes_MarketHours | — | Occurred BETWEEN OpenMarketTime AND OpenMarketTime+5min | Boolean flag |
| WithinFirst7Minutes_MarketHours | — | Occurred BETWEEN OpenMarketTime AND OpenMarketTime+7min | Boolean flag |
| RoutedTime | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | RoutedTime | Order routing timestamp |
| ClientToRoutedLatency | — | RoutedTime − RequestOccurred | Ms from request to routing |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Direct |

## ETL Pattern

- DELETE WHERE Date=@StartDate → INSERT DISTINCT
- Threshold: latency > 1000ms
- EU exchange special LP account routing (IDs 54, 127)
