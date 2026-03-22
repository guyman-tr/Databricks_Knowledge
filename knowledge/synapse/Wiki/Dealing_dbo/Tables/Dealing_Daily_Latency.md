---
object: Dealing_dbo.Dealing_Daily_Latency
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.5
status: stale_pipeline
---

# Dealing_Daily_Latency

## 1. Purpose

Daily aggregate latency report for eToro trade execution — covers positions opened or closed each day with manual/SL/TP events. Aggregated by date × hedging type × instrument type × action name × regulation. Produced by **SP_Latency_Report** (author: Adar Cahlon), the primary Dealing execution-quality monitoring SP. Pipeline uses two latency calculation paths:
- **ClientToExecution**: `DATEDIFF(ms, RequestOccurred, ExecutionTime)` — time from client request arrival to LP execution confirmation (via EMS Orders)
- **ClientToRouted**: `DATEDIFF(ms, RequestOccurred, StatusUpdateTime)` — alternate path using "Routed" EMS status instead of "Filled"

> **⚠️ PIPELINE STALE since Jan 11, 2025** — same halt date as Dealing_Daily_Slippage_Positions. SP_Latency_Report depends on CopyFromLake feeds (EMSOrders, PriceLog_History_CurrencyPrice, PricesFromProvider_MarketCurrencyPrice) that stopped being refreshed. Operational investigation required.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 473,560 |
| **Date range** | 2018-01-01 – 2025-01-11 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |
| **Avg latency** | ~2,850 ms (population avg) |
| **Max latency** | 30,855,223 ms (outlier — likely reconnect gap) |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_Latency_Report` |
| **SP author** | Adar Cahlon (migrated from BI_DB by Eden Liberman) |
| **Frequency** | Daily (OpsDB: not in opsdb-objects-status — run outside OpsDB, likely Windows scheduler) |
| **Load mode** | TRUNCATE-equivalent (DELETE WHERE Date = @Date, then INSERT) |
| **Sources** | `DWH_dbo.Dim_Position` (positions), `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` (EMS latency), `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Regulation`, `Dealing_staging.External_CalendarDB_Market_MergedDailySchedules` (market hours) |
| **Scope filter** | IsValidCustomer=1, MirrorID=0, OrigParentPositionID=0, SL/TP/Manual actions only (ClosePositionReasonID IN (1,5,0,14)) |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | The trade date being reported. One row per unique (Date, HedgingType, InstrumentType, ActionName, Regulation, WithinFirst5Minutes_MarketHours, IsSettled) combination. (Tier 2 — SP_Latency_Report) |
| HedgingType | varchar(10) | LP routing method: `HBC` (Hedge By Client — client-side hedging) or `CBH` (Covered By Hedge — eToro hedges on LP side). Derived from `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.HedgeExecutionModeID`: 1=HBC, else=CBH. NULL when EMS record not found for a position. (Tier 2 — SP_Latency_Report) |
| InstrumentType | varchar(50) | Instrument asset class (e.g., `Stocks`, `Currencies`, `Crypto`). Sourced from `DWH_dbo.Dim_Instrument.InstrumentType`. (Tier 2 — DWH_dbo.Dim_Instrument) |
| ActionName | varchar(28) | Trade action type: `ManualClose`, `StopLoss`, `TakeProfit`, `Manual Open`, `Order`, `OpenOpen`. Derived from ClosePositionReasonID and OrderType in SP logic. (Tier 2 — SP_Latency_Report) |
| No of Trades | int | Count of positions contributing to this aggregation group for the day. (Tier 2 — SP_Latency_Report) |
| Avg Latency (millisec) | int | Average ClientToExecution latency in milliseconds across all positions in the group: `AVG(DATEDIFF(ms, RequestOccurred, ExecutionTime))`. Floored at 0 (negative latencies clamped to 0). (Tier 2 — SP_Latency_Report) |
| Max Latency (millisec) | int | Maximum ClientToExecution latency in milliseconds in the group. Extreme outliers (e.g., 30M ms) indicate reconnect or stale EMS record. (Tier 2 — SP_Latency_Report) |
| Sum Latency (millisec) | bigint | Sum of all ClientToExecution latency values in the group. Used to compute weighted averages across groups. (Tier 2 — SP_Latency_Report) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last inserted/updated by the ETL pipeline. (Tier 1 — ETL metadata canonical) |
| Over1Sec | tinyint | Count of positions in this group where ClientToExecution latency > 1,000 ms. Useful for SLA breach monitoring. (Tier 2 — SP_Latency_Report) |
| Regulation | varchar(50) | Regulatory jurisdiction of the client at trade time. Sourced from `DWH_dbo.Dim_Regulation.Name` via `Fact_SnapshotCustomer`. Examples: `ASIC`, `CySEC`, `FCA`. (Tier 2 — DWH_dbo.Dim_Regulation) |
| WithinFirst5Minutes_MarketHours | bit | Flag: 1 if the position's RequestOccurred (close) or RequestOpenOccurred (open) falls within the first 5 minutes of the exchange session (from `OpenTimeUTC` in CalendarDB schedule). Used to isolate open-session latency spikes. Added SR-273548 Sep 2024. (Tier 2 — SP_Latency_Report) |
| Over1Sec_Routed | tinyint | Count of positions where ClientToRouted latency (RequestOccurred → StatusUpdateTime of "Routed" EMS event) exceeds 1,000 ms. Added SR-274939 Oct 2024. (Tier 2 — SP_Latency_Report) |
| Avg Routed Latency (millisec) | int | Average ClientToRouted latency (ms). Complements `Avg Latency` — shows how quickly orders are routed to the LP vs. fully filled. Added SR-274939 Oct 2024. (Tier 2 — SP_Latency_Report) |
| Max Routed Latency (millisec) | int | Maximum ClientToRouted latency (ms) in the group. Added SR-274939 Oct 2024. (Tier 2 — SP_Latency_Report) |
| Sum Routed Latency (millisec) | bigint | Sum of ClientToRouted latencies in the group. Added SR-274939 Oct 2024. (Tier 2 — SP_Latency_Report) |
| IsSettled | tinyint | Flag: 1 if the position was settled (i.e., traded on a real stock exchange). Sourced from `DWH_dbo.Dim_Position.IsSettled`. Added SR-276858 Oct 2024. (Tier 2 — DWH_dbo.Dim_Position) |

## 5. Business Rules & Relationships

- **Scope**: Only positions that were opened or closed via manual action, SL, or TP (`ClosePositionReasonID IN (1,5,0,14)`). Copy positions (`MirrorID>0`) and re-opens (`ReopenForPositionID IS NOT NULL`) are excluded.
- **Split adjustments**: Position prices are adjusted for stock splits using `DWH_dbo.Dim_HistorySplitRatio` before spread calculations.
- **Market hours source**: `Dealing_staging.External_CalendarDB_Market_MergedDailySchedules` — first session window per exchange per day (Rank=1 row).
- **Latency definition**: ClientToExecution = `DATEDIFF(ms, RequestCloseOccurred, ExecutionTime)`. For opens, `RequestOpenOccurred` is used. Values < 0 are clamped to 0.
- **StatusUpdateTime tables**: The `_StatusUpdateTime` variant tables use EMS "Routed" event time instead of "Filled" event time. Produced by a separate SP: `SP_Latency_Report_StatusUpdateTime`.
- **Related tables**: `Dealing_Daily_Latency_AllPositions` — position-level detail without aggregation; `Dealing_Daily_Latency_ClientOrder_WithDelay` — delayed orders only; `Dealing_Daily_Latency_Compensation_StatusUpdateTime` — compensation detail per slippage event.

## 6. Query Notes

```sql
-- Avg latency by regulation and hedging type for a date range
SELECT Date, Regulation, HedgingType, InstrumentType, ActionName,
       SUM([No of Trades]) AS Trades,
       SUM([Sum Latency (millisec)]) * 1.0 / NULLIF(SUM([No of Trades]),0) AS WeightedAvgLatency_ms
FROM [Dealing_dbo].[Dealing_Daily_Latency]
WHERE Date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY Date, Regulation, HedgingType, InstrumentType, ActionName
ORDER BY Date, WeightedAvgLatency_ms DESC

-- SLA breach trend: Over1Sec counts over time
SELECT Date, SUM([Over1Sec]) AS Breaches, SUM([No of Trades]) AS Total,
       100.0 * SUM([Over1Sec]) / NULLIF(SUM([No of Trades]),0) AS BreachPct
FROM [Dealing_dbo].[Dealing_Daily_Latency]
GROUP BY Date ORDER BY Date
```

> **⚠️ Use `Sum Latency / No of Trades` for correct weighted averages across groups** — simple `AVG([Avg Latency])` will be incorrect when group sizes differ.

## 7. Production Lineage

Source: DWH-computed analytics table (no direct production SQL Server passthrough). All columns are ETL-computed from:
- `DWH_dbo.Dim_Position` — position timestamps (RequestOccurred, Occurred)
- `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` — LP execution timestamps (ExecutionTime, StatusUpdateTime)
- `DWH_dbo.Dim_Instrument`, `Dim_Customer`, `Fact_SnapshotCustomer`, `Dim_Regulation`, `Dim_ClosePositionReason`

No upstream production wiki columns apply.

## 8. Known Issues & Notes

- **Pipeline stale since 2025-01-11**: SP_Latency_Report ceased updating — same date as Dealing_Daily_Slippage tables. Likely caused by CopyFromLake feed disruption affecting EMSOrders and PriceLog tables.
- **Latency method changed Dec 2023** (SR-221178/SR-222233/SR-222801): Original RequestTime-based latency replaced with ExecutionTime from EMS Orders for more accurate LP-side measurement.
- **StatusUpdateTime families added Jul 2024**: SP_Latency_Report_StatusUpdateTime produces parallel tables (`_StatusUpdateTime` suffix) using "Routed" EMS events rather than "Filled." These stopped Oct 2024 (3 months only).
- **RoutedTime columns added Oct 2024** (SR-274939): ClientToRoutedLatency measures time to routing, complementing ClientToExecutionLatency.
- **Columns with spaces**: `No of Trades`, `Avg Latency (millisec)`, etc. — use square brackets in all queries.

---
*Quality score: 8.5/10 | Documented: 2026-03-21 | Writer: SP_Latency_Report*
