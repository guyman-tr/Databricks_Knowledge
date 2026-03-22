---
object: Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime

## ETL Chain

StatusUpdateTime (Routed-event) variant of `Dealing_Daily_Latency_ClientOrder_WithDelay`. Same source chain, different EMS event.

```
DWH_dbo.Dim_Position + Dim_Instrument + Dim_Customer + Dim_Regulation
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders (Routed events only)
DWH_dbo.Dim_HistorySplitRatio
  → SP_Latency_Report_StatusUpdateTime (@Date)
    → Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

Same as `Dealing_Daily_Latency_ClientOrder_WithDelay` with these differences:
- `StatusUpdateTime`: replaces `ExecutionTime` — "Routed" EMS event (LP routing acknowledgment)
- `ClientToExecutionLatency`: DATEDIFF(ms, RequestOccurred, StatusUpdateTime) — routing latency, not fill
- `TradingToExecutionLatency`: DATEDIFF(ms, RequestTimeFromEMS, StatusUpdateTime) — EMS-to-routing
- No `RoutedTime`, `ClientToRoutedLatency`, `HedgeServerID` columns (those were added Oct 2024 to main table only)

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ 3-month window only (Jul–Oct 2024). SP_Latency_Report_StatusUpdateTime not scheduled.
