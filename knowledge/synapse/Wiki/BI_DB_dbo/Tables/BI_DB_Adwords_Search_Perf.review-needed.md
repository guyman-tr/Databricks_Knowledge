# BI_DB_dbo.BI_DB_Adwords_Search_Perf — Review Needed

## Tier 4 Items (require human verification)

| Column | Current Tier | Question |
|--------|-------------|----------|
| query_targeting_status | Tier 4 | Column exists in DDL but SP never populates it. Confirm intended purpose — was it planned for future use or deprecated? |
| keyword_id | Tier 4 | Same pattern — exists in DDL, never inserted. Confirm if this was intended to link to Keywords_Conv/Keywords_Pref tables. |
| search_key | Tier 4 | Never populated. nvarchar(1340) suggests composite key — was this planned as a concatenated lookup key? |

## Questions for Reviewer

1. **Stale data**: This table has not been refreshed since 2023-09-18. Is the Fivetran Google Ads pipeline permanently decommissioned, or is this a temporary outage?
2. **external_customer_id**: The SP inserts `customer_id` into both `customer_id` and `external_customer_id` — is this intentional (MCC = account) or a bug where external_customer_id should hold a different value?
3. **cost field units**: Confirmed from SP code that cost = SUM(cost_micros). The column name suggests currency but the value is in micros. Should this be documented as a known data quality issue?

## Cross-Object Consistency Notes

- **query_match_type_with_variant**: Same enum values (BROAD, EXACT, NEAR_EXACT, NEAR_PHRASE, PHRASE) as documented in BI_DB_Adwords_Search_Conv — consistent.
- **cost in micros**: Same pattern as all Adwords cluster tables (Ad_Conv, Ad_Pref, Keywords_Conv, Keywords_Pref, Geo_Conv, Geo_Pref, Campaign_Performance_Report).
- **3 unpopulated columns**: Same pattern as Search_Conv (keyword_id, search_key NULL) plus query_targeting_status (which IS populated in Search_Conv as a rename of search_term_match_type from the conv source).
