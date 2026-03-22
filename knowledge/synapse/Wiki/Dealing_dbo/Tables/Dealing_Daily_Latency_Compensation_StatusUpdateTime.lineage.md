---
object: Dealing_dbo.Dealing_Daily_Latency_Compensation_StatusUpdateTime
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Daily_Latency_Compensation_StatusUpdateTime

## ETL Chain

```
DWH_dbo.Dim_Position + Dim_Instrument + Dim_Customer + Dim_Regulation
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders (Routed events)
DWH_dbo.Dim_HistorySplitRatio
Kusto / CopyFromLake reference rates (Kusto_Rate, KustoTime)
  → SP_Latency_Report_StatusUpdateTime (@Date)
    → Dealing_dbo.Dealing_Daily_Latency_Compensation_StatusUpdateTime
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

| Column | Source |
|--------|--------|
| Date | SP parameter @Date |
| Regulation | DWH_dbo.Dim_Regulation |
| HedgingType | SP logic (#HedgingType_Routed temp table) |
| PositionID | DWH_dbo.Dim_Position |
| InstrumentID | DWH_dbo.Dim_Position |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument |
| IsBuy | DWH_dbo.Dim_Position |
| AmountInUnitsDecimal | DWH_dbo.Dim_Position + DWH_dbo.Dim_HistorySplitRatio |
| ForexRate | DWH_dbo.Dim_Position + DWH_dbo.Dim_HistorySplitRatio |
| Occurred | DWH_dbo.Dim_Position |
| ActionName | SP logic (Open/Close classification) |
| ConversionRate | DWH_dbo.Dim_Position |
| eToroTime | DWH_dbo.Dim_Position |
| LiquidityAccountID | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders |
| Price_Requested | DWH_dbo.Dim_Position |
| Spread | SP logic |
| KustoTime | Kusto / CopyFromLake reference |
| Kusto_Rate | Kusto / CopyFromLake reference |
| SlippageInDollar | Computed: (Kusto_Rate − Price_Requested) × AmountInUnitsDecimal × ConversionRate |
| UpdateDate | GETDATE() at SP execution time |
| RequestOccurred | DWH_dbo.Dim_Position |
| StatusUpdateTime | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders (Routed event) |
| RequestTimeFromEMS | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders |
| ExecutionID | DWH_dbo.Dim_Position |
| CID | DWH_dbo.Dim_Position |
| IsSettled | DWH_dbo.Dim_Position |
| PnLVersion | DWH_dbo.Dim_Position |
| OrderID | DWH_dbo.Dim_Position (ExitOrderID or OrderID) |
| ClientToDbLatency | DATEDIFF(ms, RequestOccurred, Occurred), floored at 0 |
| ClientToExecutionLatency | DATEDIFF(ms, RequestOccurred, StatusUpdateTime), floored at 0 |
| TradingToExecutionLatency | DATEDIFF(ms, RequestTimeFromEMS, StatusUpdateTime), floored at 0 |
| OpenMarketTime | SP logic / market calendar |
| WithinFirst5Minutes_MarketHours | Computed: Occurred < DATEADD(minute, 5, OpenMarketTime) |
| WithinFirst7Minutes_MarketHours | Computed: Occurred < DATEADD(minute, 7, OpenMarketTime) |

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ 3-month window only (Jul–Oct 2024). Not actively refreshed.
