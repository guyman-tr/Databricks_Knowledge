# BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts — Review Needed

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
| IsOpenedFromIBAN | DDL defines as `varchar(100)` but function returns int-like values (0/1). Is this a DDL bug or intentional for future expansion? |
| IsLeverage | Named `IsLeverage` instead of `IsLeveraged` (used in other DDR tables). Confirm this is intentional or should be aligned |
| InvestedAmountOpen/Closed | Uses `money` type — confirm whether precision is sufficient for large positions |

## Structural Questions

| Topic | Question |
|-------|----------|
| QA dump | The SP writes position-level detail to `BI_DB_VolumeQA` — confirm whether this is actively monitored or just a debugging artifact |
| Data loss investigation | SP change history (2026-01-15) mentions "bizarre data loss when running at different times" — confirm whether the root cause was found and resolved |
| Function replacement | 2026-01-15 replaced source function with position-level granularity — confirm whether historical data before this date was backfilled with the new function |
