# Compare — `Dealing_dbo.Dealing_Apex_PnL_Daily`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.25; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.0 | 8.25 | 1.25 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 21 | 21 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 21 | 21 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 8 |
| data_evidence | 6 | 6 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 5 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `13` | 0.137 | 2 | 2 | **Resolved instrument key**; **NULL** when Apex identifiers do not map to **`Dim_Instrument`**. (Tier 2 — SP_Apex_PnL) | eToro instrument key from `DWH_dbo.Dim_Instrument` resolved via two-pass Symbol/ISIN matching against Apex identifiers. NULL if no match found (delisted instruments, ADRs not in eToro universe). (Tier |
| `21` | 0.197 | 2 | 2 | **Daily zero PnL adjustment** for names **closed to zero on this day** (from **`Dealing_DailyZeroPnL_Stocks`** path in SP). (Tier 2 — SP_Apex_PnL) | Zero PnL adjustment from `Dealing_DailyZeroPnL_Stocks` for `Date = @Date` — captures PnL from positions fully closed to zero within the day. Joined via InstrumentID and AccountNumber→HedgeServerID map |
| `6` | 0.245 | 2 | 2 | **NOP at this day’s market close**, **Apex price**. (Tier 2 — SP_Apex_PnL) | Net open position at report date EOD, Apex closing price — closing mark for the daily bridge. From `LP_APEX_EXT982_3EU.MarketValue` at `@DateID`. NULL if the symbol has no open position at day end. (T |
| `4` | 0.338 | 2 | 2 | **NOP at prior business day EOD**, **Apex price** — **Monday rows use Friday** as prior business day. (Tier 2 — SP_Apex_PnL) | Net open position at prior business day EOD, valued at Apex's closing price — opening mark for the daily bridge. From `LP_APEX_EXT982_3EU.MarketValue` at `@PreviousDayID`. NULL if the symbol had no po |
| `8` | 0.339 | 2 | 2 | **Net trade notional for this day only** from Apex activity. (Tier 2 — SP_Apex_PnL) | Net traded notional for the day from Apex activity: `SUM(Quantity × Price + FeeSec + Fee5)`. Buys are positive, sells negative. Enters the PnL formula with a minus sign. NULL if no trades on this date |
| `5` | 0.35 | 2 | 2 | **Prior-day NOP** using **eToro DB** marks — pairs with `NOP_Start` for mark reconciliation. (Tier 2 — SP_Apex_PnL) | NOP at prior business day EOD using eToro internal DB bid price × quantity — pairs with Apex NOP_Start for mark-to-market reconciliation. Computed as `TradeQuantity_Start × Price_Start_DB`. NULL if no |
| `7` | 0.377 | 2 | 2 | **Same-day NOP** using **eToro DB** bid × qty. (Tier 2 — SP_Apex_PnL) | NOP at report date EOD using eToro DB bid × quantity — internal mark at the same point as `NOP_End`. Computed as `TradeQuantity_End × Price_End_DB`. NULL if no position or no DB price. (Tier 2 — SP_Ap |
| `16` | 0.384 | 2 | 2 | **eToro DB bid** at prior business day. (Tier 2 — SP_Apex_PnL) | eToro DB bid at prior business day EOD — supports price-level reconciliation alongside `Price_Start`. From `PriceLog_History_CurrencyPrice.Bid` (GBX/100 adjusted for SellCurrencyID=666). NULL if no DB |
| `1` | 0.388 | 2 | 2 | **Business date** for the row — **one trading day** per **`AccountNumber` + `Symbol`**; not necessarily a Saturday (unlike WTD header date semantics). (Tier 2 — SP_Apex_PnL) | Report date for this daily PnL row — the business date for which the day-over-day bridge is computed. Set to `@Date` parameter passed to SP_Apex_PnL. (Tier 2 — SP_Apex_PnL) |
| `17` | 0.391 | 2 | 2 | **Apex close** on **`Date`**. (Tier 2 — SP_Apex_PnL) | Apex closing price at report date EOD. From `LP_APEX_EXT982_3EU.ClosingPrice` at `@DateID`, CAST to decimal(16,6). NULL if no position at report date. (Tier 2 — SP_Apex_PnL) |

## Top issues — regen wiki (per judge)

- [low] `AccountNumber (element #2)` — AccountNumber has exactly 5 distinct values (3EU05026, 3EU05025, 3EU05027, 3EU00101, 3EU05028) hardcoded in SP but element description only lists 2 examples. Per completeness rules, columns with ≤15 values should list all values inline with their HedgeServerID mapping.
- [low] `Footer / Shape` — No explicit Phase Gate Checklist section documenting which verification phases (P1/P2/P3) were completed. Footer lacks phases-completed list.
- [low] `InstrumentDisplayName (element #14)` — Borderline tier attribution — InstrumentDisplayName is a dim-lookup passthrough from DWH_dbo.Dim_Instrument once InstrumentID is resolved. Source attribution says SP_Apex_PnL but could reference Dim_Instrument's origin (etoro_Trade_InstrumentMetaData). Final tier remains Tier 2 either way.
- [low] `Dividends (Section 5.1 lineage)` — Lineage table does not mention that LP_APEX_EXT869_3EU joins to #Apex_Ins on Cusip (not Symbol), unlike Trades which joins on Symbol + ISIN + Cusip. This join-key distinction matters for debugging unmatched dividends.
- [low] `Volume (element #20)` — Description says SUM(ABS(Quantity × Price + fees)) but SP computes SUM(ABS(Quantity × Price + FeeSec + CASE Fee5)) — ABS wraps entire expression including conditional Fee5 handling. Functionally correct but slightly imprecise.
