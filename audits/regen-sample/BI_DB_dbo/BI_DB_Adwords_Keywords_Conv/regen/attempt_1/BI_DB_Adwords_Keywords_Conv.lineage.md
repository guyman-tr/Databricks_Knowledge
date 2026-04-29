# Lineage — BI_DB_dbo.BI_DB_Adwords_Keywords_Conv

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|-------------|
| 1 | External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report | External Table | BI_DB_dbo | Synapse | Primary source (Fivetran Google Ads keyword conversion report) |
| 2 | SP_Adwords_Pref_Conv | Stored Procedure | BI_DB_dbo | Synapse | Writer SP (Table #6 of 12) |
| 3 | BI_DB_Adwords_Dictionary_Campaign | Table | BI_DB_dbo | Synapse | FK target for campaign_id |
| 4 | BI_DB_Adwords_Dictionary_AdGroup | Table | BI_DB_dbo | Synapse | FK target for ad_group_id |
| 5 | BI_DB_Adwords_Keywords_Pref | Table | BI_DB_dbo | Synapse | Performance counterpart (same keyword grain, joined on date+customer_id+device+criteria+campaign_id+ad_group_id+week+KeywordMatchType) |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | date | External_Bronze_Fivetran_adwords_keywords_conv | date | Passthrough | Tier 2 |
| 2 | DateID | External_Bronze_Fivetran_adwords_keywords_conv | date | DateToDateID(date) | Tier 2 |
| 3 | customer_id | External_Bronze_Fivetran_adwords_keywords_conv | customer_id | Passthrough | Tier 2 |
| 4 | status | External_Bronze_Fivetran_adwords_keywords_conv | ad_group_criterion_status | Rename | Tier 2 |
| 5 | device | External_Bronze_Fivetran_adwords_keywords_conv | device | Passthrough | Tier 2 |
| 6 | criteria | External_Bronze_Fivetran_adwords_keywords_conv | keyword_text | Rename | Tier 2 |
| 7 | external_customer_id | External_Bronze_Fivetran_adwords_keywords_conv | customer_id | Duplicate of customer_id | Tier 2 |
| 8 | account_currency_code | External_Bronze_Fivetran_adwords_keywords_conv | customer_currency_code | Rename | Tier 2 |
| 9 | campaign_id | External_Bronze_Fivetran_adwords_keywords_conv | campaign_id | Passthrough | Tier 2 |
| 10 | id | — | — | NOT populated (commented out in SP) | Tier 4 |
| 11 | ad_group_id | External_Bronze_Fivetran_adwords_keywords_conv | ad_group_id | Passthrough | Tier 2 |
| 12 | week | External_Bronze_Fivetran_adwords_keywords_conv | week | Passthrough | Tier 2 |
| 13 | Registration | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'Registration' THEN all_conversions - view_through_conversions ELSE 0) | Tier 2 |
| 14 | V2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'V2 Status' THEN ...) | Tier 2 |
| 15 | FTD | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'FTD' THEN ...) | Tier 2 |
| 16 | MultipleDeposit | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'Multiple Deposit' THEN ...) | Tier 2 |
| 17 | FTDA | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions_value | SUM(CASE WHEN 'FTD' THEN all_conversions_value ELSE 0) | Tier 2 |
| 18 | MTDA | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions_value | SUM(CASE WHEN 'Multiple Deposit' THEN all_conversions_value ELSE 0) | Tier 2 |
| 19 | UpdateDate | SP_Adwords_Pref_Conv | GETDATE() | ETL timestamp | Tier 5 |
| 20 | android_reg | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration' THEN ...) | Tier 2 |
| 21 | android_v2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(Android) Verification Level - 2' THEN ...) | Tier 2 |
| 22 | android_ftd | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(Android) FTD' THEN ...) | Tier 2 |
| 23 | ios_reg | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro Cryptocurrency Trading (iOS) registration' THEN ...) | Tier 2 |
| 24 | ios_v2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(iOS) Verification Level - 2' THEN ...) | Tier 2 |
| 25 | ios_ftd | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(iOS) FTD' THEN ...) | Tier 2 |
| 26 | LTV_Count | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'LTV-30Day' THEN all_conversions - view_through_conversions ELSE 0) | Tier 2 |
| 27 | LTV_Value | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions_value | SUM(CASE WHEN 'LTV-30Day' THEN all_conversions_value ELSE 0) | Tier 2 |
| 28 | KeywordMatchType | External_Bronze_Fivetran_adwords_keywords_conv | keyword_match_type | Rename | Tier 2 |
| 29 | Regs_IOS2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro: Crypto. Stocks. Social. (iOS) registration' THEN ...) — no ELSE 0 | Tier 2 |
| 30 | V2_IOS2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(iOS) Verification Level - 2' THEN ...) — no ELSE 0 | Tier 2 |
| 31 | FTD_IOS2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(iOS) FTD' THEN ...) — no ELSE 0 | Tier 2 |
| 32 | Regs_Android2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro: Investing made social (Android) registration' THEN ...) — no ELSE 0 | Tier 2 |
| 33 | V2_android2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(Android) Verification Level - 2' THEN ...) — no ELSE 0 | Tier 2 |
| 34 | FTD_Android2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN '...(Android) FTD' THEN ...) — no ELSE 0 | Tier 2 |
| 35 | OpenTrade_And | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro: Investing made social (Android) Open Trade' THEN ...) — no ELSE 0 | Tier 2 |
| 36 | OpenTrade_iOS | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro: Crypto. Stocks. Social. (iOS) Open Trade' THEN ...) — no ELSE 0 | Tier 2 |
| 37 | OpenTrade_iOS2 | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'eToro: Investing made social (iOS) Open Trade' THEN ...) — no ELSE 0 | Tier 2 |
| 38 | OpenTrade | External_Bronze_Fivetran_adwords_keywords_conv | conversion_action_name + all_conversions + view_through_conversions | SUM(CASE WHEN 'Open Trade' THEN ...) — no ELSE 0 | Tier 2 |
