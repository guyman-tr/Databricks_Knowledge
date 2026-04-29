# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Search_Conv

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads search query conversion report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | month | Fivetran source | month | Passthrough — monthly grain (not daily) | Tier 2 |
| 2 | customer_id | Fivetran source | customer_id | Passthrough | Tier 2 |
| 3 | query | Fivetran source | search_term | Rename: search_term → query | Tier 2 |
| 4 | device | Fivetran source | device | Passthrough | Tier 2 |
| 5 | query_targeting_status | Fivetran source | search_term_match_type | Rename — describes how the search term matched | Tier 2 |
| 6 | external_customer_id | Fivetran source | customer_id | Duplicate | Tier 2 |
| 7 | query_match_type_with_variant | Fivetran source | search_term_match_type | Same column as query_targeting_status (duplicate assignment) | Tier 2 |
| 8 | keyword_id | Fivetran source | N/A | Column in DDL but NOT in SP INSERT (commented out) | Tier 4 |
| 9 | account_currency_code | Fivetran source | customer_currency_code | Rename | Tier 2 |
| 10 | campaign_id | Fivetran source | campaign_id | Passthrough | Tier 2 |
| 11 | ad_group_id | Fivetran source | ad_group_id | Passthrough | Tier 2 |
| 12 | final_url | Fivetran source | ad_final_urls | Rename: ad_final_urls → final_url | Tier 2 |
| 13 | search_key | N/A | N/A | Column in DDL but NOT in SP INSERT (commented out) | Tier 4 |
| 14 | Registration | Fivetran source | Pivoted | SUM(all_conversions - view_through_conversions) WHERE 'Registration' | Tier 2 |
| 15 | V2 | Fivetran source | Pivoted | SUM WHERE 'V2 Status' | Tier 2 |
| 16 | FTD | Fivetran source | Pivoted | SUM WHERE 'FTD' | Tier 2 |
| 17 | MultipleDeposit | Fivetran source | Pivoted | SUM WHERE 'Multiple Deposit' | Tier 2 |
| 18 | FTDA | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'FTD' | Tier 2 |
| 19 | MTDA | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'Multiple Deposit' | Tier 2 |
| 20 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 21 | android_reg | Fivetran source | Pivoted | SUM for 1st-gen Android app registration | Tier 2 |
| 22 | android_v2 | Fivetran source | Pivoted | SUM for 1st-gen Android app V2 | Tier 2 |
| 23 | android_ftd | Fivetran source | Pivoted | SUM for 1st-gen Android app FTD | Tier 2 |
| 24 | ios_reg | Fivetran source | Pivoted | SUM for 1st-gen iOS app registration | Tier 2 |
| 25 | ios_v2 | Fivetran source | Pivoted | SUM for 1st-gen iOS app V2 | Tier 2 |
| 26 | ios_ftd | Fivetran source | Pivoted | SUM for 1st-gen iOS app FTD | Tier 2 |

## Lineage Notes

- Monthly grain (not daily) — uses month column as time dimension and GROUP BY key.
- DELETE+INSERT with 4-month rolling window (not 90 days like daily tables) + year-ago floor.
- query_targeting_status and query_match_type_with_variant both map from search_term_match_type (duplicate columns).
- keyword_id and search_key are in DDL but NOT populated by SP (commented out).
- HASH(customer_id) distribution — only Adwords table with hash distribution.
- Grain: month × customer_id × search_term × device × search_term_match_type × currency × campaign_id × ad_group_id × ad_final_urls.
