# Review Needed: BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report

## Critical: Data is Stale

1. **Last update: 2023-09-18**. SP has not run since Synapse migration.
2. **Date range**: 2023-06-19 to 2023-09-16 only. Missing 3+ years of data.
3. **SP_Adwords_Pref_Conv**: Manages 12 Adwords tables in one SP. May need reactivation or migration to Databricks.

## Questions for Reviewer

- Has Google Ads conversion data moved to a Databricks pipeline? If so, which tables/views replaced these?
- Should the SP be reactivated, or should these tables be marked as deprecated?
- The 1st-gen app columns use float while 2nd-gen (Regs_IOS2 etc.) use int. Is this intentional or a schema inconsistency?
- 2nd-gen app columns (Regs_IOS2, V2_IOS2, FTD_IOS2, Regs_Android2, V2_android2, FTD_Android2) are mostly NULL — were these apps ever active in Google Ads?
- No FTDA/MTDA (conversion value) columns exist in this table unlike Ad_Conv and Geo_Conv. Was this intentional?
- DDL has 28 columns (orchestrator said 29 — verified 28 from SSDT).

## Tier Assessment

- 0 Tier 1, 26 Tier 2, 1 Tier 5.
- No upstream wiki exists for Fivetran Google Ads data — all column descriptions derived from SP code analysis.

## Cross-Object Consistency

- Part of Adwords cluster: shares SP_Adwords_Pref_Conv with BI_DB_Adwords_Ad_Conv, BI_DB_Adwords_Ad_Pref, BI_DB_Adwords_Campaign_Performance_Report, BI_DB_Adwords_Geo_Conv, BI_DB_Adwords_Geo_Pref, BI_DB_Adwords_Keywords_Conv, BI_DB_Adwords_Keywords_Pref, BI_DB_Adwords_Search_Conv, BI_DB_Adwords_Search_Perf, BI_DB_Adwords_Dictionary_Campaign, BI_DB_Adwords_Dictionary_AdGroup.
- Conversion pivot formula consistent across cluster: SUM(all_conversions - view_through_conversions).
- This table is unique in having FirstOpen and Redeposit columns (not in Ad_Conv, Keywords_Conv, or Geo_Conv).
