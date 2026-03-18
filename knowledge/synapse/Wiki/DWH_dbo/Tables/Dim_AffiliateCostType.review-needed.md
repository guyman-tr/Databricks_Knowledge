# DWH_dbo.Dim_AffiliateCostType — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all elements described from live data (Tier 3) or migration DDL (Tier 2b).

## Columns Needing Clarification

No ambiguous columns found.

## Structural Questions

- **Frozen status**: This table has no active ETL and NULL timestamps for all rows. Is this intentional, or should it be added to SP_Dictionaries? Are there new affiliate cost types that need to be added?
- **eCost (ID=10)**: What does "eCost" represent specifically? Is it electronic/digital marketing costs, or a different cost classification?
- **Copys (ID=9)**: Is this specifically for copy-trade referral costs? The spelling "Copys" (not "Copies") appears intentional.

## Tier 5 Re-Review Needed

_No Tier 5 overrides exist for this object._
