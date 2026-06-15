"""Column-comment data for all four AppsFlyer objects in the one-shot deploy.

Pure data module — no I/O, no SQL string assembly. Imported by build_all.py.

Each object has a list of (col_name, comment) pairs in physical order.
Comments are written in plain ASCII single-quoted style; the renderer
escapes single quotes for SQL.
"""
from __future__ import annotations

# ---------------------------------------------------------------------------
# Bridge table: main.bi_db.bronze_marketperformance_tracking_customer
# ---------------------------------------------------------------------------
# 11 cols. CID-to-AppsFlyer-device bridge, 1 row per CID, 48M rows.
# Five fields the user explicitly asked us NOT to guess on; we describe
# only what is observable.
BRIDGE_TABLE_COMMENT = (
    "CID-to-mobile-device-identity bridge for AppsFlyer attribution. "
    "48M rows, 1 row per CID. Joins to the AppsFlyer fact "
    "(main.de_output.de_output_appsflyer_silver_reports OR "
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports) "
    "on AppsflyerID=AppsFlyerID (note vendor lowercase-f spelling on this "
    "side). Carries the device identifiers AppsflyerID / FirebaseID / IDFV "
    "alongside the CID and GCID, plus iOSAdTrackingPermissionID for ATT-state "
    "filtering. Use for any per-CID rollup of mobile-attributed events; on "
    "the AppsFlyer fact CustomerUserID is null on Installs / OrganicInstalls "
    "(no CID exists pre-registration) so the bridge join is the canonical "
    "path. Coverage: 20.9M of 48M CIDs (43%) carry a populated AppsflyerID "
    "(the share of CIDs who registered via the OneApp mobile path)."
)

BRIDGE_COLS: list[tuple[str, str]] = [
    ("CID", "Customer ID (internal platform identifier). Foreign key to Dim_Customer. Primary key of this bridge table - one row per CID. (Tier 1 - Customer.CustomerStatic)"),
    ("PartitionCol", "INT 0-9 (with one outlier row at -1) used as a partition / distribution key on the upstream marketperformance source. Even hash distribution: ~4.8M rows per bucket. Treat as physical-storage metadata - not a business dimension. (Tier 3 - observed behaviour; semantic NEEDS REVIEW)"),
    ("GCID", "Global Customer ID - cross-regulation unique identifier for a customer across all eToro entities. (Tier 1 - Customer.CustomerStatic)"),
    ("DeviceTypeID", "Device-type enum, INT. Three observed values: 1 (~27M, dominant), 2 (~10.1M), 3 (~10.9M). Likely Android / iOS / Web but the 1-dominant split does not match the AppsFlyer Platform split (~75% android / ~23% ios) so it is NOT a one-to-one platform code. (Tier 3 - observed values only; full enum NEEDS REVIEW)"),
    ("AppsflyerID", "AppsFlyer's unique device+install identifier (vendor-issued, privacy-safe). Joins to AppsFlyerID on the AppsFlyer fact tables. NOTE the vendor lowercase-f spelling on this column versus the AppsFlyer-fact AppsFlyerID. Populated on 20.9M of 48M rows (43%) - the share of CIDs that registered via the mobile app. (Tier 1 - AppsFlyer field appsflyer_id)"),
    ("UserUniqueIdentifierCookie", "STRING populated on 8.9M of 48M rows (18%). Per the column name, this is a per-user unique cookie identifier - presumably the web-tracking cookie ID stored alongside the CID for cross-device identity resolution. Treat as PII / pseudonymous identifier. (Tier 3 - inferred from name; usage and provenance NEED REVIEW)"),
    ("FirebaseID", "Firebase Cloud Messaging install ID issued by Google Firebase to the OneApp mobile app installation. Populated on 9.3M of 48M rows (19%). Used by eToro for push-notification targeting and as an additional mobile install identifier alongside AppsflyerID. (Tier 2 - Firebase platform standard; eToro usage)"),
    ("iOSAdTrackingPermissionID", "iOS App Tracking Transparency (ATT) permission state, INT. Two observed values: 0 (46.7M, 97%) and 1 (1.3M, 3%). The 97/3 split matches the empirical iOS14.5 ATT-opt-out reality. Treat as a 2-state ATT-Authorized vs Not-Authorized flag rather than a 4-state Apple ATTrackingManager enum. (Tier 3 - observed values only; full enum NEEDS REVIEW)"),
    ("UpdatedAt", "Timestamp of the last update to this bridge row. (Tier 3 - ETL metadata)"),
    ("AdditionalData", "STRING populated on 1.0M of 48M rows (2%). Sparse free-form / structured payload added by the upstream marketperformance pipeline. Content schema NEEDS REVIEW before relying on it; treat as opaque until documented. (Tier 3 - sparse field; content NEEDS REVIEW)"),
    ("IDFV", "Apple Identifier for Vendor. Unique per app vendor on a device, iOS-only. Populated on 1.4M of 48M rows (3%) - iOS users who registered via OneApp iOS. (Tier 1 - AppsFlyer field idfv)"),
]


# ---------------------------------------------------------------------------
# Bridgeclaw view: main.bridgeclaw_permitted_data.appflyer_reports
# ---------------------------------------------------------------------------
# 33-col VIEW, currently filtered `dateid > 20260531` over silver.
# View comments use COMMENT ON COLUMN syntax (not ALTER TABLE).
VIEW_COMMENT = (
    "Permissioned PII-safe view over the AppsFlyer mobile-attribution fact. "
    "33-column subset of main.de_output.de_output_appsflyer_silver_reports, "
    "filtered to dateid > 20260531. Drops the location detail columns (State "
    "/ City / PostalCode / DMA / IP), the device-network columns "
    "(WIFI / Operator / Carrier / Language), all 5 SubParam columns, the "
    "AppType-version triplet (DeviceType already excluded), most device IDs "
    "(AdvertisingID / IDFA / IDFV / AndroidID / IMEI), HTTP attribution "
    "metadata (HTTPReferrer / OriginalURL / UserAgent / IsReceiptValidated / "
    "AttributionLookback / ReengagementWindow / IsPrimaryAttribution), and "
    "the multi-touch contributor chain. Keeps the attribution + campaign + "
    "event-revenue + retargeting columns plus the eToro pipeline fields. "
    "Use when restricted access requires keeping device-level PII out of the "
    "consumer's reach. The dateid > 20260531 filter is a forward-cutover "
    "guard - this is a one-off view definition, not a deprecation signal "
    "for the gold path."
)

# Each entry: (column, source_field_in_silver_or_synthetic, source_layer, comment_lead)
# We keep the comments tighter than the silver fact since the view is read-only.
VIEW_COLS: list[tuple[str, str]] = [
    ("DateID", "Event date as YYYYMMDD integer. View filter: dateid > 20260531. (Tier 2 - eToro pipeline)"),
    ("EtoroReport", "AppsFlyer report-type partition: OrganicInstalls / Installs / InAppEvents. Always filter this column. See main.de_output.de_output_appsflyer_silver_reports for value semantics. (Tier 2 - eToro pipeline)"),
    ("EventSource", "How the event was reported: SDK or S2S. ~1M rows in the underlying fact carry malformed values - filter EventSource IN ('SDK','S2S'). (Tier 1 - AppsFlyer field event_source)"),
    ("AppsFlyerID", "AppsFlyer privacy-safe per-install device identifier. Joins to bronze_marketperformance_tracking_customer.AppsflyerID for CID resolution. (Tier 1 - AppsFlyer field appsflyer_id)"),
    ("CustomerUserID", "Hashed CID set by eToro at registration / login. Empty on Installs / OrganicInstalls. (Tier 1 - AppsFlyer field customer_user_id)"),
    ("EventTime", "Timestamp of the event occurrence. STRING. (Tier 1 - AppsFlyer field event_time)"),
    ("InstallTime", "Timestamp when the app install was first recorded. (Tier 1 - AppsFlyer field install_time)"),
    ("Partner", "Agency or partner identifier. (Tier 1 - AppsFlyer field af_prt)"),
    ("MediaSource", "The media source attributed to an event - ad network / channel. eToro values include googleadwords_int, Apple Search Ads, tiktokglobal_int, eToroWeb, restricted (iOS14 ATT bucket). (Tier 1 - AppsFlyer field media_source)"),
    ("Channel", "Sub-classifier within MediaSource. (Tier 1 - AppsFlyer field af_channel)"),
    ("Campaign", "Campaign name the user was exposed to. (Tier 1 - AppsFlyer field campaign)"),
    ("CampaignID", "Unique campaign identifier from the ad network. (Tier 1 - AppsFlyer field campaign_id)"),
    ("Adset", "Adset name within the campaign. (Tier 1 - AppsFlyer field af_adset)"),
    ("AdsetID", "Adset ID. (Tier 1 - AppsFlyer field af_adset_id)"),
    ("Ad", "Ad name - the exact creative shown to the user. (Tier 1 - AppsFlyer field af_ad)"),
    ("AdID", "Ad ID. (Tier 1 - AppsFlyer field af_ad_id)"),
    ("AdType", "Ad format type: banner, footer, interstitial, video, ClickToDownload. (Tier 1 - AppsFlyer field af_ad_type)"),
    ("Region", "AppsFlyer macro-region code (EU / AS / NA / SA / AF / AU). NOT eToro's marketing-region SCD. (Tier 1 - AppsFlyer field region)"),
    ("CountryCode", "ISO 3166 alpha-2 country code. AppsFlyer convention: UK is used, NOT GB. (Tier 1 - AppsFlyer field country_code)"),
    ("Platform", "Mobile OS: android / ios. Filter Platform IN ('android','ios','None') to drop GUID-shaped dirty values. (Tier 1 - AppsFlyer field platform)"),
    ("DeviceType", "Device form factor. AppsFlyer documents this as DEPRECATED Feb 2022 - replaced by device_model. (Tier 1 - AppsFlyer field device_type, deprecated)"),
    ("OSVersion", "Operating system version string. (Tier 1 - AppsFlyer field os_version)"),
    ("AppVersion", "eToro app version string. (Tier 1 - AppsFlyer field app_version)"),
    ("EventName", "Attribution event type or in-app event name. Top eToro values: install, Open Trade, Registration_S2S, FTD_S2S, Verification Level - 1/2/3, Redeposit_S2S. _S2S suffix = server-to-server postback (more reliable than SDK twin). (Tier 1 - AppsFlyer field event_name)"),
    ("EventValue", "JSON payload for in-app event parameters. Empty for install events. (Tier 1 - AppsFlyer field event_value)"),
    ("EventRevenue", "Revenue value in EventRevenueCurrency. STRING - cast before arithmetic. (Tier 1 - AppsFlyer field event_revenue)"),
    ("EventRevenueUSD", "Revenue converted to USD by AppsFlyer. (Tier 1 - AppsFlyer field event_revenue_usd)"),
    ("Date", "Event date - the date the install or in-app event occurred. NOT InstallTime for InAppEvents. (Tier 2 - eToro pipeline)"),
    ("CostModel", "Cost model: CPC / CPI / CPM / Other. (Tier 1 - AppsFlyer field af_cost_model)"),
    ("CostValue", "Cost amount in CostCurrency, up to 4 decimal digits. STRING. (Tier 1 - AppsFlyer field af_cost_value)"),
    ("CostCurrency", "ISO-4217 currency code, defaults to USD. (Tier 1 - AppsFlyer field af_cost_currency)"),
    ("IsRetargeting", "true / false flag. As of 2026-06 zero rows carry true - eToro is not running retargeting through the MMP integration. (Tier 1 - AppsFlyer field is_retargeting)"),
    ("RetargetingConversionType", "Re-engagement / Re-attribution. NULL across the eToro corpus while retargeting is dormant. (Tier 1 - AppsFlyer field retargeting_conversion_type)"),
]
