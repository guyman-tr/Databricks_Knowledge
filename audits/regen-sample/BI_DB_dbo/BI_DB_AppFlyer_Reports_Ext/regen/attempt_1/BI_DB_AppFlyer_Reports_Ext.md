# BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext

> 130.3M-row raw data landing table for AppsFlyer mobile attribution events, spanning 2020 to present. Receives externally loaded data from the AppsFlyer Raw Data Export API covering installs, in-app events, and organic activity for eToro mobile applications (OneApp Android, OneApp iOS). All columns stored as varchar — no type enforcement at the landing stage. Consumed by SP_AppFlyer_Reports which applies minor type casts and normalizations before inserting into BI_DB_AppFlyer_Reports.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | AppsFlyer Raw Data Export API (external data feed) |
| **Refresh** | Daily by DateID partition — externally loaded |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (no clustered index) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | None |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_AppFlyer_Reports_Ext is the raw data landing table for AppsFlyer mobile attribution reports. AppsFlyer is a third-party mobile attribution and marketing analytics platform used by eToro to track mobile app installs, in-app events (e.g., Open Trade, registration), and multi-touch attribution across advertising partners.

The table contains 130.3M rows spanning from 2020 to present (2025). Data is loaded externally from the AppsFlyer Raw Data Export API and lands in this table with all columns as `varchar(4000)` or `varchar(500)` — no type enforcement is applied at the landing stage. This is by design: AppsFlyer exports raw string data, and type conversion happens downstream.

SP_AppFlyer_Reports (author: Katy F, 2016-05-25) reads from this _Ext table daily, applies minor transforms (CAST to DATETIME, 'None'→NULL normalization, UK→GB country code correction, boolean text conversions), and inserts the cleansed data into BI_DB_AppFlyer_Reports partitioned by DateID.

The table covers two eToro mobile applications: `com.etoro.openbook` (OneApp Android) and `id674984916` (OneApp iOS). Report types include InAppEvents and OrganicInstalls.

Two columns have dynamic data masking applied: City and IsReceiptValidated, indicating PII sensitivity controls.

---

## 2. Business Logic

### 2.1 Multi-Touch Attribution Model

**What**: AppsFlyer tracks up to 3 contributing touchpoints before the attributed conversion event, enabling multi-touch attribution analysis.
**Columns Involved**: Contributor1Partner, Contributor1MediaSource, Contributor1Campaign, Contributor1TouchType, Contributor1TouchTime (repeated for Contributor2 and Contributor3)
**Rules**:
- Each contributor set captures the partner, media source, campaign, touch type, and touch time
- Contributor1 is the most recent assist before the attributed touch
- Empty contributor fields indicate fewer than 3 touchpoints in the user journey
- TouchTime values may contain 'None', 'USD', or 'usd' as dirty data (cleaned by SP_AppFlyer_Reports)

### 2.2 Attribution Touch Classification

**What**: Each event is classified by how the user was first attributed — click-through or view-through (impression).
**Columns Involved**: AttributedTouchType, AttributedTouchTime, AttributionLookback
**Rules**:
- AttributedTouchType: 'click' (user clicked an ad), 'impression' (view-through attribution), NULL/empty (organic)
- AttributionLookback: window duration string (e.g., '7d', '30d', '1d') defining the attribution window
- Organic installs have no AttributedTouchType or AttributedTouchTime

### 2.3 Event Data (In-App Events)

**What**: Tracks specific user actions within the eToro app after install.
**Columns Involved**: EventTime, EventName, EventValue, EventRevenue, EventRevenueCurrency, EventRevenueUSD, EventSource
**Rules**:
- EventName captures the action (e.g., 'Open Trade', 'install')
- EventValue is a JSON string containing structured event parameters (af_content, af_content_type, af_content_id, is_copy, af_revenue)
- EventRevenue and EventRevenueUSD track monetary value of the event
- EventSource: 'SDK' (client-side) or 'S2S' (server-to-server postback)

### 2.4 Geographic Segmentation

**What**: User geographic location at the time of the event, used for regional marketing analysis.
**Columns Involved**: Region, CountryCode, State, City, PostalCode, DMA, IP
**Rules**:
- Region uses 2-letter continent codes: EU (71%), AS (8%), AU (3%), SA (2%), AF (2%), NA (<1%)
- CountryCode uses ISO 2-letter codes; raw data contains 'UK' which SP_AppFlyer_Reports normalizes to 'GB'
- 'None' appears as a string value for missing geographic data (not SQL NULL)
- City is masked via dynamic data masking (PII protection)
- IP is stored as varchar(500)

### 2.5 Device and App Identification

**What**: Captures device fingerprint and app version data for analytics segmentation.
**Columns Involved**: Platform, DeviceType, OSVersion, AppVersion, SDKVersion, AppID, AppName, BundleID
**Rules**:
- Platform: 'android' or 'ios'
- AppID/BundleID: 'com.etoro.openbook' (Android) or 'id674984916' (iOS)
- SDKVersion: AppsFlyer SDK version (e.g., 'v6.3.2', 'v6.12.2')

### 2.6 eToro-Specific Enrichment Columns

**What**: Columns added by the eToro data pipeline to classify the report and application.
**Columns Involved**: DateID, Date, EtoroAppID, EtoroAppName, EtoroReport
**Rules**:
- DateID: integer YYYYMMDD format, used as the partition key for daily load/delete
- EtoroAppID: normalized app identifier (e.g., 'com_etoro_openbook', 'id674984916')
- EtoroAppName: human-readable app name ('OneApp Android', 'OneApp iOS')
- EtoroReport: report type classification ('InAppEvents', 'OrganicInstalls')

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution — no hash key, data spread evenly across distributions
- **HEAP** — no clustered index. Full table scans on all queries
- Always filter by `DateID` to limit scan scope. Without a DateID filter, queries scan all 130M+ rows

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many installs came from a specific campaign? | `WHERE EventName = 'install' AND Campaign = '...' AND DateID BETWEEN ... AND ...` |
| What are the top media sources by country? | `WHERE DateID >= 20250101 GROUP BY CountryCode, MediaSource` |
| What in-app events generate the most revenue? | `WHERE EventRevenue IS NOT NULL AND EventRevenue != '' AND DateID >= ...` |
| Multi-touch attribution analysis | Join Contributor1-3 fields, filter by `AttributedTouchType = 'click'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_AppFlyer_Reports | DateID, AppsFlyerID, EventTime | Compare raw vs. cleansed data |

### 3.4 Gotchas

- **All columns are varchar**: EventRevenue, CostValue, DateID (in _Ext) are strings. CAST before arithmetic operations
- **'None' is not NULL**: AppsFlyer exports the string 'None' for missing values. Filter with `WHERE col != 'None' AND col IS NOT NULL AND col != ''`
- **CountryCode 'UK' vs 'GB'**: Raw data uses 'UK' for United Kingdom. SP_AppFlyer_Reports normalizes to 'GB' in the downstream table. Query _Ext with `CountryCode IN ('UK', 'GB')` for UK data
- **EventValue is JSON**: Stored as a varchar string. Use `OPENJSON` or string parsing to extract nested fields
- **Data masking on City and IsReceiptValidated**: Non-privileged users see masked values ('xxxx' for City)
- **Dirty timestamp data**: Contributor touch time fields may contain 'USD' or 'usd' instead of timestamps (data quality issue from source)
- **DateID is int in DDL but loaded as string context**: Although DDL defines DateID as `int`, the data comes from an all-varchar source. Ensure consistent type handling

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream wiki (no upstream wiki available for this object) |
| Tier 2 | Derived from SP/ETL code with transform logic |
| Tier 3 | Grounded in DDL, sample data, and AppsFlyer API field semantics — no upstream wiki in repository |
| Tier 4 | Inferred from name only (not used) |

| # | Element | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | AttributedTouchType | varchar(4000) | YES | Type of the attributed user touchpoint that led to the conversion. Values observed: 'click' (53%), 'impression' (14%), NULL/empty (33% — organic). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 2 | AttributedTouchTime | varchar(4000) | YES | Timestamp of the attributed touch event as a raw string. Format: 'YYYY-MM-DD HH:MM:SS'. Contains 'None' for organic events. SP_AppFlyer_Reports CASTs to DATETIME downstream. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 3 | InstallTime | varchar(4000) | YES | Timestamp of the app install event as a raw string. Format: 'YYYY-MM-DD HH:MM:SS'. SP_AppFlyer_Reports CASTs to DATETIME downstream. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 4 | EventTime | varchar(4000) | YES | Timestamp of the in-app event or install as a raw string. Format: 'YYYY-MM-DD HH:MM:SS'. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 5 | EventName | varchar(4000) | YES | Name of the tracked event. Values include 'install', 'Open Trade', and other custom eToro in-app events. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 6 | EventValue | varchar(4000) | YES | JSON-encoded string containing structured event parameters. For 'Open Trade' events, includes af_content (instrument name), af_content_type (asset class), af_content_id (instrument ID), is_copy (copy trade flag), af_revenue (trade amount). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 7 | EventRevenue | varchar(4000) | YES | Revenue amount associated with the event as a raw string. Represents monetary value in the currency specified by EventRevenueCurrency. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 8 | EventRevenueCurrency | varchar(4000) | YES | ISO currency code for EventRevenue. Predominantly 'USD' in observed data. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 9 | EventRevenueUSD | varchar(4000) | YES | Revenue amount converted to USD as a raw string. AppsFlyer-calculated USD equivalent of EventRevenue. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 10 | EventSource | varchar(4000) | YES | Origin of the event data. 'SDK' = client-side AppsFlyer SDK, 'S2S' = server-to-server postback from eToro backend. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 11 | IsReceiptValidated | varchar(4000) | YES | Receipt validation status for purchase events. Dynamic data masking applied (FUNCTION = 'default()'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 12 | Partner | varchar(4000) | YES | AppsFlyer integrated partner name associated with the attribution. Identifies the ad network partner (e.g., 'zoomdil'). Empty for organic and direct traffic. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 13 | MediaSource | varchar(4000) | YES | The media source (ad network) that drove the install or event. Values include 'Website', 'googleadwords_int', 'bytedanceglobal_int', 'smadex_int', 'Linkedin', 'nasimobi_int'. Empty for organic. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 14 | Channel | varchar(4000) | YES | Marketing channel within the media source. Values include 'TikTok', 'ACI_Search'. Empty when not applicable. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 15 | Keywords | varchar(4000) | YES | Search keywords associated with the ad click, relevant for search ad campaigns. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 16 | Campaign | varchar(4000) | YES | Marketing campaign name as configured in the ad network. Contains eToro affiliate IDs (e.g., 'AFFID_77015_Smadex_FR_IOS_zoomdtrackingdata'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 17 | CampaignID | varchar(4000) | YES | Unique campaign identifier from the ad network (numeric or alphanumeric string). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 18 | Adset | varchar(4000) | YES | Ad set or ad group name within the campaign. Represents a targeting group. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 19 | AdsetID | varchar(4000) | YES | Unique ad set identifier from the ad network. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 20 | Ad | varchar(4000) | YES | Individual ad creative name within the ad set. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 21 | AdID | varchar(4000) | YES | Unique ad creative identifier from the ad network. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 22 | AdType | varchar(4000) | YES | Type of ad creative. Values include 'Banner', 'ClickToDownload', numeric codes (e.g., '15'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 23 | SiteID | varchar(4000) | YES | Publisher site ID where the ad was displayed. Identifies the specific publisher within the ad network (e.g., 'GoogleSearch', '_miroir-mag.fr'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 24 | SubSiteID | varchar(4000) | YES | Sub-publisher site identifier for granular publisher-level tracking. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 25 | SubParam1 | varchar(4000) | YES | Custom sub-parameter 1 passed via the attribution link for additional tracking dimensions. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 26 | SubParam2 | varchar(4000) | YES | Custom sub-parameter 2 passed via the attribution link for additional tracking dimensions. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 27 | SubParam3 | varchar(4000) | YES | Custom sub-parameter 3 passed via the attribution link for additional tracking dimensions. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 28 | SubParam4 | varchar(4000) | YES | Custom sub-parameter 4 passed via the attribution link for additional tracking dimensions. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 29 | SubParam5 | varchar(4000) | YES | Custom sub-parameter 5 passed via the attribution link for additional tracking dimensions. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 30 | CostModel | varchar(4000) | YES | Cost model used for the ad campaign. Common values: CPI (cost per install), CPC (cost per click), CPM (cost per mille). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 31 | CostValue | varchar(4000) | YES | Cost amount as a raw string in the currency specified by CostCurrency. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 32 | CostCurrency | varchar(4000) | YES | ISO currency code for CostValue. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 33 | Contributor1Partner | varchar(4000) | YES | Partner name for the 1st contributing touchpoint in the multi-touch attribution path. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 34 | Contributor1MediaSource | varchar(4000) | YES | Media source for the 1st contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 35 | Contributor1Campaign | varchar(4000) | YES | Campaign name for the 1st contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 36 | Contributor1TouchType | varchar(4000) | YES | Touch type ('click' or 'impression') for the 1st contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 37 | Contributor1TouchTime | varchar(4000) | YES | Timestamp of the 1st contributing touchpoint as a raw string. May contain dirty values ('None', 'USD', 'usd'). SP_AppFlyer_Reports normalizes these to NULL downstream. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 38 | Contributor2Partner | varchar(4000) | YES | Partner name for the 2nd contributing touchpoint in the multi-touch attribution path. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 39 | Contributor2MediaSource | varchar(4000) | YES | Media source for the 2nd contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 40 | Contributor2Campaign | varchar(4000) | YES | Campaign name for the 2nd contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 41 | Contributor2TouchType | varchar(4000) | YES | Touch type ('click' or 'impression') for the 2nd contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 42 | Contributor2TouchTime | varchar(4000) | YES | Timestamp of the 2nd contributing touchpoint as a raw string. 'None' values normalized to NULL by SP_AppFlyer_Reports. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 43 | Contributor3Partner | varchar(4000) | YES | Partner name for the 3rd contributing touchpoint in the multi-touch attribution path. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 44 | Contributor3MediaSource | varchar(4000) | YES | Media source for the 3rd contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 45 | Contributor3Campaign | varchar(4000) | YES | Campaign name for the 3rd contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 46 | Contributor3TouchType | varchar(4000) | YES | Touch type ('click' or 'impression') for the 3rd contributing touchpoint. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 47 | Contributor3TouchTime | varchar(4000) | YES | Timestamp of the 3rd contributing touchpoint as a raw string. 'None' values normalized to NULL by SP_AppFlyer_Reports. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 48 | Region | varchar(4000) | YES | Geographic region (continent) code. Values: EU (71%), AS (8%), AU (3%), SA (2%), AF (2%), NA (<1%), 'None' (12%), empty (3%). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 49 | CountryCode | varchar(4000) | YES | ISO 2-letter country code. Raw data uses 'UK' for United Kingdom; SP_AppFlyer_Reports normalizes to 'GB' downstream. Top countries: DE, UK, FR, IT, AE. 'None' for missing. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 50 | State | varchar(4000) | YES | State or province code within the country. Uses short codes (e.g., 'BE', 'BY', 'NI' for German states). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 51 | City | varchar(4000) | YES | City name of the user. Dynamic data masking applied (FUNCTION = 'default()') — non-privileged users see 'xxxx'. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 52 | PostalCode | varchar(4000) | YES | Postal/ZIP code of the user's location. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 53 | DMA | varchar(4000) | YES | Designated Market Area code. Numeric code identifying the geographic media market. 'None' for non-US locations or unknown. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 54 | IP | varchar(500) | YES | IP address of the user at the time of the event. Stored as varchar(500). Contains IPv4 addresses. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 55 | WIFI | varchar(4000) | YES | Whether the user was connected via WiFi at the time of the event. Raw values: '1'/'0' or 'true'/'false'. SP_AppFlyer_Reports normalizes to 'true'/'false'. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 56 | Operator | varchar(4000) | YES | Mobile network operator name (e.g., 'Vodafone'). Empty when connected via WiFi or unavailable. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 57 | Carrier | varchar(4000) | YES | Mobile carrier name. Similar to Operator but may differ when roaming. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 58 | Language | varchar(4000) | YES | Device language setting (e.g., 'Deutsch', 'English'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 59 | AppsFlyerID | varchar(4000) | YES | Unique device identifier assigned by the AppsFlyer SDK. Format: Unix timestamp in milliseconds followed by a random number (e.g., '1667318185121-6953359142415262167'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 60 | AdvertisingID | varchar(4000) | YES | Google Advertising ID (GAID) for Android devices. UUID format. Empty for iOS. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 61 | IDFA | varchar(4000) | YES | Apple Identifier for Advertisers. Empty for Android devices and post-ATT (App Tracking Transparency) iOS installs. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 62 | AndroidID | varchar(4000) | YES | Android device hardware ID. Empty for iOS devices. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 63 | CustomerUserID | varchar(4000) | YES | eToro customer identifier (hashed or raw) mapped by the eToro app to the AppsFlyer SDK. Links attribution data back to eToro user accounts. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 64 | IMEI | varchar(4000) | YES | International Mobile Equipment Identity number. Rarely populated due to privacy restrictions. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 65 | IDFV | varchar(4000) | YES | Apple Identifier for Vendors. Unique per app-vendor combination on iOS devices. Empty for Android. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 66 | Platform | varchar(4000) | YES | Mobile platform. Values: 'android', 'ios'. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 67 | DeviceType | varchar(4000) | YES | Device model or form factor. Generally empty in observed data. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 68 | OSVersion | varchar(4000) | YES | Operating system version number (e.g., '13', '12', '16.4.1'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 69 | AppVersion | varchar(4000) | YES | eToro app version string (e.g., '441.0.0', '547.0.0', '651.635.1'). Empty for some events. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 70 | SDKVersion | varchar(4000) | YES | AppsFlyer SDK version integrated in the app (e.g., 'v6.3.2', 'v6.12.2'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 71 | AppID | varchar(4000) | YES | Application store identifier. 'com.etoro.openbook' (Android Google Play) or 'id674984916' (iOS App Store). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 72 | AppName | varchar(4000) | YES | Application display name from the app store (e.g., 'eToro: Investing made social', 'eToro: Trade. Invest. Connect.'). Empty for some records. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 73 | BundleID | varchar(4000) | YES | Application bundle identifier. Same as AppID in observed data ('com.etoro.openbook' or 'id674984916'). (Tier 3 — AppsFlyer API, no upstream wiki) |
| 74 | AttributionLookback | varchar(4000) | YES | Attribution lookback window configured for the campaign. Duration string (e.g., '7d', '30d', '1d'). Defines how far back a touch can be attributed to an install. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 75 | ReengagementWindow | varchar(4000) | YES | Re-engagement attribution window for retargeting campaigns. Duration string defining how long after re-engagement an event is attributed. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 76 | IsPrimaryAttribution | varchar(4000) | YES | Whether this is the primary attribution record for the event. Raw values: '1'/'0'. SP_AppFlyer_Reports normalizes to 'true'/'false'. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 77 | UserAgent | varchar(4000) | YES | HTTP User-Agent string from the user's browser or app at the time of the attributed touch. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 78 | HTTPReferrer | varchar(4000) | YES | HTTP referrer URL from the attributed touch. SP_AppFlyer_Reports truncates to LEFT(4000) downstream. Contains ad network redirect URLs. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 79 | OriginalURL | varchar(4000) | YES | The original AppsFlyer OneLink or attribution URL that triggered the install/event. Contains full tracking parameters. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 80 | IsRetargeting | varchar(4000) | YES | Whether the event is attributed to a retargeting campaign. Raw values: '1'/'0' or NULL. SP_AppFlyer_Reports normalizes to 'true'/'false'. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 81 | RetargetingConversionType | varchar(4000) | YES | Type of retargeting conversion (e.g., 're-engagement', 're-attribution'). Empty for non-retargeting events. (Tier 3 — AppsFlyer API, no upstream wiki) |
| 82 | DateID | int | YES | Integer date key in YYYYMMDD format (e.g., 20250502). Used as the partition key for daily load and delete operations in SP_AppFlyer_Reports. (Tier 3 — ETL process, no upstream wiki) |
| 83 | Date | datetime | YES | Calendar date corresponding to DateID. Midnight timestamp (e.g., '2025-05-02 00:00:00'). (Tier 3 — ETL process, no upstream wiki) |
| 84 | EtoroAppID | varchar(500) | YES | eToro-internal normalized application identifier derived from the app store ID. Values: 'com_etoro_openbook' (Android), 'id674984916' (iOS). Uses underscores instead of dots. (Tier 3 — ETL process, no upstream wiki) |
| 85 | EtoroAppName | varchar(500) | YES | eToro-internal application display name. Values: 'OneApp Android', 'OneApp iOS'. (Tier 3 — ETL process, no upstream wiki) |
| 86 | EtoroReport | varchar(500) | YES | Report type classification assigned during data load. Values observed: 'InAppEvents' (in-app event reports), 'OrganicInstalls' (organic install reports). (Tier 3 — ETL process, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All 81 AppsFlyer columns | AppsFlyer Raw Data Export API | Corresponding API fields | Passthrough (raw varchar landing) |
| DateID | ETL load process | — | YYYYMMDD integer date key |
| Date | ETL load process | — | Calendar date |
| EtoroAppID | ETL load process | AppID | Normalized identifier (dots → underscores) |
| EtoroAppName | ETL load process | — | eToro app classification |
| EtoroReport | ETL load process | — | Report type classification |

### 5.2 ETL Pipeline

```
AppsFlyer Raw Data Export API
  |-- External data feed (daily export) --|
  v
BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext (130.3M rows, raw varchar landing)
  |-- SP_AppFlyer_Reports @dt (daily by DateID) --|
  |   Transforms: CAST datetime, 'None'→NULL,     |
  |   UK→GB, boolean normalization                 |
  v
BI_DB_dbo.BI_DB_AppFlyer_Reports (cleansed data)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| — | — | No FK references. Raw landing table with no enforced relationships. |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| All columns | BI_DB_dbo.SP_AppFlyer_Reports | SP reads from _Ext and inserts cleansed data into BI_DB_AppFlyer_Reports |

---

## 7. Sample Queries

### 7.1 Daily Install Count by Media Source

```sql
SELECT
    DateID,
    MediaSource,
    COUNT(*) AS install_count
FROM [BI_DB_dbo].[BI_DB_AppFlyer_Reports_Ext]
WHERE EventName = 'install'
  AND DateID >= 20250401
  AND MediaSource != ''
GROUP BY DateID, MediaSource
ORDER BY DateID DESC, install_count DESC;
```

### 7.2 Open Trade Events with Revenue by Country

```sql
SELECT
    CountryCode,
    COUNT(*) AS trade_events,
    SUM(CAST(EventRevenueUSD AS FLOAT)) AS total_revenue_usd
FROM [BI_DB_dbo].[BI_DB_AppFlyer_Reports_Ext]
WHERE EventName = 'Open Trade'
  AND EventRevenueUSD IS NOT NULL
  AND EventRevenueUSD != ''
  AND DateID >= 20250101
GROUP BY CountryCode
ORDER BY total_revenue_usd DESC;
```

### 7.3 Multi-Touch Attribution Path Analysis

```sql
SELECT
    AttributedTouchType,
    Contributor1TouchType,
    Contributor2TouchType,
    Contributor3TouchType,
    COUNT(*) AS conversion_count
FROM [BI_DB_dbo].[BI_DB_AppFlyer_Reports_Ext]
WHERE EventName = 'install'
  AND AttributedTouchType IS NOT NULL
  AND AttributedTouchType != ''
  AND DateID >= 20250101
GROUP BY AttributedTouchType, Contributor1TouchType, Contributor2TouchType, Contributor3TouchType
ORDER BY conversion_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 86 T3, 0 T4, 0 T5 | Elements: 86/86, Logic: 6/10, Lineage: 7/10*
*Object: BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext | Type: Table | Production Source: AppsFlyer Raw Data Export API (external)*
