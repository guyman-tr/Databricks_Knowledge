# Compare — `Dealing_dbo.Dealing_Apex_PnL_EE`

**Bucket**: `slop`

**Verdict**: **EQUIVALENT**  (score delta +0.1; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.15 | 8.25 | 0.1 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 8 | 8 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 8 | 8 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 8 |
| data_evidence | 5 | 6 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `5` | 0.076 | 2 | 2 | **Net transfers** for the week — **cash movement** into/out of Apex; use to **explain** equity step changes separate from **market PnL**. (Tier 2 — SP_Apex_PnL) | Net cash transfers into or out of the Apex account during the WTD window (Saturday-before through @Date). Aggregated as SUM(-Amount) from LP_APEX_EXT869_3EU WHERE TerminalID IN ('CSCSG','FWWRD','MGLOA |
| `6` | 0.128 | 2 | 2 | **Equity PnL:** `Equity_End - Equity_Start - Transfers` — **does not** roll **`Dividends`** into this expression per SP logic. (Tier 2 — SP_Apex_PnL) | Week-to-date equity PnL: ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0). Represents the net trading and mark-to-market effect at account level for the WTD window. Always populated |
| `4` | 0.16 | 2 | 2 | **Total equity (USD)** at **`Date` EOD** — closing equity on the statement. (Tier 2 — SP_Apex_PnL) | Total account equity at the reporting date EOD -- closing equity for the WTD bridge. Sourced from LP_APEX_EXT981_3EU.TotalEquity at @DateID. NULL when no equity file exists for the end date (14% of ro |
| `3` | 0.197 | 2 | 2 | **Total equity (USD)** at **week start** — **Friday EOD** prior to **`Date`**. (Tier 2 — SP_Apex_PnL) | Total account equity at the prior week's Friday EOD (or Thursday if Friday is a bank holiday) -- opening equity for the WTD bridge. Sourced from LP_APEX_EXT981_3EU.TotalEquity at @FridayBeforeID. NULL |
| `8` | 0.199 | 2 | 2 | **Aggregate dividends** for the **account** for the week (all instruments). (Tier 2 — SP_Apex_PnL) | Total dividends credited to the Apex LP account during the WTD window. Aggregated per AccountNumber from LP_APEX_EXT869_3EU WHERE TerminalID = '$+DIV'. Stored separately from the PnL bridge formula. N |
| `2` | 0.305 | 2 | 2 | **Apex account** key — **COALESCE**-style resolution across equity/transfers/dividend feeds in SP when identifiers differ by feed. (Tier 2 — SP_Apex_PnL) | Apex LP account number identifying the reconciled LP account (e.g., 3EU05025, 3EU05027). Resolved via COALESCE across equity, transfers, and dividends staging sources. 6 distinct accounts in the datas |
| `1` | 0.352 | 2 | 2 | **WTD report date** — **end-of-week** anchor (Saturday-style), aligned with **`Dealing_Apex_PnL.Date`** semantics. (Tier 2 — SP_Apex_PnL) | Report date for the WTD equity snapshot -- the Saturday (or equivalent) end-of-week date per the SP's WTD calendar logic. Used as the DELETE/INSERT key for idempotent reload. (Tier 2 -- SP_Apex_PnL) |
| `7` | 0.494 | 2 | 2 | **ETL timestamp** (`GETDATE()` from `SP_Apex_PnL`). (Tier 2 — SP_Apex_PnL) | ETL load timestamp set to GETDATE() at insert time by SP_Apex_PnL. Does not reflect production or Apex file timestamps. Last value: 2024-06-08 09:19. (Tier 2 -- SP_Apex_PnL) |

## Top issues — regen wiki (per judge)

- [low] `AccountNumber (Element #2)` — Element description says '6 distinct accounts' but does not list them inline. Values are in Section 1 but Elements table should be self-contained.
- [low] `Footer / Phase Gate` — No Phase Gate Checklist section or footer line confirming P2/P3 live data verification was performed. Data claims (NULL rates, row counts) are plausible but unverifiable.
- [low] `Section 2.3` — Account-to-HedgeServer mapping (3EU05026→HS9, etc.) is used only by #Zero for per-symbol sibling tables, not by this equity-level table. Inclusion is contextually useful but slightly misleading about this table's own ETL.
- [low] `Footer` — Missing phases-completed line in footer (golden shape expects 'Phases: P1 [x] P2 [x] P3 [x]').
- [low] `AccountNumber (Section 1)` — Wiki lists 3EU05000 as one of 6 accounts but SP's #AccountToHS mapping only has 5 (no HS for 3EU05000). Wiki does not explain this gap.
