# BI_DB_dbo.BI_DB_DDR_Fact_PnL — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all 15 columns are Tier 2 with verified SP code provenance.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| InstrumentTypeID | Confirm full set of InstrumentTypeID values used in DDR reporting (4,5,6,10,12,73 are common but the enum may be larger) |
| IsSettled | Confirm whether IsSettled=1 means "real stock ownership" or "settled CFD" in all contexts — product naming may differ |

## Structural Questions

| Topic | Question |
|-------|----------|
| Orchestration | Which parent SB job calls SP_DDR_Fact_PnL and at what time? Confirm via OpsDB SB_Daily configuration |
| Lake merge keys | SP header (2025-12-07) mentions null handling for merge keys — validate downstream lake consumers handle ISNULL'd values correctly |
| UnrealizedPnLChange scope | Does this include mark-to-market from all open positions or only positions with activity on this date? |
