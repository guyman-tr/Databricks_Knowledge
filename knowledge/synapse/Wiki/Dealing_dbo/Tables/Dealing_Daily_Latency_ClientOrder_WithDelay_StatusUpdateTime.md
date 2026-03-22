---
object: Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 7.5
status: stale_pipeline
---

# Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime

## 1. Purpose

StatusUpdateTime variant of `Dealing_Daily_Latency_ClientOrder_WithDelay` — uses "Routed" EMS event (`StatusUpdateTime`) instead of "Filled" (`ExecutionTime`). Produced by `SP_Latency_Report_StatusUpdateTime`. Jul–Oct 2024 only.

> **⚠️ LIMITED DATA: Jul 2024 – Oct 2024 (3 months).** 5.1M rows.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 5,087,838 (5.1M) |
| **Date range** | 2024-07-01 – 2024-10-07 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_Latency_Report_StatusUpdateTime` |
| **Frequency** | Daily (outside OpsDB) |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Trade date. (Tier 2 — SP_Latency_Report_StatusUpdateTime) |
| Regulation | varchar(50) | Regulatory jurisdiction. (Tier 2 — DWH_dbo.Dim_Regulation) |
| HedgingType | varchar(10) | `HBC` or `CBH`. (Tier 2 — SP logic) |
| PositionID | bigint | Position identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentID | int | Instrument identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentDisplayName | varchar(100) | Instrument display name. (Tier 2 — DWH_dbo.Dim_Instrument) |
| IsBuy | int | Direction: 1=Buy, 0=Sell. (Tier 2 — DWH_dbo.Dim_Position) |
| AmountInUnitsDecimal | decimal(16,6) | Trade size in units, split-adjusted. (Tier 2 — DWH_dbo.Dim_Position) |
| ForexRate | decimal(16,6) | Open/close forex rate, split-adjusted. (Tier 2 — DWH_dbo.Dim_Position) |
| Occurred | datetime | Trade execution timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| ActionName | varchar(50) | Trade action type. (Tier 2 — SP logic) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |
| ConversionRate | money | Currency conversion rate. (Tier 2 — DWH_dbo.Dim_Position) |
| RequestOccurred | datetime | Client request arrival timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| StatusUpdateTime | datetime | "Routed" EMS status timestamp — LP routing acknowledgment. Replaces ExecutionTime. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| RequestTimeFromEMS | datetime | EMS-side request timestamp. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| ExecutionID | int | EMS execution record ID. (Tier 2 — DWH_dbo.Dim_Position) |
| CID | int | Client identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| IsSettled | int | 1 if settled position. (Tier 2 — DWH_dbo.Dim_Position) |
| PnLVersion | int | PnL calculation version. (Tier 2 — DWH_dbo.Dim_Position) |
| OrderID | int | Triggering order ID. (Tier 2 — DWH_dbo.Dim_Position) |
| ClientToExecutionLatency | int | ms from RequestOccurred to StatusUpdateTime (routing, not fill). Floored at 0. (Tier 2 — computed) |
| TradingToExecutionLatency | int | ms from RequestTimeFromEMS to StatusUpdateTime. LP routing time. (Tier 2 — computed) |
| ClientToDbLatency | int | ms from RequestOccurred to Occurred. eToro internal DB latency. (Tier 2 — computed) |

## 5. Business Rules & Relationships

- Same as `Dealing_Daily_Latency_ClientOrder_WithDelay` but uses Routed timing.
- No `RoutedTime` column — the `StatusUpdateTime` column directly holds what would be `RoutedTime` in the main table.
- 3-month coverage limits analytical utility.

## 6. Query Notes

```sql
SELECT Date, PositionID, CID, ClientToExecutionLatency AS RoutingLatency_ms
FROM [Dealing_dbo].[Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime]
WHERE Date = '2024-09-01' AND ClientToExecutionLatency > 1000
ORDER BY ClientToExecutionLatency DESC
```

## 7. Production Lineage

DWH-computed analytics — same as WithDelay variant but using Routed events.

## 8. Known Issues & Notes

- **3-month window only**.
- **`ClientToExecutionLatency` measures routing** in this table, not fill.

---
*Quality score: 7.5/10 | Documented: 2026-03-21 | Writer: SP_Latency_Report_StatusUpdateTime*
