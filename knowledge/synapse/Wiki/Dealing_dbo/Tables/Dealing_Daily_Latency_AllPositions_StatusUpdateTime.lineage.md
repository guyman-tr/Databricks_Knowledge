---
object: Dealing_dbo.Dealing_Daily_Latency_AllPositions_StatusUpdateTime
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Daily_Latency_AllPositions_StatusUpdateTime

## ETL Chain

```
DWH_dbo.Dim_Position + Dim_Instrument + Dim_Customer + Dim_Regulation
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders (Routed events — StatusUpdateTime)
DWH_dbo.Dim_HistorySplitRatio
  → SP_Latency_Report_StatusUpdateTime (@Date)
    → Dealing_dbo.Dealing_Daily_Latency_AllPositions_StatusUpdateTime
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

Same as Dealing_Daily_Latency_AllPositions except:
- `StatusUpdateTime` replaces `ExecutionTime` — source: `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.StatusUpdateTime` (Routed status)
- `ClientToExecutionLatency` = `DATEDIFF(ms, RequestOccurred, StatusUpdateTime)` (not Filled)
- `TradingToExecutionLatency` = `DATEDIFF(ms, RequestTimeFromEMS, StatusUpdateTime)` (not Filled)

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ STALE since 2024-10-07 (3 months of data only)
