# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Geo_Pref

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_geo_perf_new_api_perf_geo_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads geo-level performance report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | date | Fivetran source | date | Passthrough | Tier 2 |
| 2 | DateID | Fivetran source | date | DateToDateID(date) function | Tier 2 |
| 3 | customer_id | Fivetran source | customer_id | Passthrough | Tier 2 |
| 4 | impressions | Fivetran source | impressions | Passthrough | Tier 2 |
| 5 | ad_group_status | Fivetran source | ad_group_status | Passthrough | Tier 2 |
| 6 | campaign_status | Fivetran source | campaign_status | Passthrough | Tier 2 |
| 7 | device | Fivetran source | device | Passthrough | Tier 2 |
| 8 | campaign_name | Fivetran source | campaign_name | Passthrough | Tier 2 |
| 9 | ad_group_name | Fivetran source | ad_group_name | Passthrough | Tier 2 |
| 10 | video_views | Fivetran source | video_views | Passthrough | Tier 2 |
| 11 | cost | Fivetran source | cost_micros | Rename: cost_micros → cost (value in micros) | Tier 2 |
| 12 | external_customer_id | Fivetran source | customer_id | Duplicate of customer_id | Tier 2 |
| 13 | region_criteria_id | N/A | N/A | Hardcoded NULL | Tier 2 |
| 14 | campaign_id | Fivetran source | campaign_id | Passthrough | Tier 2 |
| 15 | interactions | Fivetran source | interactions | Passthrough | Tier 2 |
| 16 | ad_group_id | Fivetran source | ad_group_id | Passthrough | Tier 2 |
| 17 | clicks | Fivetran source | clicks | Passthrough | Tier 2 |
| 18 | country_criteria_id | Fivetran source | country_criterion_id | Rename | Tier 2 |
| 19 | week | Fivetran source | week | Passthrough | Tier 2 |
| 20 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 21 | Conversions | Fivetran source | conversions | Passthrough | Tier 2 |

## Lineage Notes

- Performance table — mostly passthrough columns (no CASE WHEN pivot).
- cost column renamed from cost_micros — value is in Google Ads micros (divide by 1,000,000 for currency).
- region_criteria_id hardcoded NULL (removed 2021-08-23).
- DELETE+INSERT pattern with 90-day rolling window + year-ago floor.
