# Review Needed: BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup

## Critical: Data is Stale

1. **Last update: 2023-09-18**. SP has not run since Synapse migration.
2. **target_cpa column is always NULL** — the SP INSERT omits this column. Consider removing from DDL or populating from a different source.

## Questions for Reviewer

- Has this dictionary been replaced by a Databricks-based lookup?
- Should target_cpa be populated? The Fivetran source likely has this field — was it deliberately excluded?
- Is the ad_group_id globally unique in Google Ads, or does uniqueness require (campaign_id, ad_group_id)?

## Cross-Object Consistency

- Referenced by 6 other Adwords tables via ad_group_id JOIN.
- Part of SP_Adwords_Pref_Conv cluster (Table #12 of 12).
