# BI_DB_dbo.BI_DB_ASIC_CreditLine_At_transfer — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all 7 elements are Tier 1 or Tier 2.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| TotalCLAmount | Only 416/655K rows non-NULL. Is this expected, or could the LEFT JOIN condition (matching on DateID + CID→RealCID) be mis-aligned for some time ranges? |
| FromRegulation = "ASIC" | 15% of rows show transfer FROM ASIC to ASIC & GAML. Is this a distinct regulatory migration (ASIC → ASIC & GAML), or could some be data artifacts? |

## Structural Questions

- The table has no explicit PK constraint. The natural key appears to be (CID, DateID). Could a customer have multiple regulation transfers on the same day, producing duplicate (CID, DateID) rows?
- The SP has `@Date` parameter — is this always called with yesterday's date, or can it backfill historical dates?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
