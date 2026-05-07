-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_AppFlyer_Reports
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports SET TBLPROPERTIES (
    'comment' = 'BI_DB_AppFlyer_Reports'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AttributedTouchType COMMENT 'Attribution model: `click` (user clicked an ad), `impression` (view-through attribution), or empty/NULL (organic - no paid touch). 88.4M empty rows (organic), 31.8M click, 8.0M impression.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AttributedTouchTime COMMENT 'Timestamp of the attributed ad click or impression. NULL for organic installs (SP converts AppFlyer ''None'' string -> SQL NULL).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN InstallTime COMMENT 'Timestamp when the app was installed. Present on all rows (install events and in-app events alike). For InAppEvents, this is the original install date - may be far in the past.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AttributionLookback COMMENT 'AppFlyer attribution lookback window setting active at the time of attribution (e.g., `''1d''`, `''7d''`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN ReengagementWindow COMMENT 'AppFlyer re-engagement window for retargeting campaigns.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IsPrimaryAttribution COMMENT '`''true''` / `''false''` string. Indicates whether this is the primary attributed source (vs a re-engagement event). SP normalizes all non-''1'' values to ''false''.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IsRetargeting COMMENT '`''true''` / `''false''` string. Whether this event is from a retargeting (re-engagement) campaign rather than new user acquisition.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN RetargetingConversionType COMMENT 'For retargeting events: the conversion type (e.g., `re-engagement`, `re-attribution`). NULL for non-retargeting rows.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Partner COMMENT 'AppFlyer partner agency or integrated partner name.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN MediaSource COMMENT 'Attribution source - ad network or channel. Examples: `googleadwords_int` (Google UAC), `bytedanceglobal_int` (TikTok), `Facebook Ads`, `eToroWeb` (web-to-app redirect), `Organic`, `restricted`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Channel COMMENT 'Sub-channel within the media source (e.g., `ACI_Search`, `GoogleSearch`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Keywords COMMENT 'Search keywords associated with the paid campaign (for search campaigns).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Campaign COMMENT 'Campaign name as reported by AppFlyer. Format varies by network.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CampaignID COMMENT 'Numeric campaign identifier from the ad network.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Adset COMMENT 'Ad set name within the campaign.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AdsetID COMMENT 'Ad set numeric identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Ad COMMENT 'Individual ad creative name or description.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AdID COMMENT 'Ad creative numeric identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AdType COMMENT 'Ad format type (e.g., `ClickToDownload`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN SiteID COMMENT 'Publisher site identifier (for DSP/network buys).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN SubSiteID COMMENT 'Sub-publisher identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CostModel COMMENT 'Pricing model for this placement (CPC, CPM, CPA, etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CostValue COMMENT 'Cost amount per unit in the cost model.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CostCurrency COMMENT 'Currency of the cost value.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1Partner COMMENT 'Partner of the first contributing (non-attributed) touch.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1MediaSource COMMENT 'Media source of contributing touch 1.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1Campaign COMMENT 'Campaign of contributing touch 1.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1TouchType COMMENT 'Touch type of contributing touch 1 (click/impression).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1TouchTime COMMENT 'Timestamp of contributing touch 1, stored as varchar. SP converts ''None''/''USD''/''usd'' -> NULL.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2Partner COMMENT 'Partner of contributing touch 2.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2MediaSource COMMENT 'Media source of contributing touch 2.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2Campaign COMMENT 'Campaign of contributing touch 2.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2TouchType COMMENT 'Touch type of contributing touch 2.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2TouchTime COMMENT 'Timestamp of contributing touch 2, stored as varchar. Same NULL conversion as Contributor1TouchTime.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor3Partner COMMENT 'Partner of contributing touch 3.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor3MediaSource COMMENT 'Media source of contributing touch 3.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor3Campaign COMMENT 'Campaign of contributing touch 3.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor3TouchType COMMENT 'Touch type of contributing touch 3.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Region COMMENT 'AppFlyer macro-region code (e.g., `EU`, `AS`, `NA`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CountryCode COMMENT 'ISO-2 country code. SP applies `CASE WHEN ''UK'' THEN ''GB''` standardization (unlike `BI_DB_AppFlyer_Geo` which does not).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN State COMMENT 'State or province (where available).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN City COMMENT '**DDM-masked** with `default()` function. Shows as `''xxxx''` to non-privileged users. Contains the city of the device at install/event time.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN PostalCode COMMENT 'Postal/ZIP code of the device.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN DMA COMMENT 'DMA (Designated Market Area) code - US-only market area identifier. ''None'' for non-US.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Operator COMMENT 'Mobile network operator name (e.g., ''Vodafone'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Carrier COMMENT 'Mobile carrier identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN WIFI COMMENT '`''true''` / `''false''` string. Whether the device was on Wi-Fi at the time of the event.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AppsFlyerID COMMENT 'AppFlyer''s unique device+install identifier. Primary key at AppFlyer''s system level - identifies a specific install on a specific device.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AdvertisingID COMMENT 'Android GAID (Google Advertising ID) - device-level advertising identifier for Android.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IDFA COMMENT 'iOS IDFA (Identifier for Advertisers) - device-level advertising identifier for iOS. May be empty post-iOS14 ATT framework changes.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IDFV COMMENT 'iOS IDFV (Identifier for Vendor) - app-level device identifier for iOS.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AndroidID COMMENT 'Android hardware device ID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IMEI COMMENT 'Device IMEI number. Typically empty for modern devices (IMEI collection restricted).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CustomerUserID COMMENT 'Hashed eToro customer identifier passed to AppFlyer at registration/login. Links AppFlyer events to eToro users. Present on InAppEvents for registered users; empty on raw installs.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Platform COMMENT 'Mobile OS: `''android''` or `''ios''`. ~75% android, ~23% ios; ~2% None (unknown/legacy).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN DeviceType COMMENT 'Device form factor (phone, tablet). Often empty.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN OSVersion COMMENT 'Operating system version string (e.g., `''13''`, `''16.1.1''`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AppVersion COMMENT 'eToro app version string (e.g., `''651.114.0''`, `''618.0.0''`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN SDKVersion COMMENT 'AppFlyer SDK version embedded in the app (e.g., `''v6.12.2''`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AppID COMMENT 'App store identifier (Android: `''com.etoro.openbook''`; iOS: `''id674984916''`). Uses dot notation (native format), unlike `EtoroAppID`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AppName COMMENT 'App store display name at the time of the event. Not a constant - changed over time (e.g., `''eToro: Investing made social''` -> `''eToro: Trade. Invest. Connect.''`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN BundleID COMMENT 'iOS/Android bundle identifier. Same value as `AppID`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Language COMMENT 'Device language setting (e.g., `''Deutsch''`, `''English''`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN UserAgent COMMENT 'HTTP user agent string from the attribution redirect. Often empty.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventName COMMENT 'Name of the event as reported by AppFlyer. For install rows: `''install''`. For InAppEvents: business event names such as `''Open Trade''` (24.6M), `''Registration_S2S''` (2.1M), `''Redeposit_S2S''` (2.1M), `''registration''` (1.9M), `''Verification Level - 1/2/3''`, `''Redeposit''`, `''FTD_S2S''`. Suffix `_S2S` = server-to-server event reported by eToro backend (more reliable than SDK events).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventTime COMMENT 'Timestamp string of when the in-app event fired (stored as varchar, not cast to datetime). For install events, same as `InstallTime`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventValue COMMENT 'JSON payload for in-app events containing AppFlyer event parameters. Example: `{"af_content":"Bitcoin","af_content_type":"Crypto","af_content_id":"100000","is_copy":"False","af_revenue":"14"}`. Empty for install events.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventRevenue COMMENT 'Revenue amount associated with this event in the reported currency. Populated for trade events (e.g., `''14''`, `''250''`, `''2244''`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventRevenueCurrency COMMENT 'Currency of EventRevenue (typically `''USD''`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventRevenueUSD COMMENT 'Revenue converted to USD. Same value as EventRevenue when currency is already USD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventSource COMMENT 'How the event was reported: `''SDK''` (AppFlyer SDK on device, ~95M rows) or `''S2S''` (server-to-server from eToro backend, ~31.5M rows). ~1M rows have garbled values (malformed JSON fragments from upstream AppFlyer export data quality issues).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IsReceiptValidated COMMENT 'AppFlyer receipt validation result for in-app purchases. Typically empty (most events are not app-store purchases).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN HTTPReferrer COMMENT 'HTTP referrer URL from the AppFlyer attribution redirect. Truncated to 4000 chars by SP (`LEFT([HTTPReferrer], 4000)`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN OriginalURL COMMENT 'Original deep link URL used in the attribution (e.g., `etoro://markets/gold`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN DateID COMMENT 'Event date as YYYYMMDD integer. ETL partition key used by SP for DELETE+INSERT targeting. `DateID = Date` in YYYYMMDD format.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Date COMMENT 'Event date (the date on which this install or in-app event occurred). **Not the install date** for InAppEvents - may differ from `InstallTime` significantly.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EtoroAppID COMMENT 'AppFlyer app identifier: `''com_etoro_openbook''` (Android, using underscore separator) or `''id674984916''` (iOS).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EtoroAppName COMMENT 'Human-readable platform label: `''OneApp Android''` or `''OneApp iOS''`. Set by the AppFlyer export config; consistent within this table.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EtoroReport COMMENT 'AppFlyer report type - the key partition dimension. Values: `''OrganicInstalls''` (86.3M), `''InAppEvents''` (35.6M), `''Installs''` (6.8M). Always filter by this column to avoid mixing event types.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN UpdateDate COMMENT '**Always NULL.** Column exists in DDL but is not in the SP INSERT list - never populated.';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AttributedTouchType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AttributedTouchTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN InstallTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AttributionLookback SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN ReengagementWindow SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IsPrimaryAttribution SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IsRetargeting SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN RetargetingConversionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Partner SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN MediaSource SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Keywords SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Campaign SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CampaignID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Adset SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AdsetID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Ad SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AdID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AdType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN SiteID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN SubSiteID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CostModel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CostValue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CostCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1Partner SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1MediaSource SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1Campaign SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1TouchType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor1TouchTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2Partner SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2MediaSource SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2Campaign SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2TouchType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor2TouchTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor3Partner SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor3MediaSource SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor3Campaign SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Contributor3TouchType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CountryCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN State SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN City SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN PostalCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN DMA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Operator SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Carrier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN WIFI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AppsFlyerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AdvertisingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IDFA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IDFV SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AndroidID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IMEI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN CustomerUserID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Platform SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN DeviceType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN OSVersion SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AppVersion SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN SDKVersion SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AppID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN AppName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN BundleID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Language SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN UserAgent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventValue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventRevenue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventRevenueCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventRevenueUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EventSource SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN IsReceiptValidated SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN HTTPReferrer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN OriginalURL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EtoroAppID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EtoroAppName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN EtoroReport SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 08:53:18 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 11
-- Statements: 162/162 succeeded
-- ====================
