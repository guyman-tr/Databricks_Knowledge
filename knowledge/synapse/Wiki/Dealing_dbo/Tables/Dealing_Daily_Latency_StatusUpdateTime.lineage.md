---
object: Dealing_dbo.Dealing_Daily_Latency_StatusUpdateTime
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Daily_Latency_StatusUpdateTime

## ETL Chain

```
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders (LP routing events — "Routed" status)
DWH_dbo.Dim_Position, Dim_Instrument, Dim_Customer, Fact_SnapshotCustomer, Dim_Regulation
  → SP_Latency_Report_StatusUpdateTime (@Date)
    → Dealing_dbo.Dealing_Daily_Latency_StatusUpdateTime
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics table.

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | SP parameter | @Date | passthrough |
| HedgingType | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | HedgeExecutionModeID | CASE: 1→'HBC', else→'CBH' |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough |
| ActionName | Dim_Position + Dim_ClosePositionReason | ClosePositionReasonID, OrderType | CASE logic |
| No of Trades | Dim_Position | PositionID | COUNT(*) aggregate |
| Avg Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, StatusUpdateTime) | AVG aggregate, floored at 0 |
| Max Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, StatusUpdateTime) | MAX aggregate |
| Sum Latency (millisec) | computed | DATEDIFF(ms, RequestOccurred, StatusUpdateTime) | SUM aggregate |
| UpdateDate | ETL | GETDATE() | inserted at write time |
| Over1Sec | computed | ClientToRoutedLatency > 1000 | COUNT aggregate |
| Regulation | DWH_dbo.Dim_Regulation | Name | via Fact_SnapshotCustomer |

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ STALE since 2024-10-07 — only 3 months of data
