# DWH_dbo.Dim_Language -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all columns traced to SP code (Tier 2) or live data (Tier 3).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| IsoCode (zh) | IsoCode='zh' is shared by LanguageID=4 (Chinese Simplified, zh-CN) and LanguageID=18 (ChineseTraditional, zh-TW). When joining on IsoCode='zh', both languages match. Is this intentional? Should analysts always use CultureCode for Chinese differentiation? |
| Name (char vs varchar) | Name is defined as char(50) (fixed-width, space-padded). Was this intentional, or should it be varchar? Using RTRIM() is required to avoid trailing-space issues in downstream analysis. |

## Structural Questions

| Question |
|----------|
| Is LanguageID used in customer profile tables, event tables, or both? A list of which DWH tables reference Dim_Language.LanguageID would clarify the table's usage scope. |
| Are any of the 28 languages planned for deprecation as eToro scales back support for certain regions? If so, can they be flagged in the data? |
| The table has HEAP distribution. Was this intentional or an oversight? At 29 rows the performance impact is nil, but consistency with other Dim tables (CLUSTERED INDEX) might be preferred. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
