# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Keywords_Conv

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads keyword-level conversion performance report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | date | Fivetran source | date | Passthrough | Tier 2 |
| 2 | DateID | Fivetran source | date | DateToDateID(date) | Tier 2 |
| 3 | customer_id | Fivetran source | customer_id | Passthrough | Tier 2 |
| 4 | status | Fivetran source | ad_group_criterion_status | Rename | Tier 2 |
| 5 | device | Fivetran source | device | Passthrough | Tier 2 |
| 6 | criteria | Fivetran source | keyword_text | Rename: keyword_text → criteria | Tier 2 |
| 7 | external_customer_id | Fivetran source | customer_id | Duplicate | Tier 2 |
| 8 | account_currency_code | Fivetran source | customer_currency_code | Rename | Tier 2 |
| 9 | campaign_id | Fivetran source | campaign_id | Passthrough | Tier 2 |
| 10 | id | Fivetran source | N/A | Column in DDL but NOT populated (SP comments out --,id) | Tier 4 |
| 11 | ad_group_id | Fivetran source | ad_group_id | Passthrough | Tier 2 |
| 12 | week | Fivetran source | week | Passthrough | Tier 2 |
| 13 | Registration | Fivetran source | Pivoted | SUM(all_conversions - view_through_conversions) WHERE 'Registration' | Tier 2 |
| 14 | V2 | Fivetran source | Pivoted | SUM WHERE 'V2 Status' | Tier 2 |
| 15 | FTD | Fivetran source | Pivoted | SUM WHERE 'FTD' | Tier 2 |
| 16 | MultipleDeposit | Fivetran source | Pivoted | SUM WHERE 'Multiple Deposit' | Tier 2 |
| 17 | FTDA | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'FTD' | Tier 2 |
| 18 | MTDA | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'Multiple Deposit' | Tier 2 |
| 19 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 20-22 | android_reg/v2/ftd | Fivetran source | Pivoted | SUM for 1st-gen Android app actions | Tier 2 |
| 23-25 | ios_reg/v2/ftd | Fivetran source | Pivoted | SUM for 1st-gen iOS app actions | Tier 2 |
| 26 | LTV_Count | Fivetran source | Pivoted | SUM WHERE 'LTV-30Day' (count) | Tier 2 |
| 27 | LTV_Value | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'LTV-30Day' | Tier 2 |
| 28 | KeywordMatchType | Fivetran source | keyword_match_type | Rename | Tier 2 |
| 29-31 | Regs_IOS2/V2_IOS2/FTD_IOS2 | Fivetran source | Pivoted | SUM for 2nd-gen iOS app | Tier 2 |
| 32-34 | Regs_Android2/V2_android2/FTD_Android2 | Fivetran source | Pivoted | SUM for 2nd-gen Android app | Tier 2 |
| 35-38 | OpenTrade_And/OpenTrade_iOS/OpenTrade_iOS2/OpenTrade | Fivetran source | Pivoted | SUM for Open Trade conversion actions | Tier 2 |

## Lineage Notes

- Widest conversion table in the cluster (38 columns).
- Includes LTV columns (added 2022-07-14 by Eti) and OpenTrade columns unique to this table.
- KeywordMatchType added 2022-07-19 by Eti.
- id column is in DDL but NOT populated (commented out in SP INSERT).
- Grain: date × customer_id × status × device × keyword_text × currency × campaign_id × ad_group_id × week × keyword_match_type.
