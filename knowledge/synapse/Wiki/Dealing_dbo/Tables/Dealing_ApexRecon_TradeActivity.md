# Dealing_dbo.Dealing_ApexRecon_TradeActivity

## 1. Overview

**Daily trade activity reconciliation between eToro and Apex Clearing** for real stocks. Each row compares eToro's trade execution units and average rate against Apex's reported trade activity for the same instrument, direction, and liquidity account on the given date. Discrepancies (Etoro_Units ≠ Apex_Units, Etoro_Rate ≠ Apex_Rate) trigger investigation. This is one of three Apex reconciliation tables written by `SP_Apex_Recon` (alongside `Dealing_ApexRecon_Holdings` and `Dealing_ApexRecon_Hedging`).

**Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `IsBuy` direction.

---

## 2. Business Context

`SP_Apex_Recon` (Author: Sarah Benchitrit 2021-03-07, many updates through 2025-09-29) writes all three Apex reconciliation tables in order: TradeActivity first, then Holdings, then Hedging (each downstream uses the previous). The SP runs daily and also has an additional intraday trigger via `SP_Run_Recon` at 12:00 UTC.

**eToro side**: Sourced from `Dealing_Duco_ActivityRecon` — eToro's own trade activity aggregation vs client positions.

**Apex side**: Sourced from `Dealing_staging.LP_APEX_EXT872_3EU_217314` — the Apex broker's trade file loaded via Fivetran. This file represents what Apex recorded as eToro's trading activity for the day.

**Daylight Savings handling**: Separate code paths for DST periods to correctly align Apex's midnight-cutoff with eToro's timestamps.

**LiquidityAccountID** is resolved from Fivetran's hedge server/LA mapping for Apex accounts.

**Key business rules**:

- **Dependencies**: Runs after `SP_DataForDuco` — requires `Dealing_Duco_ActivityRecon` and `Dealing_Duco_EODRecon` to be populated.
- **AccountNumber**: Apex's alphanumeric account identifier (e.g., `3EW35324` format) — used for broker-side matching.
- **No DELETE-INSERT per se**: SP uses its own replacement pattern — replaces data for @Date range.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 15 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~6,200,000 |
| **Date range** | Active and current (recent dates present) |
| **Recent sample** | Rows for 2026-03-20 with multiple LiquidityAccountID values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the trade activity reconciliation. (Tier 2 -SP_Apex_Recon, @Date) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -SP_Apex_Recon, Dealing_Duco_ActivityRecon.InstrumentID) |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. (Tier 2 -SP_Apex_Recon, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 4 | ISINCode | varchar(50) | YES | ISIN code for broker-side matching. (Tier 2 -SP_Apex_Recon, Dealing_Duco_ActivityRecon.ISINCode) |
| 5 | LiquidityAccountID | int | YES | Apex liquidity account identifier. (Tier 2 -SP_Apex_Recon, Fivetran hedge server/LA mapping) |
| 6 | IsBuy | int | YES | Trade direction: 1=buy, 0=sell. (Tier 2 -SP_Apex_Recon, derived from Buy/Sell column in ActivityRecon) |
| 7 | Etoro_Units | decimal(16,4) | YES | Total units traded on the eToro/LP side (from Duco ActivityRecon). (Tier 2 -SP_Apex_Recon, Dealing_Duco_ActivityRecon.eToro_Units) |
| 8 | Apex_Units | decimal(16,4) | YES | Total units reported by Apex for the same instrument/direction. (Tier 2 -SP_Apex_Recon, Dealing_staging.LP_APEX_EXT872_3EU_217314.Units) |
| 9 | Etoro_Rate | decimal(16,4) | YES | Weighted average execution rate on the eToro side. (Tier 2 -SP_Apex_Recon, Dealing_Duco_ActivityRecon.eToro_AvgRate) |
| 10 | Apex_Rate | decimal(16,4) | YES | Weighted average rate reported by Apex. (Tier 2 -SP_Apex_Recon, Dealing_staging.LP_APEX_EXT872_3EU_217314.Rate) |
| 11 | Etoro_Amount | decimal(16,4) | YES | Trade value on the eToro side in USD. (Tier 2 -SP_Apex_Recon, Dealing_Duco_ActivityRecon.eToroUSDAmount) |
| 12 | Apex_Amount | decimal(16,4) | YES | Trade value reported by Apex in USD. (Tier 2 -SP_Apex_Recon, Dealing_staging.LP_APEX_EXT872_3EU_217314.Amount) |
| 13 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -SP_Apex_Recon, GETDATE()) |
| 14 | HedgeServerID | int | YES | Hedge server associated with the Apex LP account. (Tier 2 -SP_Apex_Recon, Fivetran HS mapping) |
| 15 | AccountNumber | varchar(50) | YES | Apex account number (alphanumeric broker identifier, e.g., 3EW35324). (Tier 2 -SP_Apex_Recon, Dealing_staging.LP_APEX_EXT872_3EU_217314.AccountNumber) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| Dealing_Duco_ActivityRecon | Dealing_dbo | eToro side of the trade activity (must run first) |
| Dealing_Duco_EODRecon | Dealing_dbo | eToro EOD holdings (referenced for instrument/LA mapping) |
| LP_APEX_EXT872_3EU_217314 | Dealing_staging | Apex broker trade file (Fivetran-loaded) |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LP account name/ID lookup |

### Downstream Tables

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_ApexRecon_Holdings | Dealing_dbo | Written by same SP in same run (step 2 of 3) |
| Dealing_ApexRecon_Hedging | Dealing_dbo | Written by same SP in same run (step 3 of 3) |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Apex_Recon (writes TradeActivity + Holdings + Hedging in order) |
| **Author** | Sarah Benchitrit (2021-03-07); many updates through 2025-09-29 |
| **ETL Pattern** | Date-range replacement |
| **Schedule** | SB_Daily (P0); additional intraday via SP_Run_Recon at 12:00 UTC |
| **Parameter** | @Date (DATE) |
| **Dependencies** | Requires Dealing_Duco_ActivityRecon + Dealing_Duco_EODRecon (SP_DataForDuco) to complete first |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Reconciliation interpretation** | Etoro_Units = Apex_Units indicates matched; differences indicate breaks requiring investigation. |
| **AccountNumber format** | Alphanumeric 8-char (e.g., 3EW35324) — Apex clearing account ID. |
| **Intraday run** | SP_Run_Recon triggers this at 12:00 UTC in addition to the EOD daily run. Data may be refreshed mid-day. |
| **Three-table suite** | Always consider alongside Dealing_ApexRecon_Holdings (EOD positions) and Dealing_ApexRecon_Hedging (hedging reconciliation). |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / LP Reconciliation |
| **Sub-domain** | Apex Clearing trade activity recon |
| **Sensitivity** | Aggregated LP trade data (no individual customer data) |
| **Quality Score** | 8.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
