# Dealing_dbo.Dealing_Best_Execution_Compensation_HBC

## 1. Overview

**Best-execution compensation candidates for HBC (Hedge Broker Connection) LP routing** — structurally identical to `Dealing_Best_Execution_Compensation_CBH` but scoped to positions routed through the HBC liquidity connection rather than CBH. The key difference is in the `Spread` calculation: HBC uses commission-based spread (`CommissionByUnits / (AmountInUnitsDecimal × ConversionRate) / 2`) instead of the CBH spreaded-forex-price approach. Both tables are written by the same `SP_Best_Execution` in a single run (HBC INSERT first, then CBH).

> **⚠️ DATA CURRENCY WARNING**: Maximum data date is **2025-01-11** — approximately 14 months before documentation date. The entire Best Execution compensation pipeline appears to have been decommissioned or significantly disrupted around that date. Treat as potentially deprecated. Confirm with Dealing team before building new consumers.

> **Note**: HBC has significantly fewer rows (~818K) than CBH (~4.2M) — reflecting that HBC routing was less commonly used or handled fewer over-threshold positions.

**Row grain**: `Date` + `PositionID` + `ActionTypeID` (unique position action — open or close).

---

## 2. Business Context

`SP_Best_Execution` (Author: Adar Cahlon 2021-05-03, last change 2024-09-03) writes both CBH and HBC tables from the same intermediate data in `#TotalData_HBC_WithMarketHours` and `#TotalData_CBH_WithMarketHours` temp tables respectively.

**HBC-specific logic**:
- **Spread**: `(CommissionByUnits / (AmountInUnitsDecimal × ConversionRate)) / 2` — derived from the commission charged rather than from spreaded forex price feeds (which are only available for CBH positions with `InitForex_AskSpreaded IS NOT NULL`).
- **LP_Rate**: Same Bid/Ask from `CopyFromLake.PriceLog_History_CurrencyPrice` at `FinalOccurred`.
- **LiquidityAccountID**: Sourced from `Dealing_Daily_Latency_Compensation` for HBC-routed positions (where `HedgingType = 'HBC'`).

All other business rules are identical to CBH — see `Dealing_Best_Execution_Compensation_CBH` documentation for the full compensation framework.

**Key business rules**:

- **Input filter**: Only `OverThreshold=1` rows (slippage ≥ 0.5%) from `Dealing_Daily_Slippage_Positions` where HBC routing.
- **DELETE-INSERT by date**: HBC INSERT executes before CBH INSERT in the SP.

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
| **Row count** | ~818,000 |
| **Max date** | **2025-01-11** — pipeline appears decommissioned |
| **vs CBH** | Approximately 5× fewer rows — HBC handled fewer over-threshold positions |

---

## 5. Elements

Identical column set to `Dealing_Best_Execution_Compensation_CBH`. The only semantic difference is in `Spread` (commission-based for HBC vs spreaded-price for CBH) and `HedgingMode` (always 'HBC' here).

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date. (Tier 2 -- SP_Best_Execution, @Date) |
| 2 | PositionID | bigint | YES | Position identifier. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.PositionID) |
| 3 | CID | int | YES | Customer identifier. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.CID) |
| 4 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.InstrumentID) |
| 5 | InstrumentName | varchar(50) | YES | Short instrument name. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.InstrumentName) |
| 6 | InstrumentTypeID | int | YES | Numeric instrument type. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.InstrumentTypeID) |
| 7 | InstrumentType | varchar(50) | YES | Instrument type string. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.InstrumentType) |
| 8 | HedgeServerID | int | YES | Hedge server identifier. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.HedgeServerID) |
| 9 | MirrorID | int | YES | CopyPortfolio mirror ID. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.MirrorID) |
| 10 | IsBuy | int | YES | Position direction: 1=buy, 0=sell. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.IsBuy) |
| 11 | OrigIsBuy | int | YES | Original requested direction. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.OrigIsBuy) |
| 12 | ExecutionAmountInUnits | decimal(16,8) | YES | Units on this action (split-adjusted). (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.ExecutionAmountInUnits) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Full position size in units (split-adjusted). (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.AmountInUnitsDecimal) |
| 14 | Occurred | datetime | YES | Position action execution timestamp. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.Occurred) |
| 15 | EndForexRate | decimal(16,8) | YES | Actual execution rate (split-adjusted). (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.EndForexRate) |
| 16 | ConversionRate | decimal(16,8) | YES | FX conversion rate to USD. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.ConversionRate) |
| 17 | ActionTypeID | int | YES | Numeric action type. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.ActionTypeID) |
| 18 | ActionType | varchar(50) | YES | Action type string. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.ActionType) |
| 19 | IsOpen | int | YES | 1=open action, 0=close. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.IsOpen) |
| 20 | Bid | float | YES | LP bid price at FinalOccurred. (Tier 2 -- SP_Best_Execution, CopyFromLake.PriceLog_History_CurrencyPrice.Bid) |
| 21 | Ask | float | YES | LP ask price at FinalOccurred. (Tier 2 -- SP_Best_Execution, CopyFromLake.PriceLog_History_CurrencyPrice.Ask) |
| 22 | OccurredAtServer | datetime | YES | Server-side price tick timestamp. (Tier 2 -- SP_Best_Execution, CopyFromLake.PriceLog_History_CurrencyPrice.OccurredAtServer) |
| 23 | StopRate | decimal(16,8) | YES | Stop loss rate. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.StopRate) |
| 24 | LimitRate | decimal(16,8) | YES | Take profit rate. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.LimitRate) |
| 25 | ClientViewRate | numeric(16,8) | YES | Price shown to client in UI. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.ClientViewRate) |
| 26 | CustomerChosenRate | decimal(16,8) | YES | Rate at which client's order was accepted. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.CustomerChosenRate) |
| 27 | SlippageInDollar | money | YES | Monetary slippage in USD. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.SlippageInDollar) |
| 28 | slippage % | decimal(38,21) | YES | Slippage percentage. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.slippage %) |
| 29 | RequestTime | datetime | YES | Client request timestamp. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.RequestTime) |
| 30 | OverThreshold | tinyint | YES | Always 1 in this table. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.OverThreshold) |
| 31 | OpenSession | int | YES | Market session at execution. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.OpenSession) |
| 32 | Volume | int | YES | Trading volume. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.Volume) |
| 33 | Regulation | varchar(50) | YES | Customer regulatory jurisdiction. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.Regulation) |
| 34 | PriceRateID | bigint | YES | Price rate lookup ID from Dim_Position. (Tier 2 -- SP_Best_Execution, DWH_dbo.Dim_Position.InitForexPriceRateID / EndForexPriceRateID) |
| 35 | FinalOccurred | datetime | YES | Best available price timestamp (Kusto time or Occurred fallback). (Tier 2 -- SP_Best_Execution, COALESCE(PriceOccurred, Occurred)) |
| 36 | HedgingMode | varchar(10) | YES | Always 'HBC' for rows in this table. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Slippage_Positions.HedgingMode) |
| 37 | LiquidityAccountID | int | YES | LP account for HBC routing. (Tier 2 -- SP_Best_Execution, Dealing_Daily_Latency_Compensation.LiquidityAccountID) |
| 38 | LiquidityAccountName | varchar(50) | YES | LP account display name. (Tier 2 -- SP_Best_Execution, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountName) |
| 39 | Spread | decimal(16,6) | YES | **HBC-specific**: Commission-based spread = (CommissionByUnits / (AmountInUnitsDecimal × ConversionRate)) / 2. (Tier 2 -- SP_Best_Execution, DWH_dbo.Dim_Position.CommissionByUnits / CommissionOnClose) |
| 40 | LP_Rate | float | YES | Actual LP market price at FinalOccurred (Bid for buys-close/sells-open, Ask for buys-open/sells-close). (Tier 2 -- SP_Best_Execution, CopyFromLake.PriceLog_History_CurrencyPrice.Bid / Ask) |
| 41 | Percent_Diff | float | YES | Percentage difference: (CustomerChosenRate − LP_Rate) / LP_Rate. (Tier 2 -- SP_Best_Execution, computed) |
| 42 | Compensation_Limit | decimal(16,6) | YES | Maximum compensation cap for this position action. (Tier 2 -- SP_Best_Execution, compensation policy) |
| 43 | Compensation | decimal(16,6) | YES | Computed compensation amount in USD. 0 if within policy bounds. (Tier 2 -- SP_Best_Execution, computed) |
| 44 | UpdateDate | datetime | NOT NULL | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_Best_Execution, GETDATE()) |
| 45 | RequestOccurred | datetime | YES | Original client request timestamp. (Tier 2 -- SP_Best_Execution, DWH_dbo.Dim_Position.RequestOpenOccurred / RequestCloseOccurred) |
| 46 | OpenMarketTime | datetime | YES | Exchange market open time. (Tier 2 -- SP_Best_Execution, Dealing_staging.External_CalendarDB_Market_MergedDailySchedules) |
| 47 | WithinFirst5Minutes_MarketHours | bit | YES | 1 if within 5 minutes of market open. (Tier 2 -- SP_Best_Execution, computed) |
| 48 | WithinFirst7Minutes_MarketHours | bit | YES | 1 if within 7 minutes of market open. (Tier 2 -- SP_Best_Execution, computed) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| Dealing_Daily_Slippage_Positions | Dealing_dbo | Primary input (OverThreshold=1 HBC rows) |
| Dealing_Daily_Latency_Compensation | Dealing_dbo | LiquidityAccountID for HBC positions |
| PriceLog_History_CurrencyPrice | CopyFromLake | Actual LP price at FinalOccurred |
| Dim_Position | DWH_dbo | CommissionByUnits/CommissionOnClose for HBC spread, PriceRateID |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LiquidityAccountName |
| External_CalendarDB_Market_MergedDailySchedules | Dealing_staging | Market open times |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Best_Execution (writes BOTH Dealing_Best_Execution_Compensation_HBC AND _CBH; HBC is written first) |
| **Author** | Adar Cahlon (2021-05-03); last change 2024-09-03 |
| **ETL Pattern** | DELETE WHERE Date=@Date + INSERT DISTINCT |
| **Schedule** | SB_Daily (P20) — **APPEARS DECOMMISSIONED** (last data 2025-01-11) |
| **Parameter** | @Date (DATE) |
| **Dependencies** | Requires Dealing_Daily_Latency_Compensation + Dealing_Daily_Slippage_Positions |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **⚠️ Outdated data** | Maximum date is 2025-01-11. |
| **HBC spread vs CBH** | For HBC, `Spread` = commission/2 (not from forex spread prices). This reflects eToro's markup differently from CBH. |
| **Much smaller than CBH** | ~818K vs ~4.2M rows — HBC routing was less prevalent for over-threshold slippage. |
| **Identical structure to CBH** | Both tables share the exact same DDL — use `HedgingMode` to confirm all rows are 'HBC' when querying. |
| **For combined analysis** | UNION ALL with CBH table to get full best-execution compensation picture across both LP types. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / Best Execution |
| **Sub-domain** | HBC compensation — slippage remediation |
| **Sensitivity** | Customer identifiers (CID) + position + compensation amounts |
| **Quality Score** | 7.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
