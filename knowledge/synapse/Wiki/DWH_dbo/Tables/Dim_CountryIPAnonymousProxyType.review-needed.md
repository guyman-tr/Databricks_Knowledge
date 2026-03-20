# DWH_dbo.Dim_CountryIPAnonymousProxyType — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns — all 4 columns documented from live data (Tier 3). The full set of 6 rows was visible.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| UpdateDate | Always NULL — was this table loaded by a manual INSERT script at some point? If so, when and by whom? Is there a process to refresh it when IP2Location updates their taxonomy? |

## Structural Questions

1. **No SSDT SP found**: The table contains 6 rows but no SSDT-managed stored procedure was found that INSERTs into it. Was it loaded by a one-time script (not in SSDT)? Is there a manual process to update it?
2. **Not exported to UC**: This table is not in the Generic Pipeline. Should analysts querying ProxyType from Databricks have to derive it from Dim_CountryIPAnonymous alone, or should this reference table also be made available in UC?
3. **NULL ProxyType column**: The ProxyType column is defined as VARCHAR(3) NULL (not NOT NULL). Given it is the natural key/PK, should this be NOT NULL?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
