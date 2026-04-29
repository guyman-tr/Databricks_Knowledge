# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_new_api_conversion_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads campaign-level conversion performance report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | date | Fivetran source | date | Passthrough | Tier 2 |
| 2 | DateID | Fivetran source | date | DateToDateID(date) function — YYYYMMDD int | Tier 2 |
| 3 | campaign_id | Fivetran source | id | Rename: id → campaign_id | Tier 2 |
| 4 | campaign_name | Fivetran source | name | Rename: name → campaign_name | Tier 2 |
| 5 | customer_id | Fivetran source | customer_id | Passthrough — Google Ads account ID | Tier 2 |
| 6 | labels | Fivetran source | labels | Passthrough — campaign labels JSON array | Tier 2 |
| 7 | Registration | Fivetran source | Pivoted from conversion_action_name | SUM(all_conversions - view_through_conversions) WHERE 'Registration' | Tier 2 |
| 8 | V2 | Fivetran source | Pivoted | SUM WHERE 'V2 Status' | Tier 2 |
| 9 | FTD | Fivetran source | Pivoted | SUM WHERE 'FTD' | Tier 2 |
| 10 | MultipleDeposit | Fivetran source | Pivoted | SUM WHERE 'Multiple Deposit' | Tier 2 |
| 11 | Android_FirstOpen | Fivetran source | Pivoted | SUM WHERE 'eToro - Invest in stocks, crypto & trade CFDs (Android) first_open' | Tier 2 |
| 12 | Android_FTD | Fivetran source | Pivoted | SUM WHERE '...(Android) FTD' | Tier 2 |
| 13 | Android_Redeposit | Fivetran source | Pivoted | SUM WHERE '...(Android) Redeposit' | Tier 2 |
| 14 | Android_Registration | Fivetran source | Pivoted | SUM WHERE '...(Android) registration' | Tier 2 |
| 15 | Android_V2 | Fivetran source | Pivoted | SUM WHERE '...(Android) Verification Level - 2' | Tier 2 |
| 16 | iOS_FirstOpen | Fivetran source | Pivoted | SUM WHERE 'eToro Cryptocurrency Trading (iOS) first_open' | Tier 2 |
| 17 | iOS_FTD | Fivetran source | Pivoted | SUM WHERE '...(iOS) FTD' | Tier 2 |
| 18 | iOS_Redeposit | Fivetran source | Pivoted | SUM WHERE '...(iOS) Redeposit' | Tier 2 |
| 19 | iOS_Registration | Fivetran source | Pivoted | SUM WHERE '...(iOS) registration' | Tier 2 |
| 20 | iOS_V2 | Fivetran source | Pivoted | SUM WHERE '...(iOS) Verification Level - 2' | Tier 2 |
| 21 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 22 | Regs_IOS2 | Fivetran source | Pivoted | SUM WHERE 'eToro: Crypto. Stocks. Social. (iOS) registration' | Tier 2 |
| 23 | V2_IOS2 | Fivetran source | Pivoted | SUM WHERE '...(iOS) Verification Level - 2' | Tier 2 |
| 24 | FTD_IOS2 | Fivetran source | Pivoted | SUM WHERE '...(iOS) FTD' | Tier 2 |
| 25 | Regs_Android2 | Fivetran source | Pivoted | SUM WHERE 'eToro: Investing made social (Android) registration' | Tier 2 |
| 26 | V2_android2 | Fivetran source | Pivoted | SUM WHERE '...(Android) Verification Level - 2' | Tier 2 |
| 27 | FTD_Android2 | Fivetran source | Pivoted | SUM WHERE '...(Android) FTD' | Tier 2 |
| 28 | Device | Fivetran source | device | Passthrough — DESKTOP, MOBILE, TABLET, CONNECTED_TV | Tier 2 |

## Lineage Notes

- All data from Fivetran Google Ads connector (adwords_new_api schema).
- Conversion actions pivoted from rows to columns using CASE WHEN on conversion_action_name.
- Data is STALE: last update 2023-09-18, date range 2023-06-19 to 2023-09-16.
- SP uses DELETE+INSERT pattern for rolling 90-day window + year-ago floor.
- campaign_id and campaign_name map from Fivetran's `id` and `name` columns (campaign-level report).
- No FTDA/MTDA value columns in this table (unlike Ad_Conv and Geo_Conv).
- Includes full app lifecycle tracking: FirstOpen, Registration, V2, FTD, Redeposit for Android/iOS 1st-gen apps.
