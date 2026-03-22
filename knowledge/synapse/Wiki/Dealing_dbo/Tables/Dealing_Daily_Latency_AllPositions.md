---
object: Dealing_dbo.Dealing_Daily_Latency_AllPositions
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.5
status: stale_pipeline
---

# Dealing_Daily_Latency_AllPositions

## 1. Purpose

Position-level latency detail table — one row per position per day for all positions with latency records. Unlike `Dealing_Daily_Latency` (aggregated), this table retains individual position granularity with multiple latency components. Used for per-position latency investigation and per-CID analysis. Produced by `SP_Latency_Report` (same SP as Dealing_Daily_Latency).

> **⚠️ PIPELINE STALE since Jan 11, 2025**. 295.7M rows — do NOT use `COUNT(*)` without a date filter. Use `COUNT_BIG(*)` or filter by Date.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 295,719,030 (295.7M) |
| **Date range** | 2022-05-31 – 2025-01-11 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_Latency_Report` |
| **Frequency** | Daily (outside OpsDB) |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Sources** | `DWH_dbo.Dim_Position`, `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` (Filled+Routed events), `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_HistorySplitRatio` |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Trade date (open or close date of the position). (Tier 2 — SP_Latency_Report) |
| Regulation | varchar(50) | Regulatory jurisdiction: `ASIC`, `CySEC`, `FCA`, etc. Sourced from `Dim_Regulation.Name` via `Fact_SnapshotCustomer`. (Tier 2 — DWH_dbo.Dim_Regulation) |
| HedgingType | varchar(10) | LP routing method: `HBC` or `CBH`. NULL if no EMS record found for the position. (Tier 2 — SP_Latency_Report) |
| PositionID | bigint | Unique position identifier. Foreign key to `DWH_dbo.Dim_Position.PositionID`. (Tier 2 — DWH_dbo.Dim_Position) |
| CID | int | Client identifier. Foreign key to `DWH_dbo.Dim_Customer.RealCID`. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentID | int | Instrument identifier. Foreign key to `DWH_dbo.Dim_Instrument.InstrumentID`. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentDisplayName | varchar(250) | Instrument display name (e.g., "Apple"). Sourced from `Dim_Instrument.InstrumentDisplayName`. (Tier 2 — DWH_dbo.Dim_Instrument) |
| InstrumentType | varchar(50) | Instrument asset class. (Tier 2 — DWH_dbo.Dim_Instrument) |
| IsBuy | bit | Direction: 1=Buy, 0=Sell. (Tier 2 — DWH_dbo.Dim_Position) |
| AmountInUnitsDecimal | decimal(32,8) | Trade size in instrument units, split-adjusted. `Dim_Position.AmountInUnitsDecimal * COALESCE(SplitRatio.AmountRatio, 1)`. (Tier 2 — DWH_dbo.Dim_Position, split-adjusted) |
| ForexRate | decimal(16,8) | Position open or close forex rate, split-adjusted. `InitForexRate * COALESCE(SplitRatio.PriceRatio, 1)`. (Tier 2 — DWH_dbo.Dim_Position, split-adjusted) |
| Occurred | datetime | Timestamp when the trade actually occurred (open or close). (Tier 2 — DWH_dbo.Dim_Position) |
| ActionName | varchar(50) | Trade action: `ManualClose`, `StopLoss`, `TakeProfit`, `Manual Open`, `Order`, `OpenOpen`. (Tier 2 — SP logic) |
| ConversionRate | money | Currency conversion rate at the time of trade. Used to convert latency compensation amounts to USD. (Tier 2 — DWH_dbo.Dim_Position) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 1 — ETL metadata canonical) |
| RequestOccurred | datetime | Timestamp when the client's request arrived at the eToro server. `RequestOpenOccurred` for opens, `RequestCloseOccurred` for closes. (Tier 2 — DWH_dbo.Dim_Position) |
| ExecutionID | int | EMS execution identifier. Links to `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.ExecutionID`. (Tier 2 — DWH_dbo.Dim_Position) |
| ExecutionTime | datetime | Timestamp when the LP confirmed execution ("Filled" status in EMS Orders). Primary latency endpoint. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| RequestTimeFromEMS | datetime | Timestamp of the request as recorded by the EMS (LP side). Used for `TradingToExecutionLatency`. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| ClientToDbLatency | int | Milliseconds from `RequestOccurred` to `Occurred` — time for the eToro database to record the trade. (Tier 2 — computed) |
| ClientToExecutionLatency | int | Milliseconds from `RequestOccurred` to `ExecutionTime` — total client-to-LP execution time. The primary latency KPI. Floored at 0. (Tier 2 — computed: `DATEDIFF(ms, RequestCloseOccurred, ExecutionTime)`) |
| TradingToExecutionLatency | int | Milliseconds from `RequestTimeFromEMS` (EMS request timestamp) to `ExecutionTime` — time within the LP matching engine. Floored at 0. (Tier 2 — computed: `DATEDIFF(ms, RequestTime, ExecutionTime)`) |
| RoutedTime | datetime | Timestamp when the EMS order status changed to "Routed" (LP acknowledged but not yet filled). Added SR-274939 Oct 2024. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| ClientToRoutedLatency | int | Milliseconds from `RequestOccurred` to `RoutedTime`. Indicates time to LP acknowledgment. Floored at 0. Added SR-274939 Oct 2024. (Tier 2 — computed) |
| HedgeServerID | int | Identifier of the eToro hedge server that routed the position. Maps to `DWH_dbo.Dim_HedgeServer`. NULL = platform-level rejection. (Tier 2 — DWH_dbo.Dim_Position) |

## 5. Business Rules & Relationships

- **Scope**: Same as `Dealing_Daily_Latency` — SL/TP/Manual events, MirrorID=0, IsValidCustomer=1, no re-opens.
- **295.7M rows warning**: Always filter by Date. Use COUNT_BIG(*). Full scans will be extremely slow.
- **Split-adjusted values**: AmountInUnitsDecimal and ForexRate are adjusted for stock splits via `DWH_dbo.Dim_HistorySplitRatio`.
- **EMS JOIN**: `#HedgingType` (Filled) and `#HedgingType_Routed` (Routed) are LEFT JOINed — positions without EMS records will have NULL HedgingType, ExecutionTime, RoutedTime.
- **ClientToDbLatency**: `DATEDIFF(ms, RequestOccurred, Occurred)` — measures internal eToro DB write latency before routing to LP.
- **Three latency components**: ClientToDb (eToro internal) + TradingToExecution (LP-side) ≈ ClientToExecution (end-to-end).

## 6. Query Notes

```sql
-- Position-level latency for a specific date
SELECT Date, PositionID, CID, InstrumentID, ActionName,
       ClientToDbLatency, ClientToExecutionLatency, TradingToExecutionLatency, ClientToRoutedLatency
FROM [Dealing_dbo].[Dealing_Daily_Latency_AllPositions]
WHERE Date = '2024-10-01'
  AND ClientToExecutionLatency > 1000  -- > 1 second
ORDER BY ClientToExecutionLatency DESC

-- CID-level latency profile for one day
SELECT CID, COUNT_BIG(*) AS Trades,
       AVG(ClientToExecutionLatency) AS AvgLatency,
       MAX(ClientToExecutionLatency) AS MaxLatency
FROM [Dealing_dbo].[Dealing_Daily_Latency_AllPositions]
WHERE Date = '2024-06-15'
GROUP BY CID ORDER BY AvgLatency DESC
```

> ⚠️ **NEVER query without a Date filter.** 295.7M rows on ROUND_ROBIN distribution will cause full table scan across all nodes.

## 7. Production Lineage

DWH-computed analytics — no direct production SQL Server passthrough. Sources: `DWH_dbo.Dim_Position`, `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders`, `DWH_dbo.Dim_Instrument`.

## 8. Known Issues & Notes

- **STALE since 2025-01-11**: Same cause as Dealing_Daily_Latency — CopyFromLake feed disruption.
- **295.7M rows**: Second largest position-level table in Dealing_dbo. Use COUNT_BIG, always date-filter.
- **RoutedTime/ClientToRoutedLatency**: Only populated from Oct 2024 onward (SR-274939). NULL for all rows before that.
- **TradingToExecutionLatency**: Uses EMS RequestTime vs ExecutionTime — measures LP-internal processing speed. For HBC positions, this is the client-facing latency at the hedge server level.

---
*Quality score: 8.5/10 | Documented: 2026-03-21 | Writer: SP_Latency_Report*
