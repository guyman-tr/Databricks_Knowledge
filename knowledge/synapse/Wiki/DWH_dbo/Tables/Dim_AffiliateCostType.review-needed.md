# DWH_dbo.Dim_AffiliateCostType — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this documentation. All 4 columns are classified at Tier 2b or Tier 3.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Name (ID=9) | "Copys" appears to be a typo — should this be "Copy" (as in copy-trade commissions) or something else? Confirm with affiliate team before using this label in reports. |

## Structural Questions

1. **No active consumers**: This table has zero references in the current Dataplatform SSDT repo (no SPs, no views join to it). Was this table migrated anticipating future use, or is it an artifact from a legacy affiliate cost tracking system that is no longer active in the Synapse pipeline?
2. **Production source**: The legacy DWH SQL Server source has no upstream wiki and no active etoro production DB equivalent. Does an affiliate cost type reference table exist in the fiktivo/AffWizz system (used by `SP_Dim_Affiliate`)? If so, should this table be linked to that source?
3. **ETL revival**: Should this table be connected to an ETL SP to receive live affiliate cost type data from an upstream system?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
