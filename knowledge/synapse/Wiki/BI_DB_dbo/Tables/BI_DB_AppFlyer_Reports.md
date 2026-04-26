---
table: BI_DB_dbo.BI_DB_AppFlyer_Reports
schema: BI_DB_dbo
documented: 2026-04-22
batch: 51
quality_score: 8.5
tier: Tier 3
row_count_approx: 128600000
date_range: 2022-10-25 to 2026-04-12
etl_frequency: Daily
etl_sp: BI_DB_dbo.SP_AppFlyer_Reports
opsdb_priority: 0
---

# BI_DB_AppFlyer_Reports

## 1. Purpose

User-level and event-level mobile attribution log from the **AppFlyer platform**. This is the raw, per-install and per-in-app-event export — the most granular AppFlyer dataset in BI_DB_dbo. Each row represents a single attributed mobile event: either an app install or an in-app event (trade, registration, deposit, KYC, etc.) attributed to a specific acquisition source.

Three AppFlyer report types are merged into this table, distinguished by `EtoroReport`:
- **`OrganicInstalls`** — installs not attributed to any paid campaign
- **`Installs`** — installs attributed to paid media (click or impression)
- **`InAppEvents`** — post-install in-app events carrying business outcomes (trades, registrations, FTDs, redeposits)

Used by the marketing analytics team for channel attribution, conversion funnel analysis, and LTV modeling. Feeds directly into `BI_DB_MarketingDailyRawData` / `BI_DB_MarketingMonthlyRawData` via `SP_Marketing_Cube`.

## 2. Source & Lineage

| Layer | Object |
|-------|--------|
| Origin | AppFlyer Platform (third-party mobile attribution SaaS) |
| Staging | `BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext` (all-varchar, HEAP staging) |
| Writer SP | `BI_DB_dbo.SP_AppFlyer_Reports` (Katy F, 2016-05-25) |
| ETL pattern | Daily DELETE+INSERT (single-day replace by `DateID`) |
| OpsDB | Priority 0, SB_Daily, ProcessType SQL |

AppFlyer merges three report types into one staging export → SP type-casts key fields, standardizes CountryCode, and rejects malformed timestamp strings → typed target. `UpdateDate` column is in the DDL but **not in the INSERT list** — always NULL.

See [BI_DB_AppFlyer_Reports.lineage.md](BI_DB_AppFlyer_Reports.lineage.md) for full pipeline detail.

## 3. Grain

One row per **attributed mobile event** (install or in-app event).

- `EtoroReport` partitions the event type: `OrganicInstalls` / `Installs` / `InAppEvents`
- `AppsFlyerID` is the unique AppFlyer device+install identifier — the closest thing to a row key
- `CustomerUserID` (when populated) links an in-app event to an eToro customer (hashed)
- `DateID` / `Date` = **event date** (the date the event fired). For `InAppEvents`, this differs from `InstallTime`.

## 4. Distribution & Clustering

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN |
| Clustering | CLUSTERED INDEX on `Date ASC, EtoroReport ASC` |
| Date range (live) | 2022-10-25 → 2026-04-12 |
| Row count | ~128.6M (86.3M OrganicInstalls + 35.6M InAppEvents + 6.8M Installs) |

## 5. Column Reference

### Attribution & Touch Columns

| Column | Type | Description |
|--------|------|-------------|
| `AttributedTouchType` | varchar(4000) | Attribution model: `click` (user clicked an ad), `impression` (view-through attribution), or empty/NULL (organic — no paid touch). 88.4M empty rows (organic), 31.8M click, 8.0M impression. |
| `AttributedTouchTime` | datetime | Timestamp of the attributed ad click or impression. NULL for organic installs (SP converts AppFlyer 'None' string → SQL NULL). |
| `InstallTime` | datetime | Timestamp when the app was installed. Present on all rows (install events and in-app events alike). For InAppEvents, this is the original install date — may be far in the past. |
| `AttributionLookback` | varchar(4000) | AppFlyer attribution lookback window setting active at the time of attribution (e.g., `'1d'`, `'7d'`). |
| `ReengagementWindow` | varchar(4000) | AppFlyer re-engagement window for retargeting campaigns. |
| `IsPrimaryAttribution` | varchar(4000) | `'true'` / `'false'` string. Indicates whether this is the primary attributed source (vs a re-engagement event). SP normalizes all non-'1' values to 'false'. |
| `IsRetargeting` | varchar(4000) | `'true'` / `'false'` string. Whether this event is from a retargeting (re-engagement) campaign rather than new user acquisition. |
| `RetargetingConversionType` | varchar(4000) | For retargeting events: the conversion type (e.g., `re-engagement`, `re-attribution`). NULL for non-retargeting rows. |

### Campaign & Media Source Columns

| Column | Type | Description |
|--------|------|-------------|
| `Partner` | varchar(4000) | AppFlyer partner agency or integrated partner name. |
| `MediaSource` | varchar(4000) | Attribution source — ad network or channel. Examples: `googleadwords_int` (Google UAC), `bytedanceglobal_int` (TikTok), `Facebook Ads`, `eToroWeb` (web-to-app redirect), `Organic`, `restricted`. |
| `Channel` | varchar(4000) | Sub-channel within the media source (e.g., `ACI_Search`, `GoogleSearch`). |
| `Keywords` | varchar(4000) | Search keywords associated with the paid campaign (for search campaigns). |
| `Campaign` | varchar(4000) | Campaign name as reported by AppFlyer. Format varies by network. |
| `CampaignID` | varchar(4000) | Numeric campaign identifier from the ad network. |
| `Adset` | varchar(4000) | Ad set name within the campaign. |
| `AdsetID` | varchar(4000) | Ad set numeric identifier. |
| `Ad` | varchar(4000) | Individual ad creative name or description. |
| `AdID` | varchar(4000) | Ad creative numeric identifier. |
| `AdType` | varchar(4000) | Ad format type (e.g., `ClickToDownload`). |
| `SiteID` | varchar(4000) | Publisher site identifier (for DSP/network buys). |
| `SubSiteID` | varchar(4000) | Sub-publisher identifier. |
| `SubParam1` – `SubParam5` | varchar(4000) | Custom tracking parameters passed through AppFlyer deep link (`af_sub1`–`af_sub5`). Used for publisher IDs, placement names, and custom tracking values. |
| `CostModel` | varchar(4000) | Pricing model for this placement (CPC, CPM, CPA, etc.). |
| `CostValue` | varchar(4000) | Cost amount per unit in the cost model. |
| `CostCurrency` | varchar(4000) | Currency of the cost value. |

### Multi-Touch Attribution (Contributor Columns)

AppFlyer records up to 3 contributing touchpoints before the attributed install. Contributor1 is the most recent non-attributed touch.

| Column | Type | Description |
|--------|------|-------------|
| `Contributor1Partner` | varchar(4000) | Partner of the first contributing (non-attributed) touch. |
| `Contributor1MediaSource` | varchar(4000) | Media source of contributing touch 1. |
| `Contributor1Campaign` | varchar(4000) | Campaign of contributing touch 1. |
| `Contributor1TouchType` | varchar(4000) | Touch type of contributing touch 1 (click/impression). |
| `Contributor1TouchTime` | varchar(4000) | Timestamp of contributing touch 1, stored as varchar. SP converts 'None'/'USD'/'usd' → NULL. |
| `Contributor2Partner` | varchar(4000) | Partner of contributing touch 2. |
| `Contributor2MediaSource` | varchar(4000) | Media source of contributing touch 2. |
| `Contributor2Campaign` | varchar(4000) | Campaign of contributing touch 2. |
| `Contributor2TouchType` | varchar(4000) | Touch type of contributing touch 2. |
| `Contributor2TouchTime` | varchar(4000) | Timestamp of contributing touch 2, stored as varchar. Same NULL conversion as Contributor1TouchTime. |
| `Contributor3Partner` | varchar(4000) | Partner of contributing touch 3. |
| `Contributor3MediaSource` | varchar(4000) | Media source of contributing touch 3. |
| `Contributor3Campaign` | varchar(4000) | Campaign of contributing touch 3. |
| `Contributor3TouchType` | varchar(4000) | Touch type of contributing touch 3. |
| `Contributor3TouchTime` | **datetime** | Timestamp of contributing touch 3, stored as datetime (inconsistent with Contributor1/2TouchTime which are varchar — architectural anomaly). |

### Geographic Columns

| Column | Type | Description |
|--------|------|-------------|
| `Region` | varchar(4000) | AppFlyer macro-region code (e.g., `EU`, `AS`, `NA`). |
| `CountryCode` | varchar(4000) | ISO-2 country code. SP applies `CASE WHEN 'UK' THEN 'GB'` standardization (unlike `BI_DB_AppFlyer_Geo` which does not). |
| `State` | varchar(4000) | State or province (where available). |
| `City` | varchar(500) | **DDM-masked** with `default()` function. Shows as `'xxxx'` to non-privileged users. Contains the city of the device at install/event time. |
| `PostalCode` | varchar(4000) | Postal/ZIP code of the device. |
| `DMA` | varchar(4000) | DMA (Designated Market Area) code — US-only market area identifier. 'None' for non-US. |
| `Operator` | varchar(4000) | Mobile network operator name (e.g., 'Vodafone'). |
| `Carrier` | varchar(4000) | Mobile carrier identifier. |
| `WIFI` | varchar(4000) | `'true'` / `'false'` string. Whether the device was on Wi-Fi at the time of the event. |

### Device & App Columns

| Column | Type | Description |
|--------|------|-------------|
| `AppsFlyerID` | varchar(4000) | AppFlyer's unique device+install identifier. Primary key at AppFlyer's system level — identifies a specific install on a specific device. |
| `AdvertisingID` | varchar(4000) | Android GAID (Google Advertising ID) — device-level advertising identifier for Android. |
| `IDFA` | varchar(4000) | iOS IDFA (Identifier for Advertisers) — device-level advertising identifier for iOS. May be empty post-iOS14 ATT framework changes. |
| `IDFV` | varchar(4000) | iOS IDFV (Identifier for Vendor) — app-level device identifier for iOS. |
| `AndroidID` | varchar(4000) | Android hardware device ID. |
| `IMEI` | varchar(4000) | Device IMEI number. Typically empty for modern devices (IMEI collection restricted). |
| `CustomerUserID` | varchar(4000) | Hashed eToro customer identifier passed to AppFlyer at registration/login. Links AppFlyer events to eToro users. Present on InAppEvents for registered users; empty on raw installs. |
| `Platform` | varchar(4000) | Mobile OS: `'android'` or `'ios'`. ~75% android, ~23% ios; ~2% None (unknown/legacy). |
| `DeviceType` | varchar(4000) | Device form factor (phone, tablet). Often empty. |
| `OSVersion` | varchar(4000) | Operating system version string (e.g., `'13'`, `'16.1.1'`). |
| `AppVersion` | varchar(4000) | eToro app version string (e.g., `'651.114.0'`, `'618.0.0'`). |
| `SDKVersion` | varchar(4000) | AppFlyer SDK version embedded in the app (e.g., `'v6.12.2'`). |
| `AppID` | varchar(4000) | App store identifier (Android: `'com.etoro.openbook'`; iOS: `'id674984916'`). Uses dot notation (native format), unlike `EtoroAppID`. |
| `AppName` | varchar(4000) | App store display name at the time of the event. Not a constant — changed over time (e.g., `'eToro: Investing made social'` → `'eToro: Trade. Invest. Connect.'`). |
| `BundleID` | varchar(4000) | iOS/Android bundle identifier. Same value as `AppID`. |
| `Language` | varchar(4000) | Device language setting (e.g., `'Deutsch'`, `'English'`). |
| `UserAgent` | varchar(4000) | HTTP user agent string from the attribution redirect. Often empty. |

### Event Columns

| Column | Type | Description |
|--------|------|-------------|
| `EventName` | varchar(4000) | Name of the event as reported by AppFlyer. For install rows: `'install'`. For InAppEvents: business event names such as `'Open Trade'` (24.6M), `'Registration_S2S'` (2.1M), `'Redeposit_S2S'` (2.1M), `'registration'` (1.9M), `'Verification Level - 1/2/3'`, `'Redeposit'`, `'FTD_S2S'`. Suffix `_S2S` = server-to-server event reported by eToro backend (more reliable than SDK events). |
| `EventTime` | varchar(4000) | Timestamp string of when the in-app event fired (stored as varchar, not cast to datetime). For install events, same as `InstallTime`. |
| `EventValue` | varchar(4000) | JSON payload for in-app events containing AppFlyer event parameters. Example: `{"af_content":"Bitcoin","af_content_type":"Crypto","af_content_id":"100000","is_copy":"False","af_revenue":"14"}`. Empty for install events. |
| `EventRevenue` | varchar(4000) | Revenue amount associated with this event in the reported currency. Populated for trade events (e.g., `'14'`, `'250'`, `'2244'`). |
| `EventRevenueCurrency` | varchar(4000) | Currency of EventRevenue (typically `'USD'`). |
| `EventRevenueUSD` | varchar(4000) | Revenue converted to USD. Same value as EventRevenue when currency is already USD. |
| `EventSource` | varchar(4000) | How the event was reported: `'SDK'` (AppFlyer SDK on device, ~95M rows) or `'S2S'` (server-to-server from eToro backend, ~31.5M rows). ~1M rows have garbled values (malformed JSON fragments from upstream AppFlyer export data quality issues). |
| `IsReceiptValidated` | varchar(4000) | AppFlyer receipt validation result for in-app purchases. Typically empty (most events are not app-store purchases). |
| `HTTPReferrer` | varchar(4000) | HTTP referrer URL from the AppFlyer attribution redirect. Truncated to 4000 chars by SP (`LEFT([HTTPReferrer], 4000)`). |
| `OriginalURL` | varchar(4000) | Original deep link URL used in the attribution (e.g., `etoro://markets/gold`). |

### ETL & Partition Columns

| Column | Type | Description |
|--------|------|-------------|
| `DateID` | INT | Event date as YYYYMMDD integer. ETL partition key used by SP for DELETE+INSERT targeting. `DateID = Date` in YYYYMMDD format. |
| `Date` | datetime | Event date (the date on which this install or in-app event occurred). **Not the install date** for InAppEvents — may differ from `InstallTime` significantly. |
| `EtoroAppID` | varchar(4000) | AppFlyer app identifier: `'com_etoro_openbook'` (Android, using underscore separator) or `'id674984916'` (iOS). |
| `EtoroAppName` | varchar(4000) | Human-readable platform label: `'OneApp Android'` or `'OneApp iOS'`. Set by the AppFlyer export config; consistent within this table. |
| `EtoroReport` | varchar(4000) | AppFlyer report type — the key partition dimension. Values: `'OrganicInstalls'` (86.3M), `'InAppEvents'` (35.6M), `'Installs'` (6.8M). Always filter by this column to avoid mixing event types. |
| `UpdateDate` | datetime | **Always NULL.** Column exists in DDL but is not in the SP INSERT list — never populated. |

## 6. ETL Notes

- **SP_AppFlyer_Reports** runs daily with parameter `@dt DATE`. DELETE WHERE `DateID = @dt_int` then INSERT from `BI_DB_AppFlyer_Reports_Ext`.
- Most columns pass through unchanged from the all-varchar staging table — only `AttributedTouchTime`, `InstallTime`, `Contributor3TouchTime` are cast to datetime; `DateID` is int; `Date` is datetime.
- `CountryCode` is the only standardization applied: 'UK' → 'GB'.
- `HTTPReferrer` is truncated to 4000 chars (same as column size — prevents overflow).
- `UpdateDate` was likely intended for ETL timestamp tracking but was never wired into the INSERT.

## 7. Usage Notes

- **Always filter by `EtoroReport`** before aggregating — mixing install and in-app event rows produces meaningless counts.
- **Install funnel**: `EtoroReport IN ('OrganicInstalls','Installs')` AND `EventName = 'install'` → unique installs per channel/geo.
- **Revenue attribution**: `EtoroReport = 'InAppEvents'` AND `EventName IN ('Open Trade','FTD_S2S','Redeposit_S2S')` → attributed revenue events.
- **User linkage**: `CustomerUserID` links AppFlyer events to eToro users (hashed). Available for InAppEvents from registered users; empty on raw installs.
- **Date vs InstallTime**: For cohort analysis (events by install month), use `InstallTime`. For event volume analysis (events by calendar day), use `Date`/`DateID`.
- **S2S vs SDK events**: `EventSource = 'S2S'` events are server-reported (higher fidelity). `EventSource = 'SDK'` events come from the device SDK (may have delays or duplicates in edge cases).
- **Platform split**: `Platform = 'android'` (75%) vs `Platform = 'ios'` (23%). `EtoroAppID` provides a cleaner split than `Platform` (no None rows).
- **City data**: Only accessible to privileged users with unmasked access to DDM columns.
- **Aggregate geo summary**: For aggregate country-level metrics without PII sensitivity, use `BI_DB_AppFlyer_Geo` instead.

## 8. Quality & Caveats

| Issue | Detail |
|-------|--------|
| `UpdateDate` always NULL | Column exists in DDL but SP never populates it. Do not use for ETL freshness tracking. |
| `EventSource` garbled values | ~1.1M rows have malformed EventSource values (fragments like `"af_revenue":"0"}"` or `USD`). These are upstream AppFlyer data quality issues, not ETL corruption. Filter `EventSource IN ('SDK','S2S')` for clean analysis. |
| `Contributor3TouchTime` type mismatch | DDL types it as `datetime` while `Contributor1/2TouchTime` are `varchar`. SP behavior is consistent (NULL cleanup), but the inconsistency means Contributor3TouchTime cannot hold the same malformed strings that Contributor1/2 might. |
| `City` DDM-masked | Shows as `'xxxx'` to non-privileged users. Cannot be used for geographic analysis without elevated access. |
| IDFA sparsity | Post-iOS14 ATT framework (2021), most iOS users opt out of IDFA tracking. Expect high NULL/empty rate for IDFA on recent iOS rows. |
| `AppName` not constant | Changed across app versions. Do not use as a stable filter — use `EtoroAppID` or `Platform` instead. |
| `EventTime` as varchar | Stored as string, not datetime. Parse with `TRY_CAST(EventTime AS datetime)` if needed. |
| No CID column | `CustomerUserID` is hashed — requires mapping to resolve to eToro CIDs. For user-level eToro analytics, join via the CustomerUserID hash mapping table (if available). |
