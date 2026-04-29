# Review Needed: BI_DB_dbo.BI_DB_Adwords_Ad_Pref

## Critical: Data is Stale

1. **Last update: ~2023-08**. SP has not run since Synapse migration.
2. **Date range**: 2022-09-01 to 2023-09-17 only.

## Questions for Reviewer

- Column count: DDL has 36 columns (not 37 as stated in batch assignment). Verify.
- The `headline` column is mapped from `expanded_text_ad_headline_part_3` (not the main headline). Is this intentional or an SP bug?
- `description` and `description_1` are both mapped from `expanded_text_ad_description` (same source). Are they truly identical?
- RSA JSON columns (`responsive_search_ad_headlines/descriptions`) contain rich per-asset performance data. Is anyone parsing this structured content for analysis?
- Has this data moved to Databricks? What is the replacement pipeline for Google Ads reporting?
