# Dealing_dbo.DSC_HedgeOnIndices_H — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions derived from SP code analysis (Tier 2).

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| Unreals/Unreale | Recent data shows NULLs for all rows — are positions no longer being tracked for indices hedge, or is this a data issue? | Live sample shows NULL for Unreals, Unreale, Realised, AskLast, BidLast, units in recent rows |
| MULTIPLIER | The currency conversion MULTIPLIER is set to 1 for all cases except SellCurrencyID=666 — what does CurrencyID 666 represent? | SP code: `CASE WHEN gg.SellCurrencyID=666 THEN 1 ELSE 1 END AS MULTIPLIER` — always 1, suggesting the CASE was intended for a different logic |
| 0.8 factor | The synthetic account PnL uses `* 0.8` — is this a fixed 80% hedge ratio, or does it represent something else? | SP code: `(DD.BidLast-SS.BidLast)*SS.units*0.8` |

## Structural Questions

| Question | Context |
|----------|---------|
| Is this table consumed by any Tableau/Grafana dashboards for intraday hedge monitoring? | The hourly granularity suggests real-time operational use |
| Should the _H table be retained indefinitely, or is there a retention policy? | Currently has data back to 2021-07-11 |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
