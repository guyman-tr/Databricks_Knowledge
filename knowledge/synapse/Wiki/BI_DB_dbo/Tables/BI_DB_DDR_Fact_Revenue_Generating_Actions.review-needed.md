# BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all 27 columns are Tier 2 with verified SP code provenance.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| IncludedInTotalRevenue | Confirm the complete list of metrics that should be IncludedInTotalRevenue=0 (currently: Commission, Dividends, SDRT) — has this changed? |
| IsMarginTrade | New flag added 2025-10-23 — confirm business definition: is this margin-call-related or simply leveraged-with-margin? |
| IsC2P | Copy-to-Portfolio flag added 2025-12-13 — confirm scope: does this cover all C2P positions or only specific ones from V_C2P_Positions? |
| CountAsActiveTrade | Only counted for ActionTypeID IN (1,39) — confirm whether ManualClose or other action types should also count |

## Structural Questions

| Topic | Question |
|-------|----------|
| SDRT recurrence | SP change history shows SDRT IncludedInTotalRevenue=1 kept reappearing and being fixed. Is there a root cause (code merge conflict?) that should be addressed? |
| Staking lag | StakingLagOneMonth is shifted forward by one month — confirm whether downstream consumers (DDR reports) are aware of this lag |
| Options reliability | All Options data is deleted and re-inserted every run — confirm impact on downstream caches or reports that may snapshot mid-day |
| Dividend IsBuy override | IsBuy is overridden to 1 for positive dividends and 0 for negative — confirm whether this represents "long positions receive, short positions pay" |
