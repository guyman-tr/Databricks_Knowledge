# Lineage — BI_DB_dbo.BI_DB_Adwords_Keywords_Pref

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|-------------|
| 1 | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | External Table | BI_DB_dbo | Synapse | Direct source (Fivetran Google Ads keywords performance report) |
| 2 | SP_Adwords_Pref_Conv | Stored Procedure | BI_DB_dbo | Synapse | Writer SP (Table #3 of 12) |
| 3 | BI_DB_Adwords_Dictionary_Campaign | Table | BI_DB_dbo | Synapse | FK target for campaign_id |
| 4 | BI_DB_Adwords_Dictionary_AdGroup | Table | BI_DB_dbo | Synapse | FK target for ad_group_id |
| 5 | BI_DB_Adwords_Keywords_Conv | Table | BI_DB_dbo | Synapse | Conversion counterpart (join on date, customer_id, device, criteria, campaign_id, ad_group_id, week, KeywordMatchType) |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | date | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | date | Passthrough | Tier 2 |
| 2 | DateID | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | date | DateToDateID(date) | Tier 2 |
| 3 | customer_id | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | customer_id | Passthrough | Tier 2 |
| 4 | status | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | ad_group_criterion_status | Rename | Tier 2 |
| 5 | impressions | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | impressions | Passthrough | Tier 2 |
| 6 | quality_score | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | quality_info_quality_score | Rename | Tier 2 |
| 7 | device | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | device | Passthrough | Tier 2 |
| 8 | criteria | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | keyword_text | Rename | Tier 2 |
| 9 | video_views | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | video_views | Passthrough | Tier 2 |
| 10 | cost | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | cost_micros | Rename (value unchanged — still in micros) | Tier 2 |
| 11 | external_customer_id | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | customer_id | Duplicate of customer_id | Tier 2 |
| 12 | search_budget_lost_top_impression_share | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | search_budget_lost_top_impression_share | Passthrough | Tier 2 |
| 13 | account_currency_code | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | customer_currency_code | Rename | Tier 2 |
| 14 | campaign_id | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | campaign_id | Passthrough | Tier 2 |
| 15 | interactions | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | interactions | Passthrough | Tier 2 |
| 16 | search_impression_share | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | search_impression_share | Passthrough | Tier 2 |
| 17 | id | N/A | N/A | NOT populated — SP comments out this column. Always NULL. | Tier 4 |
| 18 | ad_group_id | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | ad_group_id | Passthrough | Tier 2 |
| 19 | clicks | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | clicks | Passthrough | Tier 2 |
| 20 | search_rank_lost_impression_share | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | search_rank_lost_impression_share | Passthrough | Tier 2 |
| 21 | week | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | week | Passthrough | Tier 2 |
| 22 | UpdateDate | SP_Adwords_Pref_Conv | GETDATE() | ETL-generated timestamp | Tier 5 |
| 23 | Conversions | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | conversions | Passthrough | Tier 2 |
| 24 | KeywordMatchType | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | keyword_match_type | Rename | Tier 2 |
