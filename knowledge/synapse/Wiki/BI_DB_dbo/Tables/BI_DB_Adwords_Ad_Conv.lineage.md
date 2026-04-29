# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Ad_Conv

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Fivetran_adwords_ad_conv_new_api_conv_ad_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads ad-level conversion performance report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | date | Fivetran source | date | Passthrough | Tier 2 |
| 2 | DateID | Fivetran source | date | DateToDateID(date) function | Tier 2 |
| 3 | customer_id | Fivetran source | customer_id | Passthrough | Tier 2 |
| 4 | campaign_id | Fivetran source | campaign_id | Passthrough | Tier 2 |
| 5 | device | Fivetran source | device | Passthrough | Tier 2 |
| 6 | id | Fivetran source | ad_id | Rename: ad_id → id | Tier 2 |
| 7 | ad_group_id | Fivetran source | ad_group_id | Passthrough | Tier 2 |
| 8 | week | Fivetran source | week | Passthrough | Tier 2 |
| 9 | external_customer_id | Fivetran source | customer_id | Duplicate of customer_id | Tier 2 |
| 10 | Registration | Fivetran source | Pivoted from conversion_action_name | SUM(all_conversions - view_through_conversions) WHERE 'Registration' | Tier 2 |
| 11 | V2 | Fivetran source | Pivoted | SUM WHERE 'V2 Status' | Tier 2 |
| 12 | FTD | Fivetran source | Pivoted | SUM WHERE 'FTD' | Tier 2 |
| 13 | MultipleDeposit | Fivetran source | Pivoted | SUM WHERE 'Multiple Deposit' | Tier 2 |
| 14 | FTDA | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'FTD' | Tier 2 |
| 15 | MTDA | Fivetran source | Pivoted | SUM(all_conversions_value) WHERE 'Multiple Deposit' | Tier 2 |
| 16 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 17-22 | android_reg/v2/ftd, ios_reg/v2/ftd | Fivetran source | Pivoted | SUM for Android/iOS app-specific conversion actions | Tier 2 |
| 23-28 | Regs_IOS2/V2_IOS2/FTD_IOS2, Regs_Android2/V2_android2/FTD_Android2 | Fivetran source | Pivoted | SUM for 2nd-gen app conversion actions | Tier 2 |

## Lineage Notes

- All data from Fivetran Google Ads connector (adwords_ad_conv schema).
- Conversion actions pivoted from rows to columns using CASE WHEN on conversion_action_name.
- Data is STALE: last update 2023-09-18, date range 2023-06-19 to 2023-09-16.
- SP uses DELETE+INSERT pattern for rolling 90-day window + year-ago floor.
