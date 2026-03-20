# DWH_dbo.Vw_STS_User_Operations_Data_History — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions inherited from base table STS_User_Operations_Data_History (Tier 2/3).

## Columns Needing Clarification

1. **View purpose**: Why does this view exist? The only transform is `CAST(ClientDeviceId AS nvarchar(max))`. Is this for a specific consumer (BigQuery export, replication pipeline) that requires nvarchar(max)?

## Structural Questions

1. **Consumer identification**: Which downstream systems or reports consume this view instead of the base table?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
