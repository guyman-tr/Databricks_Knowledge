---
object: Dealing_dbo.Dealing_Daily_Latency_StatusUpdateTime
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 7.5
status: stale_pipeline
---

# Dealing_Daily_Latency_StatusUpdateTime

## 1. Purpose

Parallel daily aggregate latency table to `Dealing_Daily_Latency`, but uses **StatusUpdateTime** (the timestamp when the EMS order status changed to "Routed") instead of **ExecutionTime** ("Filled") for latency measurement. Produced by `SP_Latency_Report_StatusUpdateTime`. Covers Jul–Oct 2024 only — introduced as part of the latency monitoring expansion (SR-274939) and stopped when the broader latency pipeline halted.

> **⚠️ VERY LIMITED DATA: Only Jul 2024 – Oct 2024 (3 months).** Pipeline stopped Oct 7, 2024. Table has 36,751 rows.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 36,751 |
| **Date range** | 2024-07-01 – 2024-10-07 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_Latency_Report_StatusUpdateTime` |
| **Frequency** | Daily (outside OpsDB) |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Sources** | Same as SP_Latency_Report but uses `StatusUpdateTime` from `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` (Routed events) instead of ExecutionTime (Filled events) |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | The trade date being reported. (Tier 2 — SP_Latency_Report_StatusUpdateTime) |
| HedgingType | varchar(10) | LP routing method: `HBC` or `CBH`. Derived from `HedgeExecutionModeID` in EMS Orders (1=HBC, else=CBH). (Tier 2 — SP_Latency_Report_StatusUpdateTime) |
| InstrumentType | varchar(50) | Instrument asset class (e.g., `Stocks`, `Currencies`, `Crypto`). (Tier 2 — DWH_dbo.Dim_Instrument) |
| ActionName | varchar(28) | Trade action: `ManualClose`, `StopLoss`, `TakeProfit`, `Manual Open`, `Order`, `OpenOpen`. (Tier 2 — SP logic) |
| No of Trades | int | Count of positions in this aggregation group. (Tier 2 — SP_Latency_Report_StatusUpdateTime) |
| Avg Latency (millisec) | int | Average ClientToRouted latency in milliseconds: `AVG(DATEDIFF(ms, RequestOccurred, StatusUpdateTime))`, floored at 0. Measures time from client request to LP routing confirmation, not full fill. (Tier 2 — SP_Latency_Report_StatusUpdateTime) |
| Max Latency (millisec) | int | Maximum ClientToRouted latency in the group. (Tier 2 — SP_Latency_Report_StatusUpdateTime) |
| Sum Latency (millisec) | bigint | Sum of ClientToRouted latencies for weighted averaging across groups. (Tier 2 — SP_Latency_Report_StatusUpdateTime) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. (Tier 1 — ETL metadata canonical) |
| Over1Sec | tinyint | Count of positions where ClientToRouted latency > 1,000 ms. (Tier 2 — SP_Latency_Report_StatusUpdateTime) |
| Regulation | varchar(50) | Regulatory jurisdiction of the client at trade time. Examples: `ASIC`, `CySEC`, `FCA`. (Tier 2 — DWH_dbo.Dim_Regulation) |

## 5. Business Rules & Relationships

- **StatusUpdateTime vs ExecutionTime**: This table measures `RequestOccurred → StatusUpdateTime` (routing confirmation), while `Dealing_Daily_Latency` measures `RequestOccurred → ExecutionTime` (fill confirmation). For most orders, StatusUpdateTime < ExecutionTime, so latencies here should be lower.
- **3-month coverage only**: Pipeline introduced Jul 2024, stopped Oct 2024. Historical analysis limited to this window.
- **Compare with**: `Dealing_Daily_Latency` (same structure, different latency base) to understand Routed vs Filled latency gap.

## 6. Query Notes

```sql
-- Compare Routed vs Filled latency for same period
SELECT dl.Date, dl.HedgingType,
       dl.[Avg Latency (millisec)] AS FilledLatency_ms,
       ds.[Avg Latency (millisec)] AS RoutedLatency_ms,
       dl.[Avg Latency (millisec)] - ds.[Avg Latency (millisec)] AS FillGap_ms
FROM [Dealing_dbo].[Dealing_Daily_Latency] dl
JOIN [Dealing_dbo].[Dealing_Daily_Latency_StatusUpdateTime] ds
  ON dl.Date = ds.Date AND dl.HedgingType = ds.HedgingType
  AND dl.InstrumentType = ds.InstrumentType AND dl.ActionName = ds.ActionName
WHERE dl.Date BETWEEN '2024-07-01' AND '2024-10-07'
```

## 7. Production Lineage

DWH-computed analytics — same source chain as `Dealing_Daily_Latency` but using EMS "Routed" event StatusUpdateTime. No upstream production wiki.

## 8. Known Issues & Notes

- **3-month window only**: July–October 2024 only. Do not use for trend analysis.
- **Columns with spaces**: Square brackets required for all column name references.
- **No Over1Sec_Routed or RoutedLatency columns**: This table pre-dates the Oct 2024 Routed latency column additions to the main `Dealing_Daily_Latency` table. The distinction here is that the SP itself uses Routed events, while the main table added Routed columns as supplementary metrics.

---
*Quality score: 7.5/10 | Documented: 2026-03-21 | Writer: SP_Latency_Report_StatusUpdateTime*
