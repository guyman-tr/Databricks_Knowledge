---
object: Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Daily_Latency_ClientOrder_WithDelay

## ETL Chain

Same source chain as `Dealing_Daily_Latency_AllPositions` — filtered subset focused on delayed client order executions.

```
DWH_dbo.Dim_Position + Dim_Instrument + Dim_Customer + Dim_Regulation
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders (Filled + Routed events)
DWH_dbo.Dim_HistorySplitRatio
  → SP_Latency_Report (@Date)
    → Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

Same as Dealing_Daily_Latency_AllPositions with these differences:
- `IsSettled`: int type (vs tinyint)
- `PnLVersion`: from `DWH_dbo.Dim_Position.PnLVersion`
- `OrderID`: from `DWH_dbo.Dim_Position.ExitOrderID` (closes) or `OrderID` (opens)
- Precision differences: AmountInUnitsDecimal (16,6), ForexRate (16,6)

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ STALE since 2025-01-11
