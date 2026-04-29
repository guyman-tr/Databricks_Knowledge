# Review Needed: BI_DB_dbo.BI_DB_Adwords_Keywords_Conv

## Critical: Data is Stale

1. **Last update: 2023-09-18**. Date range only 2023-06-19 to 2023-08-09 (shorter than other tables).
2. **id column always NULL** — SP comments out the INSERT. DDL vestige.

## Questions for Reviewer

- Has keyword conversion data moved to Databricks?
- LTV_Count/LTV_Value columns — are these still relevant for marketing attribution?
- OpenTrade columns are mostly empty — were these ever actively populated?
- The shorter date range (only through Aug 2023, not Sept like others) — was this table not refreshed in the last SP run?

## Cross-Object Consistency

- Conversion counterpart to BI_DB_Adwords_Keywords_Pref (performance metrics).
- Widest table in Adwords cluster (38 cols). Unique columns: LTV_Count, LTV_Value, OpenTrade_*.
- Conversion pivot formula consistent with cluster.
- Part of SP_Adwords_Pref_Conv cluster (Table #6 of 12).
