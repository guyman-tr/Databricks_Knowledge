# Lineage — BI_DB_dbo.BI_DB_Adwords_Search_Conv

## Source Objects

| # | Source Object | Type | Schema | Role | Wiki |
|---|--------------|------|--------|------|------|
| 1 | External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report | External Table | BI_DB_dbo | Primary source (Fivetran Google Ads search query conversion report) | — |
| 2 | SP_Adwords_Pref_Conv | Stored Procedure | BI_DB_dbo | Writer SP (Table #10 of 12). Monthly rolling DELETE+INSERT with CASE WHEN conversion pivot. | — |
| 3 | BI_DB_Adwords_Dictionary_Campaign | Table | BI_DB_dbo | FK target for campaign_id | — |
| 4 | BI_DB_Adwords_Dictionary_AdGroup | Table | BI_DB_dbo | FK target for ad_group_id | — |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | month | External_Bronze_Fivetran_adwords_search_conv_... | month | Passthrough | Tier 2 |
| 2 | customer_id | External_Bronze_Fivetran_adwords_search_conv_... | customer_id | Passthrough | Tier 2 |
| 3 | query | External_Bronze_Fivetran_adwords_search_conv_... | search_term | Rename | Tier 2 |
| 4 | device | External_Bronze_Fivetran_adwords_search_conv_... | device | Passthrough | Tier 2 |
| 5 | query_targeting_status | External_Bronze_Fivetran_adwords_search_conv_... | search_term_match_type | Rename (duplicate of query_match_type_with_variant) | Tier 2 |
| 6 | external_customer_id | External_Bronze_Fivetran_adwords_search_conv_... | customer_id | Duplicate of customer_id | Tier 2 |
| 7 | query_match_type_with_variant | External_Bronze_Fivetran_adwords_search_conv_... | search_term_match_type | Rename | Tier 2 |
| 8 | keyword_id | — | — | Not inserted by SP (commented out). Always NULL. | Tier 4 |
| 9 | account_currency_code | External_Bronze_Fivetran_adwords_search_conv_... | customer_currency_code | Rename | Tier 2 |
| 10 | campaign_id | External_Bronze_Fivetran_adwords_search_conv_... | campaign_id | Passthrough | Tier 2 |
| 11 | ad_group_id | External_Bronze_Fivetran_adwords_search_conv_... | ad_group_id | Passthrough | Tier 2 |
| 12 | final_url | External_Bronze_Fivetran_adwords_search_conv_... | ad_final_urls | Rename | Tier 2 |
| 13 | search_key | — | — | Not inserted by SP (commented out). Always NULL. | Tier 4 |
| 14 | Registration | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'Registration' THEN all_conversions - view_through_conversions ELSE 0 END) | Tier 2 |
| 15 | V2 | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'V2 Status' THEN all_conversions - view_through_conversions ELSE 0 END) | Tier 2 |
| 16 | FTD | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'FTD' THEN all_conversions - view_through_conversions ELSE 0 END) | Tier 2 |
| 17 | MultipleDeposit | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'Multiple Deposit' THEN all_conversions - view_through_conversions ELSE 0 END) | Tier 2 |
| 18 | FTDA | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions_value | SUM(CASE WHEN 'FTD' THEN all_conversions_value ELSE 0 END) | Tier 2 |
| 19 | MTDA | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions_value | SUM(CASE WHEN 'Multiple Deposit' THEN all_conversions_value ELSE 0 END) | Tier 2 |
| 20 | UpdateDate | SP_Adwords_Pref_Conv | GETDATE() | ETL-generated timestamp | Tier 5 |
| 21 | android_reg | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration' THEN ...) | Tier 2 |
| 22 | android_v2 | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(Android) Verification Level - 2' THEN ...) | Tier 2 |
| 23 | android_ftd | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(Android) FTD' THEN ...) | Tier 2 |
| 24 | ios_reg | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro Cryptocurrency Trading (iOS) registration' THEN ...) | Tier 2 |
| 25 | ios_v2 | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(iOS) Verification Level - 2' THEN ...) | Tier 2 |
| 26 | ios_ftd | External_Bronze_Fivetran_adwords_search_conv_... | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(iOS) FTD' THEN ...) | Tier 2 |
