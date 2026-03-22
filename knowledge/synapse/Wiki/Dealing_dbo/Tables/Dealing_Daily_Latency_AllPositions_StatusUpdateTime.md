---
object: Dealing_dbo.Dealing_Daily_Latency_AllPositions_StatusUpdateTime
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 7.5
status: stale_pipeline
---

# Dealing_Daily_Latency_AllPositions_StatusUpdateTime

## 1. Purpose

Position-level latency detail table using **StatusUpdateTime** ("Routed" EMS event) instead of ExecutionTime ("Filled"). Parallel to `Dealing_Daily_Latency_AllPositions` but replaces `ExecutionTime` with `StatusUpdateTime`. Used for analyzing LP routing acknowledgment latency at position granularity. Produced by `SP_Latency_Report_StatusUpdateTime`.

> **⚠️ LIMITED DATA: Jul 2024 – Oct 2024 only (3 months).** 56.9M rows despite short window.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 56,893,555 (56.9M) |
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
| HedgingType | varchar(10) | `HBC` or `CBH`. NULL if no EMS record. (Tier 2 — SP logic) |
| PositionID | bigint | Position identifier. FK to `DWH_dbo.Dim_Position`. (Tier 2 — DWH_dbo.Dim_Position) |
| CID | int | Client identifier. FK to `DWH_dbo.Dim_Customer.RealCID`. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentID | int | Instrument identifier. FK to `DWH_dbo.Dim_Instrument`. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentDisplayName | varchar(250) | Instrument display name. (Tier 2 — DWH_dbo.Dim_Instrument) |
| InstrumentType | varchar(50) | Instrument asset class. (Tier 2 — DWH_dbo.Dim_Instrument) |
| IsBuy | bit | Direction: 1=Buy, 0=Sell. (Tier 2 — DWH_dbo.Dim_Position) |
| AmountInUnitsDecimal | decimal(32,8) | Trade size in units, split-adjusted. (Tier 2 — DWH_dbo.Dim_Position) |
| ForexRate | decimal(16,8) | Open/close forex rate, split-adjusted. (Tier 2 — DWH_dbo.Dim_Position) |
| Occurred | datetime | Trade execution timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| ActionName | varchar(50) | Trade action type. (Tier 2 — SP logic) |
| ConversionRate | money | Currency conversion rate. (Tier 2 — DWH_dbo.Dim_Position) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |
| RequestOccurred | datetime | Client request arrival timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| ExecutionID | int | EMS execution record ID. (Tier 2 — DWH_dbo.Dim_Position) |
| StatusUpdateTime | datetime | Timestamp of "Routed" EMS status update — LP acknowledgment time. Replaces `ExecutionTime` in the standard table. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| RequestTimeFromEMS | datetime | EMS-side request timestamp. Used for TradingToExecution calc. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| ClientToDbLatency | int | ms from RequestOccurred to Occurred. (Tier 2 — computed) |
| ClientToExecutionLatency | int | ms from RequestOccurred to StatusUpdateTime (routing). Named "Execution" but measures routing in this variant. (Tier 2 — computed) |
| TradingToExecutionLatency | int | ms from RequestTimeFromEMS to StatusUpdateTime. LP-internal routing time. (Tier 2 — computed) |

## 5. Business Rules & Relationships

- **StatusUpdateTime = Routing time, not Fill time**: Despite column name `ClientToExecutionLatency`, in this table it measures `RequestOccurred → StatusUpdateTime`. The `_StatusUpdateTime` tables consistently use Routed events.
- **56.9M rows in 3 months**: Much denser than the non-StatusUpdateTime variant's ~295M rows over 3 years — the SP captured more positions per day.
- **Use together with AllPositions**: Compare to understand fill latency vs routing latency at position level.

## 6. Query Notes

```sql
-- Routing latency vs fill latency for same position
SELECT a.PositionID, a.CID, a.Date,
       a.ClientToExecutionLatency AS RoutingLatency_ms,
       b.ClientToExecutionLatency AS FillLatency_ms,
       b.ClientToExecutionLatency - a.ClientToExecutionLatency AS FillGap_ms
FROM [Dealing_dbo].[Dealing_Daily_Latency_AllPositions_StatusUpdateTime] a
JOIN [Dealing_dbo].[Dealing_Daily_Latency_AllPositions] b ON a.PositionID = b.PositionID AND a.Date = b.Date
WHERE a.Date = '2024-09-15'
ORDER BY FillGap_ms DESC
```

> ⚠️ **Always filter by Date.** 56.9M rows on ROUND_ROBIN with no date filter causes full scans.

## 7. Production Lineage

DWH-computed analytics — same as Dealing_Daily_Latency_AllPositions but using Routed EMS events.

## 8. Known Issues & Notes

- **3-month window**: Not suitable for trend analysis.
- **Column naming confusion**: `ClientToExecutionLatency` in this table measures routing time (not fill), unlike in `Dealing_Daily_Latency_AllPositions` where it measures fill time.

---
*Quality score: 7.5/10 | Documented: 2026-03-21 | Writer: SP_Latency_Report_StatusUpdateTime*
