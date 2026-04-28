# BI_DB_dbo.BI_DB_AffData — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns documented at Tier 3b (DDL structure).

## Columns Needing Clarification

| Column / Topic | Question | Context |
|----------------|----------|---------|
| All columns | Is this table deprecated? | Table has 0 rows, no writer SP exists in the SSDT repo, and no views/SPs reference it. Should it be dropped? |
| ContractType | Does this store the text label or numeric code? | In Dim_Affiliate, ContractType is tinyint (0=N/A, 2=CPA, etc.). Here it is varchar(20) — unclear if it stores "CPA" or "2" |
| Aff_eLanguage | What does the "e" prefix signify? | Column is nvarchar(255) — correlates with Dim_Affiliate.LanguageName but the "e" prefix is unexplained (possibly "eToro language" or "electronic language preference") |
| RealCID + AffiliateID | Can a customer have multiple affiliates? | The composite PK allows this, but in practice a customer is typically associated with one affiliate at acquisition time |

## Structural Questions

- **Dormant status confirmation**: This table has 0 rows and no ETL pipeline. Is it safe to deprecate/drop, or is there a planned use case?
- **Relationship to Dim_Affiliate**: All affiliate columns appear to be a subset of Dim_Affiliate attributes. Was this table intended as a pre-joined denormalization for BI reporting?
- **Missing columns**: Dim_Affiliate has 56 columns; this table has only 11 (9 affiliate attributes + RealCID + UpdateDate). Was the slim schema intentional or was this table never fully built out?

## Tier 5 Re-Review Needed

> Tier 5 (domain expert) overrides whose underlying Tier 1-3 source has materially changed
> since the correction was made. The Tier 5 is still applied, but a domain expert should
> confirm it remains valid given the new upstream definition.

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
