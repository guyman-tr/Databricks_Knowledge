# Dealing_dbo.Dealing_Duco_ActivityRecon

## 1. Overview

**Daily trade activity reconciliation** between eToro's LP (liquidity provider) hedge executions and client trade activity. Each row compares what was executed on the hedge server side (from the execution log) against what client positions were opened or closed that day, aggregated by liquidity account and instrument. Together with `Dealing_Duco_EODRecon` (holdings), this table forms the two-part Duco reconciliation suite that all LP-specific recon pipelines consume.

**Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `Buy/Sell` direction.

---

## 2. Business Context

`SP_DataForDuco` (Author: Jenia 2021-10-25, many updates through 2025-08-07) writes both this table and `Dealing_Duco_EODRecon` in a single run. The SP does not run on weekends.

**Activity reconciliation logic**: The SP performs a **FULL OUTER JOIN** between eToro's hedge execution log (`CopyFromLake.etoro_Hedge_ExecutionLog`) and client position changes from `BI_DB_dbo.BI_DB_PositionPnL` for the report date. The execution log captures LP trade fills; the client side aggregates open/close actions on positions.

**Rate comparison**: Unlike `EODRecon` which uses a single `eToroRate` (weighted average holding rate), `ActivityRecon` has separate `eToro_AvgRate` (LP execution weighted average) and `Client_AvgRate` (client execution weighted average) — enabling spread/markup analysis.

**Buy/Sell direction** is derived from the net units direction (positive = Buy, negative = Sell).

**Key business rules**:

- **Weekends excluded**: SP skips Sat/Sun — no data is generated for those dates.
- **eToro side**: `etoro_Hedge_ExecutionLog` filtered to `@Date` — captures intraday LP fills.
- **Client side**: `BI_DB_PositionPnL` open/close counts for `DateID = @DateID`.
- **No MKTcap/HedgingPercent/CUSIP**: Unlike EODRecon, this table focuses on trade matching rather than holdings comparison.
- **DELETE-INSERT by date**: Idempotent daily reload.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 25 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~17,400,000 |
| **Date range** | Active and current (daily refresh confirmed, weekdays only) |
| **Recent sample** | Rows for 2026-03-20 with multiple LiquidityAccountID values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date (trade activity reconciliation date). (Tier 2 -SP_DataForDuco, @Date) |
| 2 | LiquidityAccountID | int | YES | LP account identifier. (Tier 2 -SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountID) |
| 3 | LiquidityAccountName | varchar(max) | YES | LP account display name. (Tier 2 -SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountName) |
| 4 | HedgeServerID | int | YES | Hedge server associated with the LP execution. (Tier 2 -SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.HedgeServerID) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.InstrumentID) |
| 6 | ISINCode | varchar(max) | YES | ISIN code from instrument master. (Tier 2 -SP_DataForDuco, DWH_dbo.Dim_Instrument.ISINCode) |
| 7 | InstrumentDisplayName | varchar(max) | YES | Instrument display name. (Tier 2 -SP_DataForDuco, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 8 | Buy/Sell | varchar(10) | YES | Direction: 'Buy' or 'Sell', derived from net units sign. (Tier 2 -SP_DataForDuco, computed from sign of eToro_Units / ClientUnits) |
| 9 | eToro_Units | float | YES | Total LP units executed on the hedge server for the date. (Tier 2 -SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Units) |
| 10 | ClientUnits | float | YES | Total client position units opened/closed on the date. (Tier 2 -SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 11 | eToroLocalAmount | money | YES | LP execution value in local instrument currency. (Tier 2 -SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Amount) |
| 12 | eToroUSDAmount | money | YES | LP execution value converted to USD. (Tier 2 -SP_DataForDuco, computed: eToroLocalAmount × FXratetoUSD) |
| 13 | ClientAmount | money | YES | Client activity value in USD. (Tier 2 -SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion) |
| 14 | eToro_AvgRate | float | YES | Weighted average execution rate on the LP/hedge side. (Tier 2 -SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Rate weighted avg) |
| 15 | Client_AvgRate | float | YES | Weighted average execution rate on the client side. (Tier 2 -SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL rate weighted avg) |
| 16 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -SP_DataForDuco, GETDATE()) |
| 17 | Symbol | varchar(50) | YES | Instrument ticker symbol. (Tier 2 -SP_DataForDuco, DWH_dbo.Dim_Instrument.Symbol) |
| 18 | SellCurrency | varchar(10) | YES | Trade currency of the instrument. (Tier 2 -SP_DataForDuco, DWH_dbo.Dim_Instrument.SellCurrency) |
| 19 | Exchange | varchar(max) | YES | Exchange name for the instrument. (Tier 2 -SP_DataForDuco, DWH_dbo.Dim_Instrument.Exchange) |
| 20 | Clients_Units_Buy | float | YES | Client trade units on the buy side. (Tier 2 -SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=1) |
| 21 | Clients_Units_Sell | float | YES | Client trade units on the sell side. (Tier 2 -SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=0) |
| 22 | Clients_NOP_Buy | float | YES | Client buy-side activity value in USD. (Tier 2 -SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP buy) |
| 23 | Clients_NOP_Sell | float | YES | Client sell-side activity value in USD. (Tier 2 -SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP sell) |
| 24 | FXratetoUSD | float | YES | FX rate from instrument currency to USD. (Tier 2 -SP_DataForDuco, DWH_dbo.Fact_CurrencyPriceWithSplit) |
| 25 | CUSIP | varchar(max) | YES | CUSIP identifier from LP execution log or external source. (Tier 2 -SP_DataForDuco, external source / LP execution log) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| etoro_Hedge_ExecutionLog | CopyFromLake | LP trade execution records for the report date |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LP account name lookup |
| etoro_Hedge_GetHedgeServerAccountMapping | CopyFromLake | Hedge server → LP account mapping |
| BI_DB_PositionPnL | BI_DB_dbo | Client open/close activity (AmountInUnitsDecimal, IsBuy) |
| Fact_CurrencyPriceWithSplit | DWH_dbo | FX rate for USD conversion |
| Dim_Instrument | DWH_dbo | Instrument metadata (ISIN, Symbol, Exchange, SellCurrency) |

### Downstream Tables (partial — 10+ recon tables)

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_ApexRecon_TradeActivity | Dealing_dbo | Apex trade recon |
| Dealing_ApexRecon_Hedging | Dealing_dbo | Apex hedging recon |
| Dealing_GSReconTrades | Dealing_dbo | Goldman Sachs trade recon |
| Dealing_IBRecon_Trades | Dealing_dbo | Interactive Brokers trade recon |
| Dealing_IGReconTrades | Dealing_dbo | IG trade recon |
| Dealing_SAXORecon_Trades | Dealing_dbo | SAXO trade recon |
| Dealing_VisionRecon_Trades | Dealing_dbo | Vision trade recon |
| Dealing_BNY_VIRTU_ReconTrades | Dealing_dbo | BNY VIRTU trade recon |
| Dealing_JPMRecon* | Dealing_dbo | JPMorgan recon |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DataForDuco (writes BOTH Dealing_Duco_EODRecon AND Dealing_Duco_ActivityRecon) |
| **Author** | Jenia (2021-10-25); many updates through 2025-08-07 |
| **ETL Pattern** | DELETE WHERE Date=@Date + INSERT |
| **Schedule** | Daily — SB_Daily (P0); skips weekends |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE Date = @Date` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Weekend gaps** | No data for Saturday/Sunday — expected behavior. |
| **Rate comparison** | `eToro_AvgRate` vs `Client_AvgRate` reveals spread/markup captured by eToro on trade routing. |
| **FULL OUTER JOIN artifact** | NULL on either side means no match — LP traded but no client activity, or vice versa. |
| **vs EODRecon** | This captures daily activity (flows); `Dealing_Duco_EODRecon` captures end-of-day holdings (stocks). |
| **Downstream dependency** | Used by 10+ LP-specific recon SPs — runs first in each broker reconciliation pipeline. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / LP Reconciliation |
| **Sub-domain** | Daily trade activity reconciliation |
| **Sensitivity** | Aggregated LP execution data (no individual customer data) |
| **Quality Score** | 8.5 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
