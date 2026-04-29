# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Geo_Conv

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_geo_conv_new_api_conv_geo_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads geo-level conversion performance report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | date | Fivetran source | date | Passthrough | Tier 2 |
| 2 | DateID | Fivetran source | date | DateToDateID(date) function | Tier 2 |
| 3 | customer_id | Fivetran source | customer_id | Passthrough | Tier 2 |
| 4 | device | Fivetran source | device | Passthrough | Tier 2 |
| 5 | external_customer_id | Fivetran source | customer_id | Duplicate of customer_id | Tier 2 |
| 6 | region_criteria_id | N/A | N/A | Hardcoded NULL | Tier 2 |
| 7 | campaign_id | Fivetran source | campaign_id | Passthrough | Tier 2 |
| 8 | ad_group_id | Fivetran source | ad_group_id | Passthrough | Tier 2 |
| 9 | country_criteria_id | Fivetran source | country_criterion_id | Rename: country_criterion_id → country_criteria_id | Tier 2 |
| 10 | week | Fivetran source | week | Passthrough | Tier 2 |
| 11 | Registration | Fivetran source | Pivoted from conversion_action_name | SUM(all_conversions - view_through_conversions) WHERE 'Registration' | Tier 2 |
| 12 | V2 | Fivetran source | Pivoted | SUM WHERE 'V2 Status' | Tier 2 |
| 13 | FTD | Fivetran source | Pivoted | SUM WHERE 'FTD' | Tier 2 |
| 14 | MultipleDeposit | Fivetran source | Pivoted | SUM WHERE 'Multiple Deposit' | Tier 2 |
| 15 | FTDA | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'FTD' — conversion value | Tier 2 |
| 16 | MTDA | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'Multiple Deposit' | Tier 2 |
| 17 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 18 | android_reg | Fivetran source | Pivoted | SUM for Android 1st-gen app registration | Tier 2 |
| 19 | android_v2 | Fivetran source | Pivoted | SUM for Android 1st-gen app V2 | Tier 2 |
| 20 | android_ftd | Fivetran source | Pivoted | SUM for Android 1st-gen app FTD | Tier 2 |
| 21 | ios_reg | Fivetran source | Pivoted | SUM for iOS 1st-gen app registration | Tier 2 |
| 22 | ios_v2 | Fivetran source | Pivoted | SUM for iOS 1st-gen app V2 | Tier 2 |
| 23 | ios_ftd | Fivetran source | Pivoted | SUM for iOS 1st-gen app FTD | Tier 2 |

## Lineage Notes

- Conversion pivot from rows to columns using CASE WHEN on conversion_action_name.
- region_criteria_id is hardcoded to NULL (originally used, removed 2021-08-23 by Amir).
- external_customer_id is always equal to customer_id (duplicate assignment).
- DELETE+INSERT pattern with 90-day rolling window + year-ago floor.
- Grain: date × customer_id × device × campaign_id × ad_group_id × country_criterion_id × week.
