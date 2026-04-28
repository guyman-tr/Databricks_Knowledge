# Compare — `Dealing_dbo.Dealing_Apex_PnL`

**Bucket**: `median`

**Verdict**: **BETTER**  (score delta +2.85; slop 1 -> 1 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 6.15 | 9.0 | 2.85 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 1 | +0 |
| Element rows | 21 | 21 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 2 | +2 |
| T2 count | 21 | 19 | -2 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 6 | 10 |
| data_evidence | 6 | 9 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 7 | 9 |
| upstream_fidelity | 3 | 8 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `11` | 0.054 | 2 | 2 | **WTD PnL using eToro DB prices** on NOP start/end — compare to **`PnL`** to isolate **price-source** differences vs Apex. (Tier 2 — SP_Apex_PnL) | Weekly profit/loss using eToro internal DB prices instead of Apex closing prices. Formula: ISNULL(NOP_End_DBPrice,0) - ISNULL(NOP_Start_DBPrice,0) - ISNULL(Trades,0) + ISNULL(Dividends,0) + ISNULL(Add |
| `10` | 0.067 | 2 | 2 | **Week-to-date PnL using Apex prices:** `NOP_End - NOP_Start - Trades + Dividends + AdditionalFees` — primary “statement-side” PnL. (Tier 2 — SP_Apex_PnL) | Weekly profit/loss computed as: ISNULL(NOP_End,0) - ISNULL(NOP_Start,0) - ISNULL(Trades,0) + ISNULL(Dividends,0) + ISNULL(AdditionalFees,0). Uses Apex closing prices for NOP valuation. Never NULL (all |
| `13` | 0.084 | 2 | 1 | **eToro instrument key** from **`DWH_dbo.Dim_Instrument`** when Apex identifiers match; **NULL** if no match. (Tier 2 — SP_Apex_PnL) | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtu |
| `2` | 0.107 | 2 | 2 | **Apex LP account number** (e.g. eToro’s account at Apex Clearing); groups all symbols under the same clearer account. (Tier 2 — SP_Apex_PnL) | Apex Clearing Corporation account identifier. 5 accounts: 3EU05025 (64.8% of rows, HedgeServerID 112), 3EU05026 (13.4%, HS 9), 3EU05027 (10.1%, HS 102), 3EU00101 (6.5%, HS 223), 3EU05028 (5.2%, HS 3). |
| `14` | 0.125 | 2 | 1 | **eToro display name** for the instrument — may differ from Apex **`Symbol`**. (Tier 2 — SP_Apex_PnL) | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 1 -- Trade.Instrumen |
| `20` | 0.174 | 2 | 2 | **Total traded volume in units** at Apex for the symbol during the week. (Tier 2 — SP_Apex_PnL) | Absolute trade volume over the weekly window. SUM of ABS(Quantity * Price + FeeSec + Fee5) from Apex EXT872 trade execution files. Always non-negative when not NULL. NULL when no trades occurred (same |
| `6` | 0.185 | 2 | 2 | **Net open position at week end** (`Date`), **Apex closing price** — closing mark for the WTD bridge. (Tier 2 — SP_Apex_PnL) | Net Open Position market value at current day EOD, from Apex EXT982 MarketValue field. Parsed from scientific notation when present. NULL when no position existed at day end (position fully closed). ( |
| `8` | 0.187 | 2 | 2 | **Net traded notional** for the week from Apex activity (buys vs sells); enters the PnL formula with a **minus** sign. (Tier 2 — SP_Apex_PnL) | Net trade value over the weekly window (Saturday through current date). SUM of (Quantity * Price + FeeSec + Fee5) from Apex EXT872 trade execution files. Negative values indicate net selling; positive |
| `19` | 0.236 | 2 | 2 | **Additional Apex fees/adjustments** (borrow, corp actions, etc.) **included** in the published PnL bridge. (Tier 2 — SP_Apex_PnL) | Additional non-dividend fees/credits from Apex EXT869 files. SUM of negated Amount WHERE TerminalID is not '$+DIV' and not a transfer code ('CSCSG','FWWRD','MGLOA','MGJNL'). NULL for 98% of rows (most |
| `16` | 0.248 | 2 | 2 | **eToro DB bid** at week start — supports **price-level** reconciliation alongside `Price_Start`. (Tier 2 — SP_Apex_PnL) | eToro internal DB bid price at week start. Last BidSpreaded from PriceLog_History_CurrencyPrice before Friday trading session close (21:30 Fri, 22:00 weekdays). GBX prices divided by 100 for GBP conve |

## Top issues — regen wiki (per judge)

- [medium] `InstrumentDisplayName` — Tagged '(Tier 1 -- Trade.Instrument)' but Dim_Instrument wiki tags this column as '(Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)'. The dim's origin is Trade.InstrumentMetaData, not Trade.Instrument. Correct tag should be '(Tier 1 -- Trade.InstrumentMetaData)'.
- [low] `Header blurb (line 1)` — Header says 'weekly and daily P&L reconciliation table' but this table is weekly-window only. The daily sibling is Dealing_Apex_PnL_Daily. Misleading to describe this table as covering both.
- [low] `Volume / Trades precision` — Trades is decimal(16,8) but Volume is decimal(16,6) despite using the same source formula (Qty*Price+Fees vs ABS(Qty*Price+Fees)). The wiki correctly documents both types but does not explain the precision difference.
- [low] `Section 6.2` — Referenced By only lists sibling tables from the same SP. No downstream consumers (views, reports) are documented. May be accurate (no downstream references) but not explicitly confirmed.
