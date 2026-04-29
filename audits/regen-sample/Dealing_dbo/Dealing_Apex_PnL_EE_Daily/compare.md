# Compare — `Dealing_dbo.Dealing_Apex_PnL_EE_Daily`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.35; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.4 | 8.75 | 1.35 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 8 | 8 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 7 | 8 | +1 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 10 |
| data_evidence | 6 | 7 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `8` | 0.063 | 2 | 2 | **Dividends** credited to the Apex account on this business date. (Tier 2 — SP_Apex_PnL) | Aggregate dividends credited to the account on this day (all instruments). Source: `SUM(-Amount)` from `LP_APEX_EXT869_3EU` where `TerminalID = '$+DIV'`. NULL when no dividends were credited (52% of r |
| `2` | 0.204 | 2 | 2 | Apex LP **account number** identifying the reconciled LP account. (Tier 2 — SP_Apex_PnL) | Apex LP account identifier (e.g. 3EU05025, 3EU00101). Resolved via ISNULL cascade across equity, transfers, and dividends feeds -- whichever feed carries the account for the day. 6 distinct accounts h |
| `3` | 0.297 | 2 | 2 | **Total account equity** at **prior business day** end of day — opening equity for the daily bridge. (Tier 2 — SP_Apex_PnL) | Total account equity (USD) at prior business day EOD. Monday rows use Friday; bank holidays shift back one additional day. Source: `Dealing_staging.LP_APEX_EXT981_3EU.TotalEquity` with scientific nota |
| `5` | 0.31 | 2 | 2 | **Net cash transfers** into or out of the Apex account on this date (non-PnL cash movement). (Tier 2 — SP_Apex_PnL) | Net cash transfers into/out of the Apex account on this day. Source: `SUM(-Amount)` from `LP_APEX_EXT869_3EU` where `TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL')`. Positive = funds received; negati |
| `7` | 0.375 | 4 | 2 | Row load / ETL timestamp (typically `GETDATE()` at insert). [UNVERIFIED] (Tier 4 — inferred) | ETL execution timestamp from `GETDATE()` in `SP_Apex_PnL`. Reflects when the row was loaded, not when the equity was valued. (Tier 2 -- SP_Apex_PnL) |
| `1` | 0.404 | 2 | 2 | Business date for the daily equity snapshot — the reporting date for this row. (Tier 2 — SP_Apex_PnL) | Business date for the daily equity row. One row per AccountNumber per trading day. The SP uses `@Date` parameter; bank holidays shift to the prior business day for equity reads. (Tier 2 -- SP_Apex_PnL |
| `6` | 0.419 | 2 | 2 | **Daily equity PnL**: `Equity_End - Equity_Start - Transfers` — trading and mark-to-market effect at account level for the day. (Tier 2 — SP_Apex_PnL) | Daily equity PnL: `ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0)`. Isolates market-driven equity change by removing transfer effects. Does NOT include Dividends in the formula. ( |
| `4` | 0.493 | 2 | 2 | **Total account equity** at **this day** end of day — closing equity for the daily bridge. (Tier 2 — SP_Apex_PnL) | Total account equity (USD) at current day EOD. Source: `Dealing_staging.LP_APEX_EXT981_3EU.TotalEquity` with scientific notation handling. NULL for 3% of rows. (Tier 2 -- SP_Apex_PnL) |

## Top issues — regen wiki (per judge)

- [low] `Section 4 (tier legend)` — Tier legend only lists Tier 2 row. While accurate, should explicitly acknowledge absence of Tier 1/3/4 so readers know it is intentional, not an omission.
- [low] `Section 5.2 (ETL pipeline)` — Dividends FULL OUTER JOIN in SP uses ON e.AccountNumber = d.AccountNumber (keyed to #Equity_Daily), meaning dividend-only accounts with no equity record rely on FULL OUTER JOIN behavior to surface. Wiki diagram does not surface this subtlety.
- [low] `Footer / Phase Gates` — No explicit Phase Gate Checklist section with P1/P2/P3 checkboxes. Data evidence is present in descriptions but the formal verification structure is absent.
- [low] `Section 2.1 (PnL formula)` — Section 2.1 states PnL = Equity_End - Equity_Start - Transfers but SP computes ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0). Elements section correctly shows ISNULL wrapping but the Business Logic formula omits it.
- [low] `All Elements (formatting)` — Wiki uses double-hyphen '--' in tier tags (e.g. 'Tier 2 -- SP_Apex_PnL') while sibling wikis use em-dash. Cosmetic inconsistency across the Apex PnL family.
