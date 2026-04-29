# Review Needed: BI_DB_dbo.BI_DB_Adwords_Search_Conv

## Critical: Data is Stale

1. **Last update: 2023-09-18**. Month range only 2023-05-01 to 2023-08-01.
2. **keyword_id and search_key always NULL** — SP comments out both columns.
3. **query_targeting_status = query_match_type_with_variant** — both map from same Fivetran field. Redundant.

## Questions for Reviewer

- Has search query conversion data moved to Databricks?
- keyword_id was commented out — should it be re-enabled for keyword↔query attribution?
- search_key was originally a composite key (ad_group_id+device+month+query+keyword_id+match). Was it abandoned for a reason?
- No 2nd-gen app columns — was this intentional given the table was already complex?
- month column is nvarchar(256) storing dates like '2023-05-01' — should this be a date type?

## Cross-Object Consistency

- Conversion counterpart to BI_DB_Adwords_Search_Perf (performance metrics).
- Only Adwords table with HASH(customer_id) distribution and monthly grain.
- Funnel pivot formula consistent with cluster.
- Part of SP_Adwords_Pref_Conv cluster (Table #10 of 12).
