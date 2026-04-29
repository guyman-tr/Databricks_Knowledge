# Review Needed: BI_DB_dbo.BI_DB_Adwords_Campaign_Performance_Report

## Critical: Data is Stale

1. **Last update: 2023-09-18**. SP has not run since Synapse migration.
2. **Date range**: 2023-06-19 to 2023-09-17 only.
3. **Part of Adwords cluster**: Same stale status across all 12 tables managed by SP_Adwords_Pref_Conv.

## Questions for Reviewer

- Has Google Ads data pipeline moved to Databricks or another system?
- DDL has 17 columns (not 18 as stated in batch assignment). Confirm.
- average_position column is deprecated (NULL). Should it be removed from the DDL?
- campaign_name follows a naming convention (e.g., SEA_YTR_Product_1_CPA_____EN_67633). Is there a parser or dictionary that decodes these naming conventions?
