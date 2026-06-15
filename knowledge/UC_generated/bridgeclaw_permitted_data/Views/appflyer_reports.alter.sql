-- =============================================================================
-- Databricks ALTER Script: main.bridgeclaw_permitted_data.appflyer_reports (VIEW)
-- Generated: 2026-06-10 | one-shot AppsFlyer deployment
-- Target: Unity Catalog VIEW comment + column comments
-- View definition: filtered subset of main.de_output.de_output_appsflyer_silver_reports
--                  WHERE dateid > 20260531
-- Syntax note: views use COMMENT ON COLUMN (ANSI) not ALTER TABLE ALTER COLUMN.
-- =============================================================================

-- ---- View Comment ----
ALTER VIEW main.bridgeclaw_permitted_data.appflyer_reports SET TBLPROPERTIES ('comment' = 'Permissioned PII-safe view over the AppsFlyer mobile-attribution fact. 33-column subset of main.de_output.de_output_appsflyer_silver_reports, filtered to dateid > 20260531. Drops the location detail columns (State / City / PostalCode / DMA / IP), the device-network columns (WIFI / Operator / Carrier / Language), all 5 SubParam columns, the AppType-version triplet (DeviceType already excluded), most device IDs (AdvertisingID / IDFA / IDFV / AndroidID / IMEI), HTTP attribution metadata (HTTPReferrer / OriginalURL / UserAgent / IsReceiptValidated / AttributionLookback / ReengagementWindow / IsPrimaryAttribution), and the multi-touch contributor chain. Keeps the attribution + campaign + event-revenue + retargeting columns plus the eToro pipeline fields. Use when restricted access requires keeping device-level PII out of the consumer''s reach. The dateid > 20260531 filter is a forward-cutover guard - this is a one-off view definition, not a deprecation signal for the gold path.');

-- ---- View Tags ----
ALTER VIEW main.bridgeclaw_permitted_data.appflyer_reports SET TAGS (
    'domain' = 'marketing_attribution',
    'object_type' = 'permissioned_view',
    'source_schema' = 'bridgeclaw_permitted_data',
    'underlying_table' = 'main.de_output.de_output_appsflyer_silver_reports',
    'filter' = 'dateid > 20260531',
    'pipeline' = 'one-shot-appsflyer-deploy',
    'pipeline_version' = '2026-06-10',
    'semantic_grade' = '4'
);

-- ---- View Column Comments (33 columns) ----
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.DateID IS 'Event date as YYYYMMDD integer. View filter: dateid > 20260531. (Tier 2 - eToro pipeline)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.EtoroReport IS 'AppsFlyer report-type partition: OrganicInstalls / Installs / InAppEvents. Always filter this column. See main.de_output.de_output_appsflyer_silver_reports for value semantics. (Tier 2 - eToro pipeline)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.EventSource IS 'How the event was reported: SDK or S2S. ~1M rows in the underlying fact carry malformed values - filter EventSource IN (''SDK'',''S2S''). (Tier 1 - AppsFlyer field event_source)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.AppsFlyerID IS 'AppsFlyer privacy-safe per-install device identifier. Joins to bronze_marketperformance_tracking_customer.AppsflyerID for CID resolution. (Tier 1 - AppsFlyer field appsflyer_id)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.CustomerUserID IS 'Hashed CID set by eToro at registration / login. Empty on Installs / OrganicInstalls. (Tier 1 - AppsFlyer field customer_user_id)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.EventTime IS 'Timestamp of the event occurrence. STRING. (Tier 1 - AppsFlyer field event_time)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.InstallTime IS 'Timestamp when the app install was first recorded. (Tier 1 - AppsFlyer field install_time)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.Partner IS 'Agency or partner identifier. (Tier 1 - AppsFlyer field af_prt)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.MediaSource IS 'The media source attributed to an event - ad network / channel. eToro values include googleadwords_int, Apple Search Ads, tiktokglobal_int, eToroWeb, restricted (iOS14 ATT bucket). (Tier 1 - AppsFlyer field media_source)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.Channel IS 'Sub-classifier within MediaSource. (Tier 1 - AppsFlyer field af_channel)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.Campaign IS 'Campaign name the user was exposed to. (Tier 1 - AppsFlyer field campaign)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.CampaignID IS 'Unique campaign identifier from the ad network. (Tier 1 - AppsFlyer field campaign_id)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.Adset IS 'Adset name within the campaign. (Tier 1 - AppsFlyer field af_adset)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.AdsetID IS 'Adset ID. (Tier 1 - AppsFlyer field af_adset_id)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.Ad IS 'Ad name - the exact creative shown to the user. (Tier 1 - AppsFlyer field af_ad)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.AdID IS 'Ad ID. (Tier 1 - AppsFlyer field af_ad_id)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.AdType IS 'Ad format type: banner, footer, interstitial, video, ClickToDownload. (Tier 1 - AppsFlyer field af_ad_type)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.Region IS 'AppsFlyer macro-region code (EU / AS / NA / SA / AF / AU). NOT eToro''s marketing-region SCD. (Tier 1 - AppsFlyer field region)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.CountryCode IS 'ISO 3166 alpha-2 country code. AppsFlyer convention: UK is used, NOT GB. (Tier 1 - AppsFlyer field country_code)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.Platform IS 'Mobile OS: android / ios. Filter Platform IN (''android'',''ios'',''None'') to drop GUID-shaped dirty values. (Tier 1 - AppsFlyer field platform)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.DeviceType IS 'Device form factor. AppsFlyer documents this as DEPRECATED Feb 2022 - replaced by device_model. (Tier 1 - AppsFlyer field device_type, deprecated)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.OSVersion IS 'Operating system version string. (Tier 1 - AppsFlyer field os_version)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.AppVersion IS 'eToro app version string. (Tier 1 - AppsFlyer field app_version)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.EventName IS 'Attribution event type or in-app event name. Top eToro values: install, Open Trade, Registration_S2S, FTD_S2S, Verification Level - 1/2/3, Redeposit_S2S. _S2S suffix = server-to-server postback (more reliable than SDK twin). (Tier 1 - AppsFlyer field event_name)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.EventValue IS 'JSON payload for in-app event parameters. Empty for install events. (Tier 1 - AppsFlyer field event_value)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.EventRevenue IS 'Revenue value in EventRevenueCurrency. STRING - cast before arithmetic. (Tier 1 - AppsFlyer field event_revenue)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.EventRevenueUSD IS 'Revenue converted to USD by AppsFlyer. (Tier 1 - AppsFlyer field event_revenue_usd)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.Date IS 'Event date - the date the install or in-app event occurred. NOT InstallTime for InAppEvents. (Tier 2 - eToro pipeline)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.CostModel IS 'Cost model: CPC / CPI / CPM / Other. (Tier 1 - AppsFlyer field af_cost_model)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.CostValue IS 'Cost amount in CostCurrency, up to 4 decimal digits. STRING. (Tier 1 - AppsFlyer field af_cost_value)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.CostCurrency IS 'ISO-4217 currency code, defaults to USD. (Tier 1 - AppsFlyer field af_cost_currency)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.IsRetargeting IS 'true / false flag. As of 2026-06 zero rows carry true - eToro is not running retargeting through the MMP integration. (Tier 1 - AppsFlyer field is_retargeting)';
COMMENT ON COLUMN main.bridgeclaw_permitted_data.appflyer_reports.RetargetingConversionType IS 'Re-engagement / Re-attribution. NULL across the eToro corpus while retargeting is dormant. (Tier 1 - AppsFlyer field retargeting_conversion_type)';

-- == LAST EXECUTION ==
-- Timestamp: 2026-06-10 13:03:33 UTC
-- Batch: appsflyer one-shot deploy (proposals/appsflyer_one_shot/deploy.py)
-- Statements: 33/35 succeeded
-- ====================
