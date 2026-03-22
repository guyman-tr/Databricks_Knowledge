---
object: Dealing_dbo.Dealing_Daily_Latency
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Daily_Latency

## ETL Chain

```
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders (LP execution events)
DWH_dbo.Dim_Position (position timestamps, CID, InstrumentID)
DWH_dbo.Dim_Instrument (InstrumentType, InstrumentDisplayName)
DWH_dbo.Dim_Customer (IsValidCustomer)
DWH_dbo.Fact_SnapshotCustomer + Dim_Regulation (RegulationID → Name)
DWH_dbo.Dim_ClosePositionReason (ActionName mapping)
DWH_dbo.Dim_HistorySplitRatio (price split adjustment)
Dealing_staging.External_CalendarDB_Market_MergedDailySchedules (market hours)
  → SP_Latency_Report (@Date)
    → Dealing_dbo.Dealing_Daily_Latency (daily latency aggregates)
```

## Generic Pipeline Mapping

No entry in generic pipeline mapping — this is a DWH-computed analytics table, not a passthrough of a production SQL Server table.

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | SP parameter | @Date | passthrough |
| HedgingType | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | HedgeExecutionModeID | CASE: 1→'HBC', else→'CBH' |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough |
| ActionName | DWH_dbo.Dim_Position + DWH_dbo.Dim_ClosePositionReason | ClosePositionReasonID, OrderType | CASE logic |
| No of Trades | DWH_dbo.Dim_Position | PositionID | COUNT(*) aggregate |
| Avg Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, ExecutionTime) | AVG aggregate, floored at 0 |
| Max Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, ExecutionTime) | MAX aggregate |
| Sum Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, ExecutionTime) | SUM aggregate |
| UpdateDate | ETL | GETDATE() | inserted at write time |
| Over1Sec | computed | ClientToExecutionLatency > 1000 | COUNT of qualifying rows |
| Regulation | DWH_dbo.Dim_Regulation | Name | via Fact_SnapshotCustomer |
| WithinFirst5Minutes_MarketHours | computed | RequestOccurred vs OpenTimeUTC | CASE: BETWEEN OpenTimeUTC and +5min |
| Over1Sec_Routed | computed | ClientToRoutedLatency > 1000 | COUNT aggregate |
| Avg Routed Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, StatusUpdateTime) | AVG aggregate |
| Max Routed Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, StatusUpdateTime) | MAX aggregate |
| Sum Routed Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, StatusUpdateTime) | SUM aggregate |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | passthrough |

## Refresh

- **OpsDB tracked**: No (not in opsdb-objects-status.json)
- **Estimated frequency**: Daily (Windows Scheduler outside OpsDB)
- **Pipeline status**: ⚠️ STALE since 2025-01-11 — CopyFromLake feed disruption
