# DWH_dbo.Dim_Channel — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns were described from SP code analysis (Tier 2).

## Columns Needing Clarification

1. **SubChannelID=0 exclusion**: SP_Dim_Channel filters `WHERE SubChannelID != 0`, so the "Unknown" sentinel row is NOT in Dim_Channel. Confirm: should unknown-channel affiliates be trackable via this dimension, or is the exclusion intentional?

2. **Google Brand as Organic**: The Organic/Paid classification treats Google Brand (paid SEM) as "Organic". Confirm this is an intentional business decision (brand queries counted as organic reach) and not a classification error.

3. **AffiliateID-specific overrides**: AffiliateIDs 56662 and 56663 are hardcoded to "Direct Mobile" regardless of their actual channel. What affiliates are these and why the override?

## Structural Questions

1. **ROUND_ROBIN distribution**: With ~50 rows, this table should likely be REPLICATE for optimal JOIN performance. Is there a reason ROUND_ROBIN was chosen?

2. **No email alert**: The SP_Dim_Channel email notification for new unmapped channels is commented out. Is there an alternative monitoring mechanism for new AffWizz channels?

## Tier 5 Re-Review Needed

> Tier 5 (domain expert) overrides whose underlying Tier 1–3 source has materially changed
> since the correction was made. The Tier 5 is still applied, but a domain expert should
> confirm it remains valid given the new upstream definition.

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
