# BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext — Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|---|---|---|---|
| 1 | AppsFlyer Raw Data Export API | External API | Data provider — raw mobile attribution events loaded externally | External |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | AttributedTouchType | AppsFlyer API | attributed_touch_type | Passthrough (raw varchar) | Tier 3 |
| 2 | AttributedTouchTime | AppsFlyer API | attributed_touch_time | Passthrough (raw varchar) | Tier 3 |
| 3 | InstallTime | AppsFlyer API | install_time | Passthrough (raw varchar) | Tier 3 |
| 4 | EventTime | AppsFlyer API | event_time | Passthrough (raw varchar) | Tier 3 |
| 5 | EventName | AppsFlyer API | event_name | Passthrough (raw varchar) | Tier 3 |
| 6 | EventValue | AppsFlyer API | event_value | Passthrough (raw varchar, JSON) | Tier 3 |
| 7 | EventRevenue | AppsFlyer API | event_revenue | Passthrough (raw varchar) | Tier 3 |
| 8 | EventRevenueCurrency | AppsFlyer API | event_revenue_currency | Passthrough (raw varchar) | Tier 3 |
| 9 | EventRevenueUSD | AppsFlyer API | event_revenue_usd | Passthrough (raw varchar) | Tier 3 |
| 10 | EventSource | AppsFlyer API | event_source | Passthrough (raw varchar) | Tier 3 |
| 11 | IsReceiptValidated | AppsFlyer API | is_receipt_validated | Passthrough (raw varchar, masked) | Tier 3 |
| 12 | Partner | AppsFlyer API | partner | Passthrough (raw varchar) | Tier 3 |
| 13 | MediaSource | AppsFlyer API | media_source | Passthrough (raw varchar) | Tier 3 |
| 14 | Channel | AppsFlyer API | channel | Passthrough (raw varchar) | Tier 3 |
| 15 | Keywords | AppsFlyer API | keywords | Passthrough (raw varchar) | Tier 3 |
| 16 | Campaign | AppsFlyer API | campaign | Passthrough (raw varchar) | Tier 3 |
| 17 | CampaignID | AppsFlyer API | campaign_id | Passthrough (raw varchar) | Tier 3 |
| 18 | Adset | AppsFlyer API | adset | Passthrough (raw varchar) | Tier 3 |
| 19 | AdsetID | AppsFlyer API | adset_id | Passthrough (raw varchar) | Tier 3 |
| 20 | Ad | AppsFlyer API | ad | Passthrough (raw varchar) | Tier 3 |
| 21 | AdID | AppsFlyer API | ad_id | Passthrough (raw varchar) | Tier 3 |
| 22 | AdType | AppsFlyer API | ad_type | Passthrough (raw varchar) | Tier 3 |
| 23 | SiteID | AppsFlyer API | site_id | Passthrough (raw varchar) | Tier 3 |
| 24 | SubSiteID | AppsFlyer API | sub_site_id | Passthrough (raw varchar) | Tier 3 |
| 25 | SubParam1 | AppsFlyer API | sub_param_1 | Passthrough (raw varchar) | Tier 3 |
| 26 | SubParam2 | AppsFlyer API | sub_param_2 | Passthrough (raw varchar) | Tier 3 |
| 27 | SubParam3 | AppsFlyer API | sub_param_3 | Passthrough (raw varchar) | Tier 3 |
| 28 | SubParam4 | AppsFlyer API | sub_param_4 | Passthrough (raw varchar) | Tier 3 |
| 29 | SubParam5 | AppsFlyer API | sub_param_5 | Passthrough (raw varchar) | Tier 3 |
| 30 | CostModel | AppsFlyer API | cost_model | Passthrough (raw varchar) | Tier 3 |
| 31 | CostValue | AppsFlyer API | cost_value | Passthrough (raw varchar) | Tier 3 |
| 32 | CostCurrency | AppsFlyer API | cost_currency | Passthrough (raw varchar) | Tier 3 |
| 33 | Contributor1Partner | AppsFlyer API | contributor_1_partner | Passthrough (raw varchar) | Tier 3 |
| 34 | Contributor1MediaSource | AppsFlyer API | contributor_1_media_source | Passthrough (raw varchar) | Tier 3 |
| 35 | Contributor1Campaign | AppsFlyer API | contributor_1_campaign | Passthrough (raw varchar) | Tier 3 |
| 36 | Contributor1TouchType | AppsFlyer API | contributor_1_touch_type | Passthrough (raw varchar) | Tier 3 |
| 37 | Contributor1TouchTime | AppsFlyer API | contributor_1_touch_time | Passthrough (raw varchar) | Tier 3 |
| 38 | Contributor2Partner | AppsFlyer API | contributor_2_partner | Passthrough (raw varchar) | Tier 3 |
| 39 | Contributor2MediaSource | AppsFlyer API | contributor_2_media_source | Passthrough (raw varchar) | Tier 3 |
| 40 | Contributor2Campaign | AppsFlyer API | contributor_2_campaign | Passthrough (raw varchar) | Tier 3 |
| 41 | Contributor2TouchType | AppsFlyer API | contributor_2_touch_type | Passthrough (raw varchar) | Tier 3 |
| 42 | Contributor2TouchTime | AppsFlyer API | contributor_2_touch_time | Passthrough (raw varchar) | Tier 3 |
| 43 | Contributor3Partner | AppsFlyer API | contributor_3_partner | Passthrough (raw varchar) | Tier 3 |
| 44 | Contributor3MediaSource | AppsFlyer API | contributor_3_media_source | Passthrough (raw varchar) | Tier 3 |
| 45 | Contributor3Campaign | AppsFlyer API | contributor_3_campaign | Passthrough (raw varchar) | Tier 3 |
| 46 | Contributor3TouchType | AppsFlyer API | contributor_3_touch_type | Passthrough (raw varchar) | Tier 3 |
| 47 | Contributor3TouchTime | AppsFlyer API | contributor_3_touch_time | Passthrough (raw varchar) | Tier 3 |
| 48 | Region | AppsFlyer API | region | Passthrough (raw varchar) | Tier 3 |
| 49 | CountryCode | AppsFlyer API | country_code | Passthrough (raw varchar) | Tier 3 |
| 50 | State | AppsFlyer API | state | Passthrough (raw varchar) | Tier 3 |
| 51 | City | AppsFlyer API | city | Passthrough (raw varchar, masked) | Tier 3 |
| 52 | PostalCode | AppsFlyer API | postal_code | Passthrough (raw varchar) | Tier 3 |
| 53 | DMA | AppsFlyer API | dma | Passthrough (raw varchar) | Tier 3 |
| 54 | IP | AppsFlyer API | ip | Passthrough (raw varchar) | Tier 3 |
| 55 | WIFI | AppsFlyer API | wifi | Passthrough (raw varchar) | Tier 3 |
| 56 | Operator | AppsFlyer API | operator | Passthrough (raw varchar) | Tier 3 |
| 57 | Carrier | AppsFlyer API | carrier | Passthrough (raw varchar) | Tier 3 |
| 58 | Language | AppsFlyer API | language | Passthrough (raw varchar) | Tier 3 |
| 59 | AppsFlyerID | AppsFlyer API | appsflyer_id | Passthrough (raw varchar) | Tier 3 |
| 60 | AdvertisingID | AppsFlyer API | advertising_id | Passthrough (raw varchar) | Tier 3 |
| 61 | IDFA | AppsFlyer API | idfa | Passthrough (raw varchar) | Tier 3 |
| 62 | AndroidID | AppsFlyer API | android_id | Passthrough (raw varchar) | Tier 3 |
| 63 | CustomerUserID | AppsFlyer API | customer_user_id | Passthrough (raw varchar) | Tier 3 |
| 64 | IMEI | AppsFlyer API | imei | Passthrough (raw varchar) | Tier 3 |
| 65 | IDFV | AppsFlyer API | idfv | Passthrough (raw varchar) | Tier 3 |
| 66 | Platform | AppsFlyer API | platform | Passthrough (raw varchar) | Tier 3 |
| 67 | DeviceType | AppsFlyer API | device_type | Passthrough (raw varchar) | Tier 3 |
| 68 | OSVersion | AppsFlyer API | os_version | Passthrough (raw varchar) | Tier 3 |
| 69 | AppVersion | AppsFlyer API | app_version | Passthrough (raw varchar) | Tier 3 |
| 70 | SDKVersion | AppsFlyer API | sdk_version | Passthrough (raw varchar) | Tier 3 |
| 71 | AppID | AppsFlyer API | app_id | Passthrough (raw varchar) | Tier 3 |
| 72 | AppName | AppsFlyer API | app_name | Passthrough (raw varchar) | Tier 3 |
| 73 | BundleID | AppsFlyer API | bundle_id | Passthrough (raw varchar) | Tier 3 |
| 74 | AttributionLookback | AppsFlyer API | attribution_lookback | Passthrough (raw varchar) | Tier 3 |
| 75 | ReengagementWindow | AppsFlyer API | reengagement_window | Passthrough (raw varchar) | Tier 3 |
| 76 | IsPrimaryAttribution | AppsFlyer API | is_primary_attribution | Passthrough (raw varchar) | Tier 3 |
| 77 | UserAgent | AppsFlyer API | user_agent | Passthrough (raw varchar) | Tier 3 |
| 78 | HTTPReferrer | AppsFlyer API | http_referrer | Passthrough (raw varchar) | Tier 3 |
| 79 | OriginalURL | AppsFlyer API | original_url | Passthrough (raw varchar) | Tier 3 |
| 80 | IsRetargeting | AppsFlyer API | is_retargeting | Passthrough (raw varchar) | Tier 3 |
| 81 | RetargetingConversionType | AppsFlyer API | retargeting_conversion_type | Passthrough (raw varchar) | Tier 3 |
| 82 | DateID | ETL process | — | Integer date key (YYYYMMDD format), added by the data load process | Tier 3 |
| 83 | Date | ETL process | — | Calendar date corresponding to DateID, added by the data load process | Tier 3 |
| 84 | EtoroAppID | ETL process | — | eToro-internal application identifier mapped from AppID/BundleID | Tier 3 |
| 85 | EtoroAppName | ETL process | — | eToro-internal application display name (e.g., 'OneApp Android', 'OneApp iOS') | Tier 3 |
| 86 | EtoroReport | ETL process | — | Report type classification (e.g., 'InAppEvents', 'OrganicInstalls') | Tier 3 |

## Downstream Consumers

| # | Consumer Object | Consumer Type | Relationship |
|---|---|---|---|
| 1 | BI_DB_dbo.BI_DB_AppFlyer_Reports | Table | SP_AppFlyer_Reports reads from _Ext and inserts into BI_DB_AppFlyer_Reports with minor transforms |
