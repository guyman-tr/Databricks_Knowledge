# DWH_dbo.Dim_CostConfigurationId - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| CostConfigurationId (Relationship) | Is Dim_CostConfigurationId.CostConfigurationId actually referenced by Fact_History_Cost? No SP grep match found - the Fact_History_Cost SP may reference it indirectly or the column name may differ. Please confirm. |
| UpdateDate (NOT NULL) | The DDL defines UpdateDate as NOT NULL but the source staging column has no NOT NULL constraint. This is consistent with GETDATE() injection (always non-null from ETL). Confirm no rows can have NULL UpdateDate. |

## Structural Questions

| Question |
|----------|
| Why is Dim_CostConfigurationId distributed ROUND_ROBIN? With only 4 rows it should be REPLICATE for broadcast join efficiency. Was this a default ETL setting? Can it be changed? |
| HistoryCosts.Dictionary.CostConfigurationId is not in the Generic Pipeline mapping. How is the staging table DWH_staging.HistoryCosts_Dictionary_CostConfigurationId refreshed? Is there an ADF pipeline or a direct SQL linked server load? |
| Only 4 cost configuration types exist (MarkupReal, MarkupCfd, TicketFee, CurrencyConversionMarkup). Are there additional types planned or is this set complete? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
