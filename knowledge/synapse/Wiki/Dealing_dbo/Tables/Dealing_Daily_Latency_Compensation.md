# Dealing_dbo.Dealing_Daily_Latency_Compensation

## 1. Overview

**Position-level execution latency records** for positions that experienced significant latency (>1 second threshold), enriched with the computed compensation amount due to the client. Each row captures a single position action (open or close) that exceeded the latency threshold, with the full latency decomposition (client-to-DB, client-to-execution, trading-to-execution, client-to-routed), LP price at execution, spread, and the resulting slippage/compensation in USD. This table feeds the Best Execution report (`SP_Best_Execution`) for both CBH and HBC LP types.

> **⚠️ DATA CURRENCY WARNING**: Maximum data date is **2025-01-11** — approximately 14 months before documentation date. The SP_Latency_Report and downstream SP_Best_Execution pipelines appear to have been decommissioned or significantly disrupted around that date. Treat as potentially deprecated. Confirm with Dealing team before building new consumers.

**Row grain**: `Date` + `PositionID` + `ActionTypeID` (position action — open or close).

---

## 2. Business Context

`SP_Latency_Report` (Author: Eden Liberman 2018, extensively updated by Adar Cahlon through 2024) identifies position actions where the time from client request to hedge execution exceeded a threshold. The SP processes four output tables; this table captures **positions that exceed the latency threshold for potential compensation**.

**Latency sources**: The SP reads LP execution timestamps from `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` (the Async EMS order log as of SR-223342). Price ticks are sourced from `CopyFromLake.PriceLog_History_CurrencyPrice` with LP-specific routing (`LiquidityAccountID NOT IN (100017, 100018)`) and EU exchange special handling.

**Latency components**:
- `ClientToDbLatency`: Time from client request receipt to DB entry (ms).
- `ClientToExecutionLatency`: Time from client request to LP execution (ms).
- `TradingToExecutionLatency`: Time from trading engine to LP execution (ms).
- `ClientToRoutedLatency`: Time from client request to routing (ms).

**Market hours flags** (`WithinFirst5Minutes_MarketHours`, `WithinFirst7Minutes_MarketHours`) indicate whether the trade occurred in the first 5 or 7 minutes after market open — relevant because liquidity is typically thinner at open.

**SlippageInDollar**: The USD monetary slippage for the position (from `Dealing_Daily_Slippage_Positions`).

**Key business rules**:

- **Threshold**: Positions with latency > 1000 ms are included (SELECT DISTINCT from `#TotalData_WithMarketHours`).
- **CBH vs HBC split**: Positions are classified by `HedgingType` ('CBH' or 'HBC') based on LP routing.
- **EU exchange special handling**: EU-listed instruments use EU-specific LP liquidity accounts (IDs 54, 127) for price matching.
- **DELETE-INSERT by date**.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 37 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~22,200,000 |
| **Max date** | **2025-01-11** — pipeline appears decommissioned |
| **HedgingType distribution** | Mix of CBH and HBC rows |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the latency event. (Tier 2 -- SP_Latency_Report, @StartDate) |
| 2 | Regulation | varchar(50) | YES | Customer regulation from snapshot. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Regulation.Name) |
| 3 | HedgingType | varchar(5) | YES | LP routing type: 'CBH' (Citi Brokerage Holdings) or 'HBC' (Hedge Broker Connection). (Tier 2 -- SP_Latency_Report, derived from LP routing logic) |
| 4 | PositionID | bigint | YES | Position identifier. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.PositionID) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.InstrumentID) |
| 6 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 7 | IsBuy | int | YES | Position direction: 1=buy/long, 0=sell/short. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.IsBuy) |
| 8 | AmountInUnitsDecimal | decimal(16,6) | YES | Position size in instrument units (split-adjusted). (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.AmountInUnitsDecimal) |
| 9 | ForexRate | decimal(16,6) | YES | Execution rate for the position action. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.OpenForexRate / CloseForexRate) |
| 10 | Occurred | datetime | YES | Timestamp when the position action occurred. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.OpenOccurred / CloseOccurred) |
| 11 | ActionName | varchar(50) | YES | Position action type (Open, Manual Close, Take Profit, Stop Loss, etc.). (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position action type) |
| 12 | ConversionRate | money | YES | FX conversion rate to USD for the position. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.InitForexRate / EndForexRate) |
| 13 | eToroTime | datetime | YES | eToro system timestamp for the position action. (Tier 2 -- SP_Latency_Report, from EMS order log) |
| 14 | LiquidityAccountID | int | YES | LP account that executed the hedge for this position. (Tier 2 -- SP_Latency_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.LiquidityAccountID) |
| 15 | Price_Requested | decimal(16,6) | YES | Price requested by the client at order submission. (Tier 2 -- SP_Latency_Report, from client request data) |
| 16 | Spread | decimal(16,6) | YES | Bid-ask spread at execution time (CBH: from spreaded forex prices; HBC: derived from commission). (Tier 2 -- SP_Latency_Report, computed from InitForex/EndForex spreaded prices) |
| 17 | KustoTime | datetime | YES | Timestamp from the Kusto (Azure Data Explorer) price tick log. (Tier 2 -- SP_Latency_Report, CopyFromLake.PriceLog_History_CurrencyPrice.Occurred) |
| 18 | Kusto_Rate | decimal(16,6) | YES | LP price from the Kusto tick at execution time. (Tier 2 -- SP_Latency_Report, CopyFromLake.PriceLog_History_CurrencyPrice.Ask / Bid) |
| 19 | SlippageInDollar | money | YES | Monetary slippage in USD from Dealing_Daily_Slippage_Positions. (Tier 2 -- SP_Latency_Report, Dealing_dbo.Dealing_Daily_Slippage_Positions.SlippageInDollar) |
| 20 | UpdateDate | datetime | NOT NULL | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_Latency_Report, GETDATE()) |
| 21 | RequestOccurred | datetime | YES | Timestamp of the client's original request (OpenOccurred or CloseOccurred from Dim_Position). (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.RequestOpenOccurred / RequestCloseOccurred) |
| 22 | ExecutionTime | datetime | YES | Timestamp when LP executed the order (from EMS log). (Tier 2 -- SP_Latency_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.ExecutionTime) |
| 23 | RequestTimeFromEMS | datetime | YES | Request time as recorded in the EMS order log. (Tier 2 -- SP_Latency_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.RequestTime) |
| 24 | ExecutionID | int | YES | EMS execution identifier linking to the LP order. (Tier 2 -- SP_Latency_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.ExecutionID) |
| 25 | CID | int | YES | Customer identifier. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.CID) |
| 26 | IsSettled | int | YES | Settled flag (1=Real stocks, 0=CFD). (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.IsSettled) |
| 27 | PnLVersion | int | YES | P&L version indicator for the position. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.PnLVersion) |
| 28 | OrderID | int | YES | Order identifier from the EMS system. (Tier 2 -- SP_Latency_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.OrderID) |
| 29 | ClientToDbLatency | int | YES | Milliseconds from client request to DB entry. (Tier 2 -- SP_Latency_Report, computed from timestamps) |
| 30 | ClientToExecutionLatency | int | YES | Milliseconds from client request to LP execution. (Tier 2 -- SP_Latency_Report, computed: ExecutionTime − RequestOccurred) |
| 31 | TradingToExecutionLatency | int | YES | Milliseconds from trading engine timestamp to LP execution. (Tier 2 -- SP_Latency_Report, computed from EMS timestamps) |
| 32 | OpenMarketTime | datetime | YES | Market open time for the instrument's exchange on the report date. (Tier 2 -- SP_Latency_Report, Dealing_staging.External_CalendarDB_Market_MergedDailySchedules) |
| 33 | WithinFirst5Minutes_MarketHours | bit | YES | 1 if the action occurred within 5 minutes of market open. (Tier 2 -- SP_Latency_Report, computed: Occurred BETWEEN OpenMarketTime AND OpenMarketTime+5min) |
| 34 | WithinFirst7Minutes_MarketHours | bit | YES | 1 if the action occurred within 7 minutes of market open. (Tier 2 -- SP_Latency_Report, computed: Occurred BETWEEN OpenMarketTime AND OpenMarketTime+7min) |
| 35 | RoutedTime | datetime | YES | Timestamp when the order was routed to the LP. (Tier 2 -- SP_Latency_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.RoutedTime) |
| 36 | ClientToRoutedLatency | int | YES | Milliseconds from client request to routing. (Tier 2 -- SP_Latency_Report, computed: RoutedTime − RequestOccurred) |
| 37 | HedgeServerID | int | YES | Hedge server that processed the LP execution. (Tier 2 -- SP_Latency_Report, DWH_dbo.Dim_Position.HedgeServerID) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| eToroLogs_Real_Hedge_EMSOrders | CopyFromLake | LP execution timestamps (EMS Async order log) |
| Dim_Position | DWH_dbo | Position attributes (open/close times, CID, IsSettled) |
| Dealing_Daily_Slippage_Positions | Dealing_dbo | SlippageInDollar for compensation input |
| PriceLog_History_CurrencyPrice | CopyFromLake | LP price ticks (Kusto time/rate) |
| Dim_Instrument | DWH_dbo | Instrument metadata |
| External_CalendarDB_Market_MergedDailySchedules | Dealing_staging | Exchange open/close times for market hours flags |

### Downstream Tables

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_Best_Execution_Compensation_CBH | Dealing_dbo | CBH compensation output — reads this table |
| Dealing_Best_Execution_Compensation_HBC | Dealing_dbo | HBC compensation output — reads this table |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Latency_Report |
| **Author** | Eden Liberman (2018-04-12); Adar Cahlon (extensive updates 2021–2024) |
| **ETL Pattern** | DELETE WHERE Date=@StartDate + INSERT DISTINCT |
| **Schedule** | SB_Daily (P0) — **APPEARS DECOMMISSIONED** (last data 2025-01-11) |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE Date = @StartDate` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **⚠️ Outdated data** | Maximum date is 2025-01-11. Do not use for current operational monitoring without confirming SP is active. |
| **Latency in ms** | All latency columns (ClientToDbLatency, etc.) are in milliseconds as int. Rows here exceeded the 1000ms threshold. |
| **CBH vs HBC** | HedgingType column separates the two LP routing modes. Use in conjunction with downstream CBH/HBC compensation tables. |
| **Market hours flags** | First-5/7-minute flags identify high-slippage open-auction executions — important context for compensation decisions. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / Best Execution |
| **Sub-domain** | Execution latency — compensation eligibility |
| **Sensitivity** | Customer identifiers (CID) + position data |
| **Quality Score** | 7.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
