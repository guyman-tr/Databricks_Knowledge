---
object: Dealing_dbo.Dealing_Daily_Latency_AllPositions
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Daily_Latency_AllPositions

## ETL Chain

```
DWH_dbo.Dim_Position (PositionID, CID, InstrumentID, timestamps, ForexRate, IsSettled, HedgeServerID)
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders (ExecutionTime, StatusUpdateTime, HedgeExecutionModeID)
DWH_dbo.Dim_Instrument (InstrumentDisplayName, InstrumentType)
DWH_dbo.Dim_Customer (IsValidCustomer)
DWH_dbo.Fact_SnapshotCustomer + Dim_Regulation (Regulation)
DWH_dbo.Dim_HistorySplitRatio (split-adjusted amounts/prices)
CopyFromLake.etoro_DWH_HistoryOrderForClose/Open (OrderType classification)
  → SP_Latency_Report (@Date)
    → Dealing_dbo.Dealing_Daily_Latency_AllPositions (position-level latency detail)
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | SP parameter | @Date | passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | via Fact_SnapshotCustomer |
| HedgingType | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | HedgeExecutionModeID | CASE ISNULL(Filled, Routed) |
| PositionID | DWH_dbo.Dim_Position | PositionID | passthrough |
| CID | DWH_dbo.Dim_Position | CID | passthrough |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | passthrough |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | passthrough |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | passthrough |
| AmountInUnitsDecimal | DWH_dbo.Dim_Position | AmountInUnitsDecimal | * COALESCE(SplitRatio.AmountRatio, 1) |
| ForexRate | DWH_dbo.Dim_Position | InitForexRate / EndForexRate | * COALESCE(SplitRatio.PriceRatio, 1) |
| Occurred | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | passthrough |
| ActionName | Dim_ClosePositionReason, Dim_Position | ClosePositionReasonID, OrderType | CASE logic |
| ConversionRate | DWH_dbo.Dim_Position | ConversionRate | passthrough |
| UpdateDate | ETL | GETDATE() | at write time |
| RequestOccurred | DWH_dbo.Dim_Position | RequestOpenOccurred / RequestCloseOccurred | passthrough |
| ExecutionID | DWH_dbo.Dim_Position | InitExecutionID / EndExecutionID | passthrough |
| ExecutionTime | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | ExecutionTime | passthrough (Filled events) |
| RequestTimeFromEMS | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | RequestTime | passthrough |
| ClientToDbLatency | computed | DATEDIFF(ms, RequestOccurred, Occurred) | floored at 0 |
| ClientToExecutionLatency | computed | DATEDIFF(ms, RequestOccurred, ExecutionTime) | floored at 0 |
| TradingToExecutionLatency | computed | DATEDIFF(ms, RequestTimeFromEMS, ExecutionTime) | floored at 0 |
| RoutedTime | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | StatusUpdateTime | passthrough (Routed events) |
| ClientToRoutedLatency | computed | DATEDIFF(ms, RequestOccurred, RoutedTime) | floored at 0 |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | passthrough |

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ STALE since 2025-01-11
