# DWH_dbo.Dim_AccountStatus — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all elements have Tier 1 or Tier 2 confidence.

## Columns Needing Clarification

No ambiguous columns found.

## Structural Questions

- **DWH consumer coverage**: The "Referenced By" section lists Dim_Customer and Fact_SnapshotCustomer. Are there additional DWH fact/dimension tables that JOIN on AccountStatusID?

## Tier 5 Re-Review Needed

_No Tier 5 overrides exist for this object._
