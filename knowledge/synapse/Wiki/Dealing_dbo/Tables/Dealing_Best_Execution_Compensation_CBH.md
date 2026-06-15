# Dealing_dbo.Dealing_Best_Execution_Compensation_CBH

## 1. Overview

**Best-execution compensation candidates for CBH (Citi Brokerage Holdings) LP routing** — positions where slippage exceeded the 0.5% threshold, enriched with the actual LP market price at execution time (`LP_Rate`), the spread charged, the percentage difference between the client rate and LP rate (`Percent_Diff`), and the computed compensation amount (`Compensation`). Each row represents a single position action (open or close) that may be eligible for client compensation under eToro's best-execution policy.

> **⚠️ DATA CURRENCY WARNING**: Maximum data date is **2025-01-11** — approximately 14 months before documentation date. The entire Best Execution compensation pipeline (SP_Latency_Report → SP_Slippage_Report → SP_Best_Execution) appears to have been decommissioned or significantly disrupted around that date. Treat as potentially deprecated. Confirm with Dealing team before building new consumers.

**Row grain**: `Date` + `PositionID` + `ActionTypeID` (unique position action — open or close).

---

## 2. Business Context

`SP_Best_Execution` (Author: Adar Cahlon 2021-05-03, last change 2024-09-03) reads from two intermediate tables:
1. `Dealing_Daily_Slippage_Positions` — slippage data (filtered for `OverThreshold=1`)
2. `Dealing_Daily_Latency_Compensation` — positions with latency > 1 second and spread data

The SP then fetches the **actual LP market price** (`LP_Rate`) from `CopyFromLake.PriceLog_History_CurrencyPrice` at the precise execution timestamp (`FinalOccurred`), using EU-specific LP accounts for EU-exchange instruments.

**CBH specific**: Spread is computed from the CBH (Citi Brokerage Holdings) spreaded forex prices (`InitForex_AskSpreaded` / `EndForex_AskSpreaded` from `Dim_Position`).

**Compensation formula** (simplified): `Compensation = ABS(SlippageInDollar) × CASE WHEN within compensation policy THEN 1 ELSE 0 END`, subject to `Compensation_Limit`.

`FinalOccurred`: The best available price timestamp — uses the Kusto (LP tick) occurrence time when available, otherwise falls back to the position's own Occurred timestamp.

**Key business rules**:

- **Input filter**: Only `OverThreshold=1` rows from `Dealing_Daily_Slippage_Positions` (slippage ≥ 0.5%).
- **CBH vs HBC**: This table is CBH only — positions routed through Citi Brokerage Holdings. HBC equivalent is `Dealing_Best_Execution_Compensation_HBC`.
- **Compensation_Limit**: Cap on maximum compensation per position action.
- **DELETE-INSERT by date**.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 48 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~4,200,000 |
| **Max date** | **2025-01-11** — pipeline appears decommissioned |
| **Compensation distribution** | Mix of Compensation=0 and positive values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the compensation record. (Tier 2 -SP_Best_Execution, @Date) |
| 2 | PositionID | bigint | YES | Position identifier. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.PositionID) |
| 3 | CID | int | YES | Customer identifier. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.CID) |
| 4 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.InstrumentID) |
| 5 | InstrumentName | varchar(50) | YES | Short instrument name/ticker. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.InstrumentName) |
| 6 | InstrumentTypeID | int | YES | Numeric instrument type. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.InstrumentTypeID) |
| 7 | InstrumentType | varchar(50) | YES | Instrument type string. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.InstrumentType) |
| 8 | HedgeServerID | int | YES | Hedge server identifier. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.HedgeServerID) |
| 9 | MirrorID | int | YES | CopyPortfolio mirror relationship ID. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.MirrorID) |
| 10 | IsBuy | int | YES | Position direction: 1=buy, 0=sell. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.IsBuy) |
| 11 | OrigIsBuy | int | YES | Original requested direction. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.OrigIsBuy) |
| 12 | ExecutionAmountInUnits | decimal(16,8) | YES | Units on this specific action (split-adjusted). (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.ExecutionAmountInUnits) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Full position size in units (split-adjusted). (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.AmountInUnitsDecimal) |
| 14 | Occurred | datetime | YES | Position action execution timestamp. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.Occurred) |
| 15 | EndForexRate | decimal(16,8) | YES | Actual execution rate received (split-adjusted). (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.EndForexRate) |
| 16 | ConversionRate | decimal(16,8) | YES | FX conversion rate to USD. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.ConversionRate) |
| 17 | ActionTypeID | int | YES | Numeric action type. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.ActionTypeID) |
| 18 | ActionType | varchar(50) | YES | Action type string (Open, Manual Close, etc.). (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.ActionType) |
| 19 | IsOpen | int | YES | 1 if open action, 0 if close. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.IsOpen) |
| 20 | Bid | float | YES | LP bid price at execution time from the price tick log. (Tier 2 -SP_Best_Execution, CopyFromLake.PriceLog_History_CurrencyPrice.Bid) |
| 21 | Ask | float | YES | LP ask price at execution time from the price tick log. (Tier 2 -SP_Best_Execution, CopyFromLake.PriceLog_History_CurrencyPrice.Ask) |
| 22 | OccurredAtServer | datetime | YES | Server-side timestamp when the LP price was recorded. (Tier 2 -SP_Best_Execution, CopyFromLake.PriceLog_History_CurrencyPrice.OccurredAtServer) |
| 23 | StopRate | decimal(16,8) | YES | Stop loss rate. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.StopRate) |
| 24 | LimitRate | decimal(16,8) | YES | Take profit rate. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.LimitRate) |
| 25 | ClientViewRate | numeric(16,8) | YES | Price shown to client in UI. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.ClientViewRate) |
| 26 | CustomerChosenRate | decimal(16,8) | YES | Rate at which client's order was accepted. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.CustomerChosenRate) |
| 27 | SlippageInDollar | money | YES | Monetary slippage in USD. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.SlippageInDollar) |
| 28 | slippage % | decimal(38,21) | YES | Slippage as percentage of CustomerChosenRate. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.slippage %) |
| 29 | RequestTime | datetime | YES | Client request timestamp. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.RequestTime) |
| 30 | OverThreshold | tinyint | YES | Always 1 in this table (filtered from Slippage at source). (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.OverThreshold) |
| 31 | OpenSession | int | YES | Market session at execution time. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.OpenSession) |
| 32 | Volume | int | YES | Trading volume for the action. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.Volume) |
| 33 | Regulation | varchar(50) | YES | Customer regulatory jurisdiction. (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.Regulation) |
| 34 | PriceRateID | bigint | YES | Price rate lookup ID from Dim_Position (OpenForexPriceRateID or EndForexPriceRateID). (Tier 2 -SP_Best_Execution, DWH_dbo.Dim_Position.InitForexPriceRateID / EndForexPriceRateID) |
| 35 | FinalOccurred | datetime | YES | Best available price timestamp: Kusto price occurrence when available, else Occurred. (Tier 2 -SP_Best_Execution, COALESCE(PriceOccurred, Occurred)) |
| 36 | HedgingMode | varchar(10) | YES | Hedging mode (CBH for this table). (Tier 2 -SP_Best_Execution, Dealing_Daily_Slippage_Positions.HedgingMode) |
| 37 | LiquidityAccountID | int | YES | LP account that priced/executed the hedge for CBH positions. (Tier 2 -SP_Best_Execution, Dealing_Daily_Latency_Compensation.LiquidityAccountID) |
| 38 | LiquidityAccountName | varchar(50) | YES | LP account display name. (Tier 2 -SP_Best_Execution, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountName) |
| 39 | Spread | decimal(16,6) | YES | Bid-ask spread for CBH: computed from InitForex/EndForex AskSpreaded vs Rate. (Tier 2 -SP_Best_Execution, DWH_dbo.Dim_Position CBH spread formula) |
| 40 | LP_Rate | float | YES | Actual LP market price at FinalOccurred (Bid for buy close/sell open, Ask for buy open/sell close). (Tier 2 -SP_Best_Execution, CopyFromLake.PriceLog_History_CurrencyPrice.Bid / Ask) |
| 41 | Percent_Diff | float | YES | Percentage difference between CustomerChosenRate and LP_Rate. (Tier 2 -SP_Best_Execution, computed: (CustomerChosenRate - LP_Rate) / LP_Rate) |
| 42 | Compensation_Limit | decimal(16,6) | YES | Maximum compensation cap for this position action (policy-based). (Tier 2 -SP_Best_Execution, compensation policy logic) |
| 43 | Compensation | decimal(16,6) | YES | Computed compensation amount in USD owed to the client. 0 if within policy; positive if compensation due. (Tier 2 -SP_Best_Execution, computed: MIN(ABS(SlippageInDollar), Compensation_Limit) under policy conditions) |
| 44 | UpdateDate | datetime | NOT NULL | Batch execution timestamp (GETDATE()). (Tier 3 -SP_Best_Execution, GETDATE()) |
| 45 | RequestOccurred | datetime | YES | Original client request timestamp (from Dim_Position). (Tier 2 -SP_Best_Execution, DWH_dbo.Dim_Position.RequestOpenOccurred / RequestCloseOccurred) |
| 46 | OpenMarketTime | datetime | YES | Exchange market open time on the report date. (Tier 2 -SP_Best_Execution, Dealing_staging.External_CalendarDB_Market_MergedDailySchedules) |
| 47 | WithinFirst5Minutes_MarketHours | bit | YES | 1 if action occurred within 5 minutes of market open. (Tier 2 -SP_Best_Execution, computed) |
| 48 | WithinFirst7Minutes_MarketHours | bit | YES | 1 if action occurred within 7 minutes of market open. (Tier 2 -SP_Best_Execution, computed) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| Dealing_Daily_Slippage_Positions | Dealing_dbo | Primary input (OverThreshold=1 rows) |
| Dealing_Daily_Latency_Compensation | Dealing_dbo | Latency data and LiquidityAccountID for CBH positions |
| PriceLog_History_CurrencyPrice | CopyFromLake | Actual LP price at FinalOccurred (Bid/Ask/OccurredAtServer) |
| Dim_Position | DWH_dbo | PriceRateID, RequestOccurred, split ratios |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LiquidityAccountName |
| External_CalendarDB_Market_MergedDailySchedules | Dealing_staging | Market open times |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Best_Execution (writes BOTH Dealing_Best_Execution_Compensation_CBH AND _HBC) |
| **Author** | Adar Cahlon (2021-05-03); last change 2024-09-03 |
| **ETL Pattern** | DELETE WHERE Date=@Date + INSERT DISTINCT |
| **Schedule** | SB_Daily (P20) — **APPEARS DECOMMISSIONED** (last data 2025-01-11) |
| **Parameter** | @Date (DATE) |
| **Dependencies** | Requires Dealing_Daily_Latency_Compensation (SP_Latency_Report P0) + Dealing_Daily_Slippage_Positions (SP_Slippage_Report P20) |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **⚠️ Outdated data** | Maximum date is 2025-01-11. Do not use for current operational monitoring without confirming SP is active. |
| **Compensation=0** | Many rows will have Compensation=0 — these are over-threshold on slippage but within LP rate policy bounds. |
| **CBH vs HBC** | This table is CBH only. For HBC, use `Dealing_Best_Execution_Compensation_HBC` (identical structure, different LP routing). |
| **Percent_Diff** | Difference between CustomerChosenRate and LP_Rate — not the same as slippage %. Shows how much better/worse the client got vs LP fair value. |
| **FinalOccurred** | Use `FinalOccurred` rather than `Occurred` for matching against external price sources. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / Best Execution |
| **Sub-domain** | CBH compensation — slippage remediation |
| **Sensitivity** | Customer identifiers (CID) + position + compensation amounts |
| **Quality Score** | 7.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
