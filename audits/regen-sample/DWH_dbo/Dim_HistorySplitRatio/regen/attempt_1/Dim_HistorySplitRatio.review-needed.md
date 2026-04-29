# DWH_dbo.Dim_HistorySplitRatio — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all 9 columns are Tier 1 (8 columns) or Tier 2 (1 column).

## Columns Needing Clarification

- **PriceRatioUnAdjusted / AmountRatioUnAdjusted**: The upstream wiki describes these as `money` type. The DWH stores them as `decimal(19,4)`. The semantic meaning is preserved, but confirm whether the type change from money to decimal introduces any rounding differences for extreme ratio values.
- **MinDate / MaxDate nullability**: The DWH DDL allows NULLs for these columns, but the production table enforces NOT NULL with defaults (`2000-01-01` and `2100-01-01`). In the current 16,014 rows, no NULLs exist. Confirm whether NULLs are ever expected in the DWH copy.

## Structural Questions

- **Relationship to Fact_CurrencyPriceWithSplit**: Confirm that `Fact_CurrencyPriceWithSplit` is the primary consumer of this dimension for price adjustment. Are there other DWH tables that JOIN to `Dim_HistorySplitRatio`?
- **Missing operational columns**: The DWH drops all 11 completion flags from production. If analytics ever needs to identify "split in progress" vs "split completed" status, this information is not available in the DWH. Confirm this is intentional.

## Tier 5 Re-Review Needed

> Tier 5 (domain expert) overrides whose underlying Tier 1-3 source has materially changed
> since the correction was made. The Tier 5 is still applied, but a domain expert should
> confirm it remains valid given the new upstream definition.

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
