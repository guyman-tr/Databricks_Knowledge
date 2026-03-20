# DWH_dbo.Dim_BonusType -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 8 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

No individual column clarification needed. The column meanings are well-established.

## Structural Questions

1. **ParentID excluded**: The production BackOffice.BonusType table has a ParentID column creating a 2-level departmental hierarchy (9 root categories). This is not loaded into DWH. Is this intentional? If bonus reporting requires grouping by department (Sales, Retention, Accounting, etc.), the hierarchy must be reconstructed manually from the production source.
2. **DisplayName excluded**: The customer-facing display label (shown in account statements) is not in DWH. Was this excluded intentionally? Analysts who need to display customer-visible bonus labels cannot derive them from DWH alone.
3. **IsDepositRelated excluded**: The flag identifying deposit-triggered bonuses is not in DWH. If deposit-related bonus analysis is needed, this creates a gap.
4. **BonusTypeID smallint vs production int**: DWH uses smallint (max 32,767) while production uses int IDENTITY. Current max ID=71 is well within smallint range, but if bonus types expand significantly, this could become a type constraint.
5. **ETL freshness**: UpdateDate=2026-03-11 (7 days stale as of 2026-03-18). Confirm ETL is running or investigate why SP_Dictionaries_DL_To_Synapse hasn't refreshed.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
