# Dealing_dbo.Dealing_DailyZeroPnL_Stocks

## 1. Overview

**Daily eToro revenue (Zero P&L) aggregated by instrument** for stocks and ETFs. Each row represents one combination of date, hedge server, instrument, leverage tier, CFD flag, regulation, MiFID category, trading mode (IsManual), and stock index membership. Realized Zero comes from positions closed on the report date; Unrealized Zero reflects the mark-to-market P&L on open positions. The table is a foundational feed for downstream Dealing revenue analytics, Apex P&L reconciliation, credit risk, and hedge cost calculations.

**Row grain**: `Date` + `HedgeServerID` + `InstrumentID` + `Industry` + `InstrumentType` + `IsManual` + `Leverage` + `IsCFD` + `Regulation` + `MifID`.

---

## 2. Business Context

`SP_DailyZeroPnL_Stocks` (Author: Amir Gurewitz 2020-06-09, migrated to Synapse by Gal in Jan 2024) calculates the daily Zero P&L for `InstrumentTypeID IN (5, 6)` (Stocks and ETFs).

**Realized Zero** is computed for positions with `CloseDateID = @RepDate`: NetProfit + CommissionOnClose − PreviousDayPnL (standard eToro zero formula).

**Unrealized Zero** (ChangeInUnrealizedZero) is computed for open positions as DailyPnL + commission adjustment: captures intraday P&L movement for positions still open at EOD.

**NOP** (Net Open Position) is aggregated as `SUM(ABS(NOP_in_USD))` using the (2*IsBuy-1) sign convention, with FX conversion via `Fact_CurrencyPriceWithSplit`.

**StockIndex** mapping comes from `BI_DB_dbo.BI_DB_IndexesMapping_Static` to classify instruments into index groups (e.g., S&P500, NASDAQ).

**Key business rules**:

- **InstrumentTypeID filter**: Only Stocks (5) and ETFs (6) — FX/crypto excluded.
- **DELETE-INSERT by date**: Idempotent daily reload.
- **MifID and Regulation** from `Fact_SnapshotCustomer` for the report date — used by compliance/reporting consumers.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 26 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~275,000,000 |
| **Date range** | Active and current (daily refresh confirmed) |
| **Recent sample** | Rows for 2026-03-20 with mixed Regulation values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the zero P&L snapshot. (Tier 2 -- SP_DailyZeroPnL_Stocks, @RepDate) |
| 2 | HedgeServerID | int | YES | Hedge server identifier for the position set. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.HedgeServerID) |
| 3 | Industry | varchar(250) | YES | Industry classification of the instrument (from Dim_Instrument). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Industry) |
| 4 | InstrumentType | varchar(50) | YES | Instrument type string (Stock / ETF). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentType) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentID) |
| 6 | InstrumentDisplayName | varchar(250) | YES | Display name of the instrument. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 7 | StockIndex | varchar(50) | YES | Index membership (e.g., S&P500, NASDAQ) from the static mapping table; NULL if not in any index. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_IndexesMapping_Static.IndexName) |
| 8 | IsManual | tinyint | YES | Flag indicating manual (non-automated) trading positions. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.IsManual) |
| 9 | Leverage | int | YES | Position leverage tier. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.Leverage) |
| 10 | IsCFD | tinyint | YES | 1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.IsSettled / HedgeServerID) |
| 11 | Regulation | varchar(50) | YES | Regulatory jurisdiction of the customer (e.g., ASIC, FCA, CySEC). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Regulation.Name) |
| 12 | MifID | int | YES | MiFID categorization ID of the customer snapshot. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Fact_SnapshotCustomer.MifidCategorizationID) |
| 13 | RealizedCommission | money | YES | Aggregate commission charged on positions closed on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.CommissionOnClose) |
| 14 | RealizedZero | money | YES | Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.DailyPnL / NetProfit / CommissionOnClose) |
| 15 | ChangeInUnrealizedZero | money | YES | Change in unrealized eToro revenue for still-open positions: SUM(DailyPnL + commission adjustment). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.DailyPnL) |
| 16 | TotalZero | money | YES | RealizedZero + ChangeInUnrealizedZero for the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, computed) |
| 17 | NOP | money | YES | Net Open Position in USD for open positions in the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion) |
| 18 | OpenPositions | money | YES | Count of open positions in the group (as money type). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL) |
| 19 | NOP_Units | numeric(38,6) | YES | Net open position in instrument units (signed: positive=long, negative=short). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal with sign) |
| 20 | VolumeOnOpen | bigint | YES | Cumulative open-action volume for positions opened on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.VolumeOnOpen) |
| 21 | VolumeOnClose | bigint | YES | Cumulative close-action volume for positions closed on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.VolumeOnClose) |
| 22 | OpenPositionValue | money | YES | Aggregated USD value of open positions (units × price). (Tier 2 -- SP_DailyZeroPnL_Stocks, computed from NOP and FX rate) |
| 23 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE()) |
| 24 | InstrumentName | varchar(100) | YES | Short instrument name/ticker symbol. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Name) |
| 25 | Units | decimal(16,6) | YES | Net units held across the group's open positions. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 26 | Currency | varchar(50) | YES | Trade currency of the instrument (SellCurrency). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.SellCurrency) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary position P&L fact (NOP, DailyPnL, CommissionOnClose, IsSettled) |
| Dim_Position | DWH_dbo | Position attributes (OpenDateID, CloseDateID, HedgeServerID, Leverage) |
| Fact_SnapshotCustomer | DWH_dbo | Customer regulation and MiFID snapshot for report date |
| Dim_Range | DWH_dbo | Snapshot date range lookup |
| Dim_Instrument | DWH_dbo | Instrument metadata (InstrumentType, Industry, SellCurrency) |
| Dim_Regulation | DWH_dbo | Regulation name lookup |
| Fact_CurrencyPriceWithSplit | DWH_dbo | FX rate for NOP USD conversion |
| BI_DB_IndexesMapping_Static | BI_DB_dbo | Stock index membership mapping |

### Downstream Tables

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_Apex_PnL | Dealing_dbo | Apex P&L report — depends on this table |
| Dealing_Apex_PnL_Daily | Dealing_dbo | Daily Apex P&L |
| Dealing_Apex_PnL_EE / EE_Daily | Dealing_dbo | eToro Europe variant |
| Dealing_CFDs_Stocks_Credit_Risk | Dealing_dbo | CFD stock credit risk |
| Dealing_HedgeCost | Dealing_dbo | Hedge cost calculation |
| Dealing_Manual_Exec_Trade / Summary | Dealing_dbo | Manual execution trade analytics |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DailyZeroPnL_Stocks |
| **Author** | Amir Gurewitz (2020-06-09); Synapse migration by Gal (2024-01) |
| **ETL Pattern** | DELETE WHERE Date=@dd + INSERT |
| **Schedule** | Daily — SB_Daily (P0) |
| **Parameter** | @dd (DATE) — the report date |
| **Delete Scope** | `DELETE WHERE Date = @dd` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Clustered index** | Filter on `Date` first for optimal performance. |
| **CFD vs Real** | Use `IsCFD` flag to split; Real = `IsSettled=1` or `HedgeServerID IN (3,9,102,112,125,126,81)`. |
| **NOP sign** | `NOP_Units` is signed (positive=long, negative=short). `NOP` is absolute USD value. |
| **Zero formula** | RealizedZero = NetProfit + CommissionOnClose − PreviousDayPnL (standard eToro Zero definition). |
| **Downstream** | Several Dealing_dbo tables depend on this as a source — changes to filters here ripple broadly. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / Revenue Analytics |
| **Sub-domain** | Daily Zero P&L — Stocks & ETFs |
| **Sensitivity** | Aggregated (no individual customer data exposed) |
| **Quality Score** | 8.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
