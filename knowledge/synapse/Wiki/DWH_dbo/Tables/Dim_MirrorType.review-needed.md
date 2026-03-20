# DWH_dbo.Dim_MirrorType -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all columns traced to SP code or live data.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| MirrorTypeID=2 (CopyMe) | Is 'CopyMe' the legacy name for the Popular Investor program? Has this product been renamed to 'Popular Investor' in the UI but still stored as CopyMe in the DB? Confirm the current product marketing name for this type. |
| MirrorTypeID=3 (Social Index) | Is 'Social Index' the legacy name for Smart Portfolios (formerly CopyPortfolios)? Confirm the current product name and whether new Smart Portfolio copies use MirrorTypeID=3. |
| MirrorTypeID=4 (Fund) | Are eToro Funds still an active product? How many active Fund mirrors exist in Dim_Mirror? |

## Structural Questions

| Question |
|----------|
| Dim_MirrorType has no MirrorTypeID=0 sentinel. Does Dim_Mirror or any fact table ever carry MirrorTypeID=0 or NULL? If so, how should analysts handle it? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
