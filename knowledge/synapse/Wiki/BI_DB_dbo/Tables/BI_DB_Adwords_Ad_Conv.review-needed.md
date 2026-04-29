# Review Needed: BI_DB_dbo.BI_DB_Adwords_Ad_Conv

## Critical: Data is Stale

1. **Last update: 2023-09-18**. SP has not run since Synapse migration.
2. **Date range**: 2023-06-19 to 2023-09-16 only. Missing 3 years of data.
3. **SP_Adwords_Pref_Conv**: Manages 12 Adwords tables in one SP. May need reactivation or migration to Databricks.

## Questions for Reviewer

- Has Google Ads data moved to a Databricks pipeline? If so, which tables/views replaced these?
- Should the SP be reactivated, or should these tables be marked as deprecated?
- The 1st-gen app columns (android_reg/ios_reg) use float, while 2nd-gen (Regs_IOS2/Regs_Android2) use int. Is this intentional or a schema inconsistency?
- DDL shows 29 columns but only 28 actual columns. Verify count.

## Cross-Object Consistency

- Part of Adwords cluster: BI_DB_Adwords_Ad_Conv, BI_DB_Adwords_Ad_Pref, BI_DB_Adwords_Campaign_Performance_Report (this batch), plus Geo_Conv, Geo_Pref, Keywords_Conv, Keywords_Pref, Search_Conv, Search_Perf, Conversion_Performance_Report, Dictionary_Campaign, Dictionary_AdGroup (other batches).
