---
object: Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.5
status: stale_pipeline
---

# Dealing_Daily_Latency_ClientOrder_WithDelay

## 1. Purpose

Position-level latency detail for **orders with execution delay** — a filtered subset of `Dealing_Daily_Latency_AllPositions` that captures delayed client-triggered order executions. The "WithDelay" qualifier indicates that this table was specifically designed to identify positions where execution latency exceeded acceptable thresholds for potential compensation review. Produced by `SP_Latency_Report`.

> **⚠️ PIPELINE STALE since Jan 11, 2025.** 26.4M rows — filter by Date for queries.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 26,404,913 (26.4M) |
| **Date range** | 2021-09-20 – 2025-01-11 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_Latency_Report` |
| **Frequency** | Daily (outside OpsDB) |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Trade date. (Tier 2 — SP_Latency_Report) |
| Regulation | varchar(50) | Regulatory jurisdiction. (Tier 2 — DWH_dbo.Dim_Regulation) |
| HedgingType | varchar(10) | `HBC` or `CBH`. (Tier 2 — SP logic) |
| PositionID | bigint | Position identifier. FK to `DWH_dbo.Dim_Position`. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentID | int | Instrument identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentDisplayName | varchar(100) | Instrument display name. (Tier 2 — DWH_dbo.Dim_Instrument) |
| IsBuy | int | Direction: 1=Buy, 0=Sell. Note: `int` type (not `bit`) unlike AllPositions. (Tier 2 — DWH_dbo.Dim_Position) |
| AmountInUnitsDecimal | decimal(16,6) | Trade size in units, split-adjusted. Lower precision than AllPositions (32,8). (Tier 2 — DWH_dbo.Dim_Position) |
| ForexRate | decimal(16,6) | Open/close forex rate, split-adjusted. (Tier 2 — DWH_dbo.Dim_Position) |
| Occurred | datetime | Trade execution timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| ActionName | varchar(50) | Trade action type. (Tier 2 — SP logic) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |
| ConversionRate | money | Currency conversion rate. (Tier 2 — DWH_dbo.Dim_Position) |
| RequestOccurred | datetime | Client request arrival timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| ExecutionTime | datetime | LP fill confirmation timestamp from EMS. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| RequestTimeFromEMS | datetime | EMS-side request timestamp. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| ExecutionID | int | EMS execution record ID. (Tier 2 — DWH_dbo.Dim_Position) |
| CID | int | Client identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| IsSettled | int | 1 if position is settled (real stock). Note: `int` here vs `bit` in AllPositions. (Tier 2 — DWH_dbo.Dim_Position) |
| PnLVersion | int | P&L calculation version identifier. Indicates which pricing methodology was applied. (Tier 2 — DWH_dbo.Dim_Position) |
| OrderID | int | Order identifier that triggered this position. (Tier 2 — DWH_dbo.Dim_Position) |
| ClientToExecutionLatency | int | ms from RequestOccurred to ExecutionTime. Primary latency KPI. Floored at 0. (Tier 2 — computed) |
| TradingToExecutionLatency | int | ms from RequestTimeFromEMS to ExecutionTime. LP-internal processing. Floored at 0. (Tier 2 — computed) |
| ClientToDbLatency | int | ms from RequestOccurred to Occurred. eToro-internal DB write latency. Floored at 0. (Tier 2 — computed) |
| RoutedTime | datetime | "Routed" EMS status timestamp. Added SR-274939 Oct 2024. NULL before Oct 2024. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| ClientToRoutedLatency | int | ms from RequestOccurred to RoutedTime. LP acknowledgment latency. Added SR-274939 Oct 2024. (Tier 2 — computed) |
| HedgeServerID | int | Hedge server routing this position. NULL = platform rejection. (Tier 2 — DWH_dbo.Dim_Position) |

## 5. Business Rules & Relationships

- **Same source chain as AllPositions** — but this table is the basis for compensation analysis. The SP_Latency_Report writes compensation-eligible positions to `Dealing_Daily_Latency_Compensation_StatusUpdateTime` by cross-referencing positions from this table.
- **IsSettled/IsBuy as int**: Different types vs `Dealing_Daily_Latency_AllPositions` (which uses bit). Same data, different precision.
- **OrderID**: Present here — used to join with order tables for compensation workflows.
- **PnLVersion**: Tracks which PnL version was applicable at time of trade.

## 6. Query Notes

```sql
-- Positions with high execution latency for compensation review
SELECT Date, PositionID, CID, InstrumentID, InstrumentDisplayName,
       ClientToExecutionLatency, TradingToExecutionLatency, HedgingType, OrderID
FROM [Dealing_dbo].[Dealing_Daily_Latency_ClientOrder_WithDelay]
WHERE Date = '2024-10-01'
  AND ClientToExecutionLatency > 2000  -- > 2 seconds
ORDER BY ClientToExecutionLatency DESC
```

## 7. Production Lineage

DWH-computed — same sources as Dealing_Daily_Latency_AllPositions. No upstream production wiki.

## 8. Known Issues & Notes

- **STALE since 2025-01-11**.
- **Type differences from AllPositions**: IsBuy is `int` (not `bit`), IsSettled is `int` (not `tinyint`), precision on AmountInUnitsDecimal is (16,6) not (32,8).
- **RoutedTime/ClientToRoutedLatency NULL before Oct 2024** — added SR-274939.

---
*Quality score: 8.5/10 | Documented: 2026-03-21 | Writer: SP_Latency_Report*
