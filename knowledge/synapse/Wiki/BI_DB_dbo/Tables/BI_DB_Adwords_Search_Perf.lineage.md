# BI_DB_dbo.BI_DB_Adwords_Search_Perf — Column Lineage

## Source Objects

| Source Table | Source Type | Relationship |
|---|---|---|
| External_Bronze_Fivetran_adwords_search_perf_new_api_perf_search_query_performance_report | External Table (Fivetran Google Ads) | Primary source — search query performance report |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| month | External_Bronze_Fivetran_adwords_search_perf... | month | Passthrough |
| customer_id | External_Bronze_Fivetran_adwords_search_perf... | customer_id | Passthrough |
| query | External_Bronze_Fivetran_adwords_search_perf... | search_term | Rename: search_term → query |
| device | External_Bronze_Fivetran_adwords_search_perf... | device | Passthrough |
| query_targeting_status | — | — | NOT INSERTED by SP — always NULL |
| external_customer_id | External_Bronze_Fivetran_adwords_search_perf... | customer_id | Duplicate of customer_id (same value) |
| query_match_type_with_variant | External_Bronze_Fivetran_adwords_search_perf... | search_term_match_type | Rename: search_term_match_type → query_match_type_with_variant |
| keyword_id | — | — | NOT INSERTED by SP �� always NULL |
| account_currency_code | External_Bronze_Fivetran_adwords_search_perf... | customer_currency_code | Rename: customer_currency_code → account_currency_code |
| ad_group_id | External_Bronze_Fivetran_adwords_search_perf... | ad_group_id | Passthrough |
| search_key | — | — | NOT INSERTED by SP — always NULL |
| impressions | External_Bronze_Fivetran_adwords_search_perf... | impressions | SUM aggregation by month/customer/query/device/match_type/currency/ad_group |
| top_impressions | External_Bronze_Fivetran_adwords_search_perf... | top_impression_percentage * impressions | SUM(top_impression_percentage * impressions) — computed weighted sum |
| clicks | External_Bronze_Fivetran_adwords_search_perf... | clicks | SUM aggregation |
| cost | External_Bronze_Fivetran_adwords_search_perf... | cost_micros | SUM(cost_micros) — value is in MICROS (divide by 1,000,000 for currency units) |
| UpdateDate | — | GETDATE() | ETL-generated timestamp at load time |
