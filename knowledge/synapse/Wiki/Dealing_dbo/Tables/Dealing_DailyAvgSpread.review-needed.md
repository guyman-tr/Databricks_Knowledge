# Dealing_dbo.Dealing_DailyAvgSpread — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| PP = Price Provider | Confirm "PP" stands for "Price Provider" (raw LP market spread). | Inferred from `InitForex_Ask - InitForex_Bid` vs `InitForex_AskSpreaded - InitForex_BidSpreaded` |
| YTD naming | The column says "YTD" but the SP uses trailing 365 days (`DATEADD(year,-1,@Date)`), not calendar YTD. Should the column be renamed? | SP code line 10 |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
