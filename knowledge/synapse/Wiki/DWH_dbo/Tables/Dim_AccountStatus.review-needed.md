# DWH_dbo.Dim_AccountStatus - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All 5 elements have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

- **StatusID**: Confirmed hardcoded to 1 by SP_Dictionaries_DL_To_Synapse. If this column has semantic meaning beyond being a generic ETL flag (e.g., does it gate downstream queries?), please clarify.

## Structural Questions

- **Referenced By section**: The wiki lists DWH_dbo.Dim_Customer and DWH_dbo.CustomerStatic as consumers. Please confirm there are no other DWH tables or views that JOIN to Dim_AccountStatus on AccountStatusID (fast-path skipped Phase 7 view scan and full Phase 5 JOIN analysis).
- **ID=0 placeholder logic**: The SP adds a hardcoded ID=0 "N/A" row. Is this intentional and consistent with how other Dim tables handle missing FK values? Or was this added for a specific consumer?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
