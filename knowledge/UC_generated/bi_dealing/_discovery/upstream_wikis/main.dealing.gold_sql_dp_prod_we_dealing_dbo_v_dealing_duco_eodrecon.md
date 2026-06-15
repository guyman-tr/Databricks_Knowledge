# Dealing_dbo.Dealing_Duco_EODRecon

## 1. Overview

**Daily end-of-day reconciliation** between eToro's LP (liquidity provider) hedge holdings and client NOP (net open position). Each row compares what eToro's hedge servers hold at EOD for a given liquidity account and instrument versus what the aggregated client position demands, expressed in units and USD amounts. The table is the **primary foundation for all LP broker reconciliation pipelines** — 11+ downstream recon tables (Apex, GS, IB, IG, JPM, SAXO, VISION, BNY VIRTU, CloseOnly) depend on it.

**Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `Buy/Sell` direction.

---

## 2. Business Context

`SP_DataForDuco` (Author: Jenia 2021-10-25, many updates through 2025-08-07) is the shared writer for both `Dealing_Duco_EODRecon` (EOD holdings) and `Dealing_Duco_ActivityRecon` (trade activity). The SP does not run on weekends.

**EOD reconciliation logic**: The SP performs a **FULL OUTER JOIN** between eToro's hedge netting (LP holdings from `Dealing_staging.etoro_Hedge_Netting` + `etoro_History_Netting_History`) and client NOP (from `BI_DB_dbo.BI_DB_PositionPnL`), resolving the latest netting row per (server, instrument) via ROW_NUMBER dedup. The result shows the EOD hedge position vs the client position for each instrument.

**LP side sourcing**: Uses the SCD2 netting history table (`etoro_History_Netting_History` with SysStartTime/SysEndTime) unioned with current state (`etoro_Hedge_Netting`) — the combined set is deduplicated to the latest row per (HedgeServerID, InstrumentID).

**Client side sourcing**: `BI_DB_PositionPnL` aggregates client NOP using the (2*IsBuy-1) sign convention, joined to `Fact_CurrencyPriceWithSplit` for USD conversion.

**Key business rules**:

- **Weekends excluded**: SP skips Sat/Sun — no data is generated for those dates.
- **HedgingPercent**: `eToro_Units / ClientUnits` — the ratio showing how much of the client position is hedged.
- **MKTcap**: Market capitalization from an external reference, used by downstream to size reconciliation thresholds.
- **CUSIP**: US security identifier from the LP file, used for broker-side matching.
- **Buy/Sell direction** is derived from the net units direction (positive = Buy, negative = Sell).
- **DELETE-INSERT by date**: Idempotent daily reload.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 27 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~22,600,000 |
| **Date range** | Active and current (daily refresh confirmed, weekdays only) |
| **Recent sample** | Rows for 2026-03-20 with multiple LiquidityAccountID values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date (EOD reconciliation date). (Tier 2 -- SP_DataForDuco, @Date) |
| 2 | LiquidityAccountID | int | YES | LP account identifier from etoro_Trade_LiquidityAccounts. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountID) |
| 3 | LiquidityAccountName | varchar(max) | YES | LP account display name. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountName) |
| 4 | HedgeServerID | int | YES | Hedge server identifier associated with the LP position. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.HedgeServerID) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.InstrumentID) |
| 6 | ISINCode | varchar(max) | YES | ISIN code from LP netting or instrument master. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.ISINCode) |
| 7 | InstrumentDisplayName | varchar(max) | YES | Instrument display name. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 8 | Buy/Sell | varchar(10) | YES | Direction of the position: 'Buy' or 'Sell', derived from net units sign. (Tier 2 -- SP_DataForDuco, computed from eToro_Units / ClientUnits sign) |
| 9 | eToro_Units | float | YES | Total LP hedge units held at EOD on the eToro side. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Units) |
| 10 | ClientUnits | float | YES | Total client NOP units from BI_DB_PositionPnL for the instrument. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 11 | eToroLocalAmount | money | YES | LP hedge position value in the instrument's local currency. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Amount) |
| 12 | eToroUSDAmount | money | YES | LP hedge position value converted to USD via FXratetoUSD. (Tier 2 -- SP_DataForDuco, computed: eToroLocalAmount × FXratetoUSD) |
| 13 | ClientAmount | money | YES | Client NOP position value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion) |
| 14 | eToroRate | float | YES | Average rate of the eToro hedge holding (LP-side weighted average price). (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Rate) |
| 15 | HedgingPercent | float | YES | eToro_Units / ClientUnits — hedge coverage ratio (1.0 = fully hedged). (Tier 2 -- SP_DataForDuco, computed: eToro_Units / NULLIF(ClientUnits, 0)) |
| 16 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DataForDuco, GETDATE()) |
| 17 | Symbol | varchar(50) | YES | Instrument ticker symbol. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Symbol) |
| 18 | SellCurrency | varchar(10) | YES | Trade currency of the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.SellCurrency) |
| 19 | Exchange | varchar(max) | YES | Exchange name for the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Exchange) |
| 20 | MKTcap | decimal(24,6) | YES | Market capitalization of the instrument from external reference. (Tier 2 -- SP_DataForDuco, external reference table) |
| 21 | Clients_Units_Buy | float | YES | Client units on the buy side (long positions). (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=1) |
| 22 | Clients_Units_Sell | float | YES | Client units on the sell side (short positions). (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=0) |
| 23 | Clients_NOP_Buy | float | YES | Client NOP USD value for buy (long) positions. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP buy-side) |
| 24 | Clients_NOP_Sell | float | YES | Client NOP USD value for sell (short) positions. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP sell-side) |
| 25 | FXratetoUSD | float | YES | FX rate from instrument currency to USD for amount conversion. (Tier 2 -- SP_DataForDuco, DWH_dbo.Fact_CurrencyPriceWithSplit) |
| 26 | CUSIP | varchar(max) | YES | CUSIP identifier from the LP netting/external data source. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.CUSIP / external source) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| etoro_Hedge_Netting | Dealing_staging | Current LP netting state (EOD holdings) |
| etoro_History_Netting_History | Dealing_staging | Historical LP netting (SCD2, deduped to latest per server/instrument) |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LP account name lookup |
| BI_DB_PositionPnL | BI_DB_dbo | Client NOP aggregation (AmountInUnitsDecimal, IsBuy) |
| Fact_CurrencyPriceWithSplit | DWH_dbo | FX rate for USD conversion |
| Dim_Instrument | DWH_dbo | Instrument metadata (ISIN, Symbol, Exchange, SellCurrency) |
| etoro_Hedge_GetHedgeServerAccountMapping | CopyFromLake | Hedge server → LP account mapping |

### Downstream Tables (partial — 11+ recon tables)

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_ApexRecon_TradeActivity | Dealing_dbo | Apex trade recon (via SP_Apex_Recon) |
| Dealing_ApexRecon_Holdings | Dealing_dbo | Apex holdings recon |
| Dealing_ApexRecon_Hedging | Dealing_dbo | Apex hedging recon |
| Dealing_CloseOnly_Recon | Dealing_dbo | Close-only instrument monitoring |
| Dealing_GSRecon* | Dealing_dbo | Goldman Sachs reconciliation |
| Dealing_IBRecon* | Dealing_dbo | Interactive Brokers reconciliation |
| Dealing_IGRecon* | Dealing_dbo | IG reconciliation |
| Dealing_SAXORecon* | Dealing_dbo | SAXO reconciliation |
| Dealing_VisionRecon* | Dealing_dbo | Vision reconciliation |
| Dealing_BNY_VIRTU_Recon* | Dealing_dbo | BNY VIRTU reconciliation |
| Dealing_JPMRecon* | Dealing_dbo | JPMorgan reconciliation |

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
| **HedgingPercent** | Values > 1.0 indicate over-hedging; < 1.0 indicates under-hedging. NULL when ClientUnits = 0. |
| **Buy/Sell direction** | Derived from net units sign; not always equivalent to instrument IsBuy flag. |
| **Downstream dependency** | 11+ recon tables use this as input — it runs before all LP-specific recon SPs. |
| **FULL OUTER JOIN artifact** | Rows may have NULL on either side if LP holds position but no client NOP exists, or vice versa. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / LP Reconciliation |
| **Sub-domain** | EOD hedge vs client NOP reconciliation |
| **Sensitivity** | Aggregated LP position data (no individual customer data) |
| **Quality Score** | 8.5 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
