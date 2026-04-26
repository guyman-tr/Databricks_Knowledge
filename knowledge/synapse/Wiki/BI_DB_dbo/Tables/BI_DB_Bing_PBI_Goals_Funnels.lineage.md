# Lineage: BI_DB_dbo.BI_DB_Bing_PBI_Goals_Funnels

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object** | BI_DB_Bing_PBI_Goals_Funnels |
| **Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_Bing_PBI |
| **Primary Source** | External_Fivetran_bingads_goals_and_funnels_daily_report |
| **Source Lake Path** | Bronze/Fivetran/bingads/goals_and_funnels_daily_report |
| **Source Type** | Fivetran connector (Microsoft Advertising / Bing Ads API) |
| **Upstream Wiki** | None — external third-party source |
| **UC Target** | _Not_Migrated |

## ETL Chain

```
Microsoft Advertising (Bing Ads API)
  |-- Fivetran bingads connector ---|
  v
Azure Data Lake Bronze/Fivetran/bingads/goals_and_funnels_daily_report (Parquet)
  |-- External_Fivetran_bingads_goals_and_funnels_daily_report ---|
  v
SP_Bing_PBI @date (DELETE by date + CASE-pivot INSERT)
  v
BI_DB_dbo.BI_DB_Bing_PBI_Goals_Funnels
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | date | External_Fivetran_bingads_goals_and_funnels_daily_report | date | Passthrough. WHERE date=@date filter | Tier 2 |
| 2 | account_id | External_Fivetran_bingads_goals_and_funnels_daily_report | account_id | Passthrough | Tier 2 |
| 3 | campaign_id | External_Fivetran_bingads_goals_and_funnels_daily_report | campaign_id | Passthrough | Tier 2 |
| 4 | ad_group_id | External_Fivetran_bingads_goals_and_funnels_daily_report | ad_group_id | Passthrough | Tier 2 |
| 5 | keyword_id | External_Fivetran_bingads_goals_and_funnels_daily_report | keyword_id | Passthrough | Tier 2 |
| 6 | device_type | External_Fivetran_bingads_goals_and_funnels_daily_report | device_type | Passthrough | Tier 2 |
| 7 | device_os | External_Fivetran_bingads_goals_and_funnels_daily_report | device_os | Passthrough | Tier 2 |
| 8 | Registration_General | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='Registration_General' THEN all_conversions-view_through_conversions END | Tier 2 |
| 9 | Bing_Multiple_Deposit_Tag | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='Bing Multiple Deposit Tag' THEN all_conversions-view_through_conversions END | Tier 2 |
| 10 | Bing_Multiple_Deposit | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='Bing Multiple Deposit' THEN all_conversions-view_through_conversions END | Tier 2 |
| 11 | FTD_General | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='FTD_General' THEN all_conversions-view_through_conversions END | Tier 2 |
| 12 | Registration_Brand | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='Registration_Brand' THEN all_conversions-view_through_conversions END | Tier 2 |
| 13 | FTD_Brand | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='FTD_Brand' THEN all_conversions-view_through_conversions END | Tier 2 |
| 14 | Bing_V2_Complete | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='Bing V2 Complete' THEN all_conversions-view_through_conversions END | Tier 2 |
| 15 | Bing_Registration | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='Bing Registration' THEN all_conversions-view_through_conversions END | Tier 2 |
| 16 | Bing_FTD | External_Fivetran_bingads_goals_and_funnels_daily_report | all_conversions, view_through_conversions, goal | CASE WHEN goal='Bing FTD' THEN all_conversions-view_through_conversions END | Tier 2 |
| 17 | _fivetran_synced | External_Fivetran_bingads_goals_and_funnels_daily_report | _fivetran_synced | Passthrough — Fivetran sync timestamp | Tier 2 |
| 18 | UpdateDate | — | — | GETDATE() at SP execution time | Tier 2 |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No upstream production wiki (external Fivetran source) |
| Tier 2 | 18 | All columns — SP code and external table DDL |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Source Tables Referenced

| Source Object | Type | Lake Path |
|---------------|------|-----------|
| External_Fivetran_bingads_goals_and_funnels_daily_report | External Table | Bronze/Fivetran/bingads/goals_and_funnels_daily_report |
