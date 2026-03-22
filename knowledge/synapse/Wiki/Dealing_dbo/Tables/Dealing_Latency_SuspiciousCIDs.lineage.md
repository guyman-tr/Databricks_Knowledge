---
object: Dealing_dbo.Dealing_Latency_SuspiciousCIDs
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Latency_SuspiciousCIDs

## ETL Chain

```
Dealing_dbo.Dealing_OccurredAtProvider_Latency_Instrument
  (instruments with ≥3s price feed latency on @Date)
DWH_dbo.Dim_Position
  (positions on those instruments with Duration ≤ 600s)
  → SP_Latency_SuspiciousCIDs (@Date)
    → Dealing_dbo.Dealing_Latency_SuspiciousCIDs  (main store)
    → Dealing_dbo.Dealing_Latency_SuspiciousCIDs_Email  (rolling email alert table)
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

| Column | Source |
|--------|--------|
| Date | Dealing_OccurredAtProvider_Latency_Instrument.Date |
| CID | DWH_dbo.Dim_Position |
| PositionID | DWH_dbo.Dim_Position |
| InstrumentID | DWH_dbo.Dim_Position (filtered to instruments in OccurredAtProvider) |
| HedgeServerID | DWH_dbo.Dim_Position |
| InitDateTime | DWH_dbo.Dim_Position |
| EndDateTime | DWH_dbo.Dim_Position |
| NetProfit | DWH_dbo.Dim_Position |
| Duration | DATEDIFF(ss, InitDateTime, EndDateTime); filter ≤ 600 |
| UpdateDate | GETDATE() at SP execution time |

## Refresh

- **OpsDB tracked**: ✅ Yes — Priority 0, SB_Daily
- **Pipeline status**: ✅ ACTIVE (2026-03-10)
- **Note**: OccurredAtProvider source tables are stale since 2025-01-11 — cross-reference data may be outdated
