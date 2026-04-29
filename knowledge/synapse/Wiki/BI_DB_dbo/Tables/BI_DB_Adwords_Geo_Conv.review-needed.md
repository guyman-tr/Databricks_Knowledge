# Review Needed: BI_DB_dbo.BI_DB_Adwords_Geo_Conv

## Critical: Data is Stale

1. **Last update: 2023-09-18**. SP has not run since Synapse migration.
2. **region_criteria_id hardcoded NULL** — column exists but never populated. Consider dropping from DDL.
3. **external_customer_id = customer_id** — redundant column.

## Questions for Reviewer

- Has geo conversion data moved to Databricks?
- country_criteria_id maps to Google Ads geocriteria codes — is there a lookup table for resolving these to country names?
- No 2nd-gen app columns (Regs_IOS2 etc.) in this table — was this intentional, or should they be added for parity with Ad_Conv?
- FTDA/MTDA are int type here but float in other tables — is the value in micros or actual currency?

## Cross-Object Consistency

- Geographic counterpart to BI_DB_Adwords_Geo_Pref (performance metrics).
- Funnel pivot formula consistent with cluster: SUM(all_conversions - view_through_conversions).
- Part of SP_Adwords_Pref_Conv cluster (Table #4 of 12).
