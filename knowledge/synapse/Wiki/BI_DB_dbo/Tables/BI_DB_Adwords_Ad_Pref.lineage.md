# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Ad_Pref

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_ad_perf_new_api_perf_ad_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads ad-level performance report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | date | Fivetran source | date | Passthrough | Tier 2 |
| 2 | DateID | Fivetran source | date | DateToDateID(date) | Tier 2 |
| 3 | customer_id | Fivetran source | customer_id | Passthrough | Tier 2 |
| 4 | description | Fivetran source | expanded_text_ad_description | Rename | Tier 2 |
| 5 | ad_type | Fivetran source | ad_type | Passthrough | Tier 2 |
| 6-37 | (all remaining) | Fivetran source | Various | Passthrough/rename from Google Ads API fields | Tier 2 |

## Lineage Notes

- All data from Fivetran Google Ads connector (adwords_ad_perf schema).
- Direct passthrough with column renames from Google Ads API field names.
- Contains responsive search ad JSON in headlines/descriptions columns.
- Data is STALE: last update ~2023-08, date range 2022-09-01 to 2023-09-17.
