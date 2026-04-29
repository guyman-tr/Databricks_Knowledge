# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Keywords_Pref

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads keyword-level performance report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | date | Fivetran source | date | Passthrough | Tier 2 |
| 2 | DateID | Fivetran source | date | DateToDateID(date) | Tier 2 |
| 3 | customer_id | Fivetran source | customer_id | Passthrough | Tier 2 |
| 4 | status | Fivetran source | ad_group_criterion_status | Rename | Tier 2 |
| 5 | impressions | Fivetran source | impressions | Passthrough | Tier 2 |
| 6 | quality_score | Fivetran source | quality_info_quality_score | Rename | Tier 2 |
| 7 | device | Fivetran source | device | Passthrough | Tier 2 |
| 8 | criteria | Fivetran source | keyword_text | Rename | Tier 2 |
| 9 | video_views | Fivetran source | video_views | Passthrough | Tier 2 |
| 10 | cost | Fivetran source | cost_micros | Rename (value in micros) | Tier 2 |
| 11 | external_customer_id | Fivetran source | customer_id | Duplicate | Tier 2 |
| 12 | search_budget_lost_top_impression_share | Fivetran source | search_budget_lost_top_impression_share | Passthrough | Tier 2 |
| 13 | account_currency_code | Fivetran source | customer_currency_code | Rename | Tier 2 |
| 14 | campaign_id | Fivetran source | campaign_id | Passthrough | Tier 2 |
| 15 | interactions | Fivetran source | interactions | Passthrough | Tier 2 |
| 16 | search_impression_share | Fivetran source | search_impression_share | Passthrough | Tier 2 |
| 17 | id | N/A | N/A | Column in DDL but NOT in SP INSERT (commented out) | Tier 4 |
| 18 | ad_group_id | Fivetran source | ad_group_id | Passthrough | Tier 2 |
| 19 | clicks | Fivetran source | clicks | Passthrough | Tier 2 |
| 20 | search_rank_lost_impression_share | Fivetran source | search_rank_lost_impression_share | Passthrough | Tier 2 |
| 21 | week | Fivetran source | week | Passthrough | Tier 2 |
| 22 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 23 | Conversions | Fivetran source | conversions | Passthrough | Tier 2 |
| 24 | KeywordMatchType | Fivetran source | keyword_match_type | Rename | Tier 2 |

## Lineage Notes

- Performance table — mostly passthrough columns (no CASE WHEN pivot).
- cost renamed from cost_micros — value is in Google Ads micros.
- quality_score renamed from quality_info_quality_score.
- id column exists in DDL but NOT in SP INSERT (commented out).
- Includes search impression share metrics for competitive analysis.
