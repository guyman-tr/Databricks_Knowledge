---
object: Dealing_dbo.Dealing_Daily_Latency_Compensation_StatusUpdateTime
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.0
status: stale_pipeline
---

# Dealing_Daily_Latency_Compensation_StatusUpdateTime

## 1. Purpose

Compensation eligibility detail table for positions with execution delay — StatusUpdateTime (Routed-event) variant. Extends `Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime` with slippage measurement columns: requested vs. actual price, dollar slippage, Kusto reference rate, LP identity (`LiquidityAccountID`), and market-open proximity flags. Used to determine compensation amounts for client positions affected by routing latency. Produced by `SP_Latency_Report_StatusUpdateTime`. Jul–Oct 2024 only.

> **⚠️ LIMITED DATA: Jul 2024 – Oct 2024 (3 months).** 4.6M rows.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 4,593,802 (4.6M) |
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
| HedgingType | varchar(5) | `HBC` or `CBH`. Note: varchar(5) here vs varchar(10) in other tables. (Tier 2 — SP logic) |
| PositionID | bigint | Position identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentID | int | Instrument identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentDisplayName | varchar(100) | Instrument display name. (Tier 2 — DWH_dbo.Dim_Instrument) |
| IsBuy | int | Direction: 1=Buy, 0=Sell. (Tier 2 — DWH_dbo.Dim_Position) |
| AmountInUnitsDecimal | decimal(16,6) | Trade size in units, split-adjusted. (Tier 2 — DWH_dbo.Dim_Position) |
| ForexRate | decimal(16,6) | Open/close forex rate, split-adjusted. (Tier 2 — DWH_dbo.Dim_Position) |
| Occurred | datetime | Trade execution timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| ActionName | varchar(50) | Trade action type. (Tier 2 — SP logic) |
| ConversionRate | money | Currency conversion rate. (Tier 2 — DWH_dbo.Dim_Position) |
| eToroTime | datetime | eToro-side timestamp for this execution event. (Tier 2 — DWH_dbo.Dim_Position) |
| LiquidityAccountID | int | LP account that executed this position — identifies which LP to charge compensation. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| Price_Requested | decimal(16,6) | Price the client requested at order submission. Basis for slippage calculation. (Tier 2 — DWH_dbo.Dim_Position) |
| Spread | decimal(16,6) | Bid-ask spread at time of execution. (Tier 2 — SP logic) |
| KustoTime | datetime | Timestamp from Kusto reference rate lookup. (Tier 2 — Kusto/CopyFromLake reference) |
| Kusto_Rate | decimal(16,6) | Reference rate from Kusto at execution time. Used as fair-value benchmark. (Tier 2 — Kusto/CopyFromLake reference) |
| SlippageInDollar | money | Dollar value of slippage: (Kusto_Rate − Price_Requested) × AmountInUnitsDecimal × ConversionRate. Negative = adverse slippage. (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |
| RequestOccurred | datetime | Client request arrival timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| StatusUpdateTime | datetime | "Routed" EMS status timestamp — LP routing acknowledgment. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| RequestTimeFromEMS | datetime | EMS-side request timestamp. (Tier 2 — CopyFromLake.eToroLogs_Real_Hedge_EMSOrders) |
| ExecutionID | int | EMS execution record ID. (Tier 2 — DWH_dbo.Dim_Position) |
| CID | int | Client identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| IsSettled | int | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| PnLVersion | int | PnL calculation version. (Tier 2 — DWH_dbo.Dim_Position) |
| OrderID | int | Triggering order ID. (Tier 2 — DWH_dbo.Dim_Position) |
| ClientToDbLatency | int | ms from RequestOccurred to Occurred. eToro internal DB latency. Floored at 0. (Tier 2 — computed) |
| ClientToExecutionLatency | int | ms from RequestOccurred to StatusUpdateTime (routing, not fill). Primary latency KPI. Floored at 0. (Tier 2 — computed) |
| TradingToExecutionLatency | int | ms from RequestTimeFromEMS to StatusUpdateTime. LP routing time. Floored at 0. (Tier 2 — computed) |
| OpenMarketTime | datetime | Market open timestamp on this trade date for the instrument's exchange. (Tier 2 — SP logic / market calendar) |
| WithinFirst5Minutes_MarketHours | bit | 1 if trade occurred within 5 minutes of market open. Compensation modifier. (Tier 2 — computed) |
| WithinFirst7Minutes_MarketHours | bit | 1 if trade occurred within 7 minutes of market open. Compensation modifier. (Tier 2 — computed) |

## 5. Business Rules & Relationships

- **Compensation logic**: This table is the basis for actual compensation payments. `SlippageInDollar` represents the dollar value of adverse price movement attributable to routing latency.
- **`LiquidityAccountID`**: Identifies which LP is charged — key for LP-level compensation accountability.
- **Market-open flags**: `WithinFirst5Minutes_MarketHours` and `WithinFirst7Minutes_MarketHours` are compensation modifiers — positions opened just after market open often have wider spreads and different compensation thresholds.
- **`Kusto_Rate`**: Fair-value reference rate from Kusto (Databricks/Azure Data Explorer log analytics). Different from the execution price — the delta drives `SlippageInDollar`.
- **`HedgingType` varchar(5)**: Narrower type than other latency tables (varchar(10)). Values are still `HBC`/`CBH` — no functional impact.
- **Subset of WithDelay**: Row count (4.6M) < ClientOrder_WithDelay_StatusUpdateTime (5.1M) — compensation table is filtered to positions with adverse slippage above threshold.

## 6. Query Notes

```sql
-- Top LP accounts by adverse slippage (compensation candidates)
SELECT LiquidityAccountID, COUNT(*) AS Positions,
       SUM(SlippageInDollar) AS TotalSlippage_USD,
       AVG(ClientToExecutionLatency) AS AvgRoutingLatency_ms
FROM [Dealing_dbo].[Dealing_Daily_Latency_Compensation_StatusUpdateTime]
WHERE Date BETWEEN '2024-07-01' AND '2024-10-07'
  AND SlippageInDollar < 0  -- adverse slippage only
GROUP BY LiquidityAccountID
ORDER BY TotalSlippage_USD ASC
```

```sql
-- First-5-minutes positions (typically excluded from compensation)
SELECT Date, COUNT(*) AS Positions, SUM(SlippageInDollar) AS Slippage_USD
FROM [Dealing_dbo].[Dealing_Daily_Latency_Compensation_StatusUpdateTime]
WHERE WithinFirst5Minutes_MarketHours = 1
GROUP BY Date ORDER BY Date
```

## 7. Production Lineage

DWH-computed — sources Dim_Position, EMSOrders (Routed events), Kusto reference rates. No upstream production wiki.

## 8. Known Issues & Notes

- **3-month window only** (Jul–Oct 2024).
- **`ClientToExecutionLatency` measures routing** (RequestOccurred→StatusUpdateTime), not fill — same naming mismatch as other SUT tables.
- **`HedgingType` varchar(5)** differs from varchar(10) in sibling tables — no data impact.
- **`SlippageInDollar` sign convention**: Negative = client paid more than fair value (adverse). Positive = client received better price.

---
*Quality score: 8.0/10 | Documented: 2026-03-21 | Writer: SP_Latency_Report_StatusUpdateTime*
