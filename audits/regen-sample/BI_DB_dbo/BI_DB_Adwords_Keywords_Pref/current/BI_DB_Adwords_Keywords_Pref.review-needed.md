# Review Needed: BI_DB_dbo.BI_DB_Adwords_Keywords_Pref

## Critical: Data is Stale

1. **Last update: 2023-09-18**. SP has not run since Synapse migration.
2. **cost is in micros** — value not converted, users must divide by 1,000,000.
3. **id column always NULL** — SP comments out the INSERT.

## Questions for Reviewer

- Has keyword performance data moved to Databricks?
- search_*_share columns are stored as nvarchar — should these be converted to numeric for analysis?
- quality_score = 0 vs NULL — what's the semantic difference in the source data?

## Cross-Object Consistency

- Performance counterpart to BI_DB_Adwords_Keywords_Conv (conversion breakdown).
- Part of SP_Adwords_Pref_Conv cluster (Table #3 of 12).
- Cost-in-micros pattern consistent with Geo_Pref.
