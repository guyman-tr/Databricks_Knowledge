---
name: domain-marketing-and-acquisition
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-08"
description: >
  AppFlyer (mobile-measurement-partner) mobile-attribution layer for the eToro
  OneApp Android and OneApp iOS apps. Anchors on
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports (131M
  rows: Installs, OrganicInstalls, InAppEvents — partitioned via EtoroReport,
  carrying multi-touch attribution chain, S2S vs SDK event source, post-iOS14
  IDFA / IDFV / AppsFlyerID / AdvertisingID identifiers, EventName taxonomy
  Open Trade / Registration_S2S / FTD_S2S / Redeposit_S2S / Verification Level
  - 1/2/3, EventRevenueUSD on trade events) and on the CID bridge
  main.bi_db.bronze_marketperformance_tracking_customer (48M rows mapping CID
  to AppsflyerID / FirebaseID / IDFV plus the iOSAdTrackingPermissionID ATT
  flag). Covers per-vendor install attribution, organic vs paid install split,
  ATT-framework IDFA opt-in coverage, multi-touch contributor chain, retargeting
  / re-engagement (currently dormant), S2S-vs-SDK event-source reconciliation,
  EventName-to-business-event mapping, cohort revenue from in-app events, and
  the join path from AppFlyer device identity back to eToro CID for funnel
  analysis. Source SP is BI_DB.dbo.SP_AppFlyer_Reports.
triggers:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
  - gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
  - BI_DB_AppFlyer_Reports
  - bi_db_appflyer_reports
  - appflyer_reports
  - appflyer
  - AppFlyer
  - AppsFlyer
  - apps_flyer
  - apps-flyer
  - main.bridgeclaw_permitted_data.appflyer_reports
  - bridgeclaw_permitted_data.appflyer_reports
  - bronze_marketperformance_tracking_customer
  - marketperformance_tracking_customer
  - SP_AppFlyer_Reports
  - BI_DB.dbo.SP_AppFlyer_Reports
  - mobile attribution
  - mobile install
  - mobile installs
  - app install
  - app installs
  - app-install
  - install attribution
  - mobile measurement partner
  - MMP
  - MMP postback
  - postback
  - post-back
  - S2S
  - S2S event
  - server-to-server
  - server to server
  - SDK event
  - SDK source
  - SDK install
  - multi-touch attribution
  - multi touch attribution
  - last-touch attribution
  - last touch attribution
  - view-through attribution
  - view through
  - click attribution
  - impression attribution
  - attribution chain
  - contributor chain
  - attribution lookback
  - retargeting
  - re-engagement
  - reengagement
  - re-attribution
  - re attribution
  - organic install
  - OrganicInstalls
  - Installs
  - InAppEvents
  - in-app event
  - in app event
  - in-app revenue
  - EtoroReport
  - EventName
  - EventSource
  - EventValue
  - EventRevenue
  - EventRevenueUSD
  - EventRevenueCurrency
  - AttributedTouchType
  - AttributedTouchTime
  - InstallTime
  - Contributor1Partner
  - Contributor1MediaSource
  - Contributor1Campaign
  - Contributor1TouchType
  - Contributor1TouchTime
  - Contributor2Partner
  - Contributor2MediaSource
  - Contributor2Campaign
  - Contributor3Partner
  - Contributor3MediaSource
  - IsRetargeting
  - RetargetingConversionType
  - IsPrimaryAttribution
  - IsReceiptValidated
  - AttributionLookback
  - ReengagementWindow
  - HTTPReferrer
  - OriginalURL
  - CostModel
  - CostValue
  - AppsFlyerID
  - AppsflyerID
  - AppsFlyerId
  - IDFA
  - IDFV
  - AdvertisingID
  - Google Advertising ID
  - Android GAID
  - GAID
  - AndroidID
  - device id
  - mobile device id
  - device identifier
  - mobile device identifier
  - CustomerUserID
  - customer user id
  - hashed CID
  - FirebaseID
  - Firebase ID
  - iOSAdTrackingPermissionID
  - ATT
  - App Tracking Transparency
  - ATT framework
  - ATT consent
  - ATT opt-in
  - ATT opt in
  - ATT opt-out
  - iOS14
  - iOS 14
  - iOS14.5
  - iOS 14.5
  - SKAdNetwork
  - SK Ad Network
  - SK ad-network
  - OneApp
  - OneApp Android
  - OneApp iOS
  - EtoroAppID
  - EtoroAppName
  - com.etoro.openbook
  - id674984916
  - MediaSource
  - googleadwords_int
  - Google UAC
  - tiktokglobal_int
  - bytedanceglobal_int
  - Apple Search Ads
  - ASA
  - Facebook Ads
  - Facebook install
  - snapchat_int
  - taboola_int
  - smadex_int
  - bidease_int
  - moloco_int
  - dipperads_int
  - edge_int
  - persona.ly_int
  - peppaads_int
  - mobwonder_int
  - adtiming_int
  - xyads_int
  - appfloodaff_int
  - riversads_int
  - eToroWeb
  - DesktopLogoutScreen
  - QR_code
  - restricted attribution
  - restricted MediaSource
  - Organic
  - OneLink
  - deep link
  - deep-link
  - deferred deep link
  - deferred deeplink
  - install cohort
  - mobile cohort
  - device cohort
  - cohort by install
  - app revenue
  - in-app purchase revenue
  - mobile FTD
  - mobile registration
  - Open Trade
  - open trade
  - Registration_S2S
  - registration_s2s
  - FTD_S2S
  - ftd_s2s
  - Redeposit_S2S
  - redeposit_s2s
  - FTDE_S2S
  - ftde_s2s
  - Verification Level - 1
  - Verification Level - 2
  - Verification Level - 3
  - verification level
  - VIEW_SIGNIN_SIGNUP
  - enableUninstallTracking
  - Launched
  - DMA
  - Designated Market Area
  - AppVersion
  - SDKVersion
  - AppID mobile
  - BundleID
  - AdvertisingID null
  - IDFA null
  - IDFA opt-out
  - post-iOS14
  - probabilistic attribution
  - fingerprint attribution
  - SKAdNetwork campaign
  - SKAdNetwork postback
sample_questions:
  - "How many AppFlyer-attributed installs did paid TikTok drive last week?"
  - "Split organic vs paid installs by week for OneApp Android in 2026"
  - "Show in-app revenue (EventRevenueUSD) on Open Trade events by MediaSource last quarter"
  - "FTD_S2S vs FTD count from AppFlyer for googleadwords_int last month"
  - "What share of iOS installs have a non-null IDFA today vs 2021?"
  - "Install cohort retention: of users installed in 2026-01, how many reached Verification Level - 3 by 2026-03?"
  - "Reconcile FTD_S2S in AppFlyer with FTD_S2S in v_marketing_campaigns_social"
  - "What's the SDK vs S2S split on Open Trade events by Platform?"
  - "Are we running any retargeting / re-engagement campaigns? (IsRetargeting distribution)"
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
  - main.bi_db.bronze_marketperformance_tracking_customer
  - main.bridgeclaw_permitted_data.appflyer_reports
domain_tags:
  - marketing
  - attribution
  - mobile
  - mmp
  - appflyer
  - install
  - cohort
---

# AppFlyer mobile attribution (OneApp Android / iOS)

AppFlyer is eToro's mobile-measurement partner (MMP). The OneApp Android and OneApp iOS apps embed the AppFlyer SDK plus server-side S2S postbacks from the eToro backend, and the joined feed lands in **`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports`**: 131,364,241 rows, 89 columns, range 2022-10-25 → 2026-06-07 (yesterday, ETL alive). The upstream Synapse SP is `BI_DB.dbo.SP_AppFlyer_Reports`.

The vendor spells its product **AppsFlyer** (with `s`). eToro's column / table naming standardised on **AppFlyer** (no `s`) in the gold layer (`appflyer_reports`, `BI_DB_AppFlyer_Reports`, `BI_DB_AppFlyer_Geo`). The CID-bridge table uses the vendor spelling: `bronze_marketperformance_tracking_customer.AppsflyerID`. Both refer to the same identifier.

## Anchor tables

| Table | Rows | Cols | What it carries |
|---|---:|---:|---|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports` | 131.4M | 89 | The mobile-attribution fact: Installs + OrganicInstalls + InAppEvents. Partitioned conceptually by `EtoroReport`. |
| `main.bi_db.bronze_marketperformance_tracking_customer` | 48.0M | 11 | CID → device-identity bridge. 1 row per CID. Carries `AppsflyerID`, `FirebaseID`, `IDFV`, `iOSAdTrackingPermissionID`, `UserUniqueIdentifierCookie`. |
| `main.bridgeclaw_permitted_data.appflyer_reports` | (view) | — | Permissioned view over the gold fact — same shape, restricted access. |

## EtoroReport — the partition key you must always filter

| EtoroReport | Rows | What it is |
|---|---:|---|
| `OrganicInstalls` | 86.5M | Installs with no attributable paid touch (organic + SKAdNetwork-restricted) |
| `InAppEvents` | 37.8M | Post-install in-app events (trades, registrations, verifications, redeposits) |
| `Installs` | 7.0M | Paid / attributable installs |

**Always filter `EtoroReport = '<one of the three>'`** — mixing the classes triple-counts the same install across event types.

## EventName taxonomy (InAppEvents)

Order by row count:

| EventName | Rows | Type |
|---|---:|---|
| `Open Trade` | 26.0M | Position opened (SDK + S2S) |
| `Redeposit_S2S` | 2.4M | Repeat deposit (server-to-server) |
| `Registration_S2S` | 2.2M | Account registration (S2S) |
| `registration` | 1.9M | SDK-side registration (lowercase) |
| `Verification Level - 1` | 1.5M | KYC step 1 |
| `Verification Level - 2` | 1.2M | KYC step 2 |
| `Redeposit` | 1.1M | SDK-side redeposit |
| `Verification Level - 3` | 0.7M | KYC step 3 (FTD-eligible) |
| `FTD_S2S` | 272k | First-time deposit (S2S) |
| `FTD` | 204k | First-time deposit (SDK) |
| `FTDE_S2S` | 132k | First-time deposit (e — exchange variant, S2S) |
| `VIEW_SIGNIN_SIGNUP` | 6.9k | View of the auth screen |
| `open trade` | 3.5k | Same event as `Open Trade`, case bug |
| `verification level - 1/2/3` | ~200 each | Lower-case typo variants |
| `Launched` | 245 | App launch |
| `enableUninstallTracking Android` | 2 | One-shot Android tracking toggle |

`_S2S` events are first-class — server-side acknowledgements from the eToro backend, fired regardless of whether the SDK is online. Prefer them over the matching SDK event for revenue / FTD / registration analysis.

## MediaSource (top channels)

| MediaSource | Rows (Installs+InAppEvents) | What it is |
|---|---:|---|
| `googleadwords_int` | 15.4M | Google UAC (Universal App Campaigns) |
| (empty string) | 5.0M | Pre-attribution bucket |
| `Apple Search Ads` | 3.5M | ASA |
| `restricted` | 2.5M | iOS14 ATT-opt-out (Apple-restricted attribution) |
| `Website` | 1.5M | Web-to-app install (cross-platform redirect) |
| `None` | 1.2M | Explicit non-attributable |
| `smadex_int` | 1.1M | Smadex DSP |
| `0.0` | 1.1M | **Data-quality artifact** — see warning 12 |
| `tiktokglobal_int` | 0.9M | TikTok For Business |
| `eToroWeb` | 0.7M | eToro web-to-app deep link |
| `taboola_int` | 0.6M | Taboola |
| `bidease_int` | 0.6M | Bidease DSP |
| `snapchat_int` | 0.5M | Snapchat |
| `bytedanceglobal_int` | 0.4M | ByteDance Global |
| `dipperads_int` | 0.3M | Dipper Ads |
| `Twitter` | 0.3M | Twitter / X |
| `QR_code` | 0.3M | QR-code campaign |
| `edge_int` | 0.3M | Edge |
| `DesktopLogoutScreen` | 0.2M | Desktop logout-screen prompt |
| ~50 more `*_int` partners | … | Long-tail DSPs / ad networks (`_int` suffix = AppFlyer integrated partner) |

The `_int` suffix marks AppFlyer-integrated networks (postback-supported). `eToroWeb` / `Website` / `DesktopLogoutScreen` / `QR_code` are eToro-side first-party sources. `restricted` is the iOS14 ATT bucket — see warning 5.

## EventSource — SDK vs S2S split

| EventSource | Platform | Rows | Notes |
|---|---|---:|---|
| `SDK` | android | 80.8M | AppFlyer SDK on Android device |
| `S2S` | android | 15.9M | Server-to-server from eToro backend |
| `S2S` | ios | 15.7M | S2S on iOS (iOS S2S coverage > SDK because of ATT) |
| `SDK` | ios | 14.7M | SDK events on iOS (post-ATT-consent-only) |
| garbage values | None | ~1M | JSON fragments — see warning 2 |

## CID bridge

```sql
SELECT mp.CID, a.EventName, a.EventRevenueUSD, a.MediaSource, a.Date
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports a
JOIN main.bi_db.bronze_marketperformance_tracking_customer mp
  ON a.AppsFlyerID = mp.AppsflyerID
WHERE a.EtoroReport = 'InAppEvents'
  AND a.EventName = 'FTD_S2S'
  AND a.Date >= DATE'2026-05-01'
```

Two device-identity surfaces:

| Field | Where | What it identifies | Coverage |
|---|---|---|---:|
| `AppsFlyerID` | gold fact | Per-install device identifier (privacy-safe; AppFlyer-issued) | ~131M (every row) |
| `AppsflyerID` | tracking_customer | Same value as above, indexed by CID | 20.2M distinct |
| `CustomerUserID` | gold fact | Hashed CID, populated on InAppEvents (post-registration) | 34.4M rows (26%) |
| `IDFA` | gold fact | iOS device-level ad ID — empty post-ATT-opt-out | 10.8M rows (8%) |
| `AdvertisingID` (GAID) | gold fact | Android device-level ad ID | 80.9M rows (62%) |
| `FirebaseID` | tracking_customer | Firebase install ID | 8.9M distinct |

For per-CID rollups: prefer the bridge join. `CustomerUserID` IS the hashed CID but null on 74% of rows (all Installs + OrganicInstalls have no CID yet).

## Multi-touch attribution chain

`AttributedTouch*` is the **last** touch that earned the install credit. `Contributor1/2/3*` are up to three earlier touches that contributed but did not win the attribution model:

```
Contributor3 (oldest)  →  Contributor2  →  Contributor1  →  AttributedTouch (winner)
```

Each contributor slot carries `Partner`, `MediaSource`, `Campaign`, `TouchType` (click / impression), `TouchTime`. Use these for view-through analysis ("how often did Facebook contribute to a Google-attributed install?") and for cross-channel-credit redistribution.

## When to Use

Load this sub-skill when the question is about:

- **AppFlyer / AppsFlyer in any spelling** — installs, in-app events, mobile attribution, multi-touch chains, retargeting status
- **OneApp Android / OneApp iOS** — anything mobile-app-specific (Open Trade, Registration_S2S, FTD_S2S, Verification Level events sourced from the app)
- **MMP postbacks / S2S events** — server-to-server reconciliation, SDK vs S2S coverage gaps
- **iOS14 ATT framework / IDFA decline** — opt-in coverage, post-ATT identifier strategy, SKAdNetwork-restricted attribution
- **Mobile install cohorts** — install-date cohorts → downstream conversion (registration → VL3 → FTD)
- **AppFlyer device identifiers** — `AppsFlyerID`, `IDFA`, `IDFV`, `AdvertisingID` / GAID, `AndroidID`, `CustomerUserID`, `FirebaseID`
- **CPI / cost-per-install / cost-per-FTD on mobile channels** — `googleadwords_int` (Google UAC), `Apple Search Ads`, `tiktokglobal_int`, `bytedanceglobal_int`, `snapchat_int`, `taboola_int`, `smadex_int`, etc.
- **Multi-touch / view-through attribution** — `Contributor1/2/3*` chains
- **CID-to-device bridge** for mobile-funnel analysis — `bronze_marketperformance_tracking_customer`

Do **not** load for:

- Pre-aggregated paid-media cost / channel ROI at the **vendor-feed grain** (Google UAC, FB, TikTok, Apple Search Ads cost reports) → `affiliate-and-paid-media.md` — that sub-skill owns `v_marketing_campaigns_social` / `_google` plus the Fivetran vendor-feed bronzes
- Affiliate platform (Fiktivo) / `dim_affiliate_masked` per-affiliate rankings → `affiliate-and-paid-media.md`
- Mixpanel pageview / event stream and product-event-driven attribution on the **web** funnel → `domain-product-analytics/mixpanel-events-and-pageviews.md`
- SFMC email engagement, push notifications → `marketing-comms-and-sfmc.md`
- FTD definition / FirstTimeFunded formula / IsFunded → `domain-customer-and-identity/customer-populations-and-lifecycle.md`

## Scope

In scope: the AppFlyer mobile-attribution fact at `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports` (89 columns, 131M rows) with all three `EtoroReport` event classes; the CID-bridge at `main.bi_db.bronze_marketperformance_tracking_customer` (48M rows, 11 columns) including `AppsflyerID` / `FirebaseID` / `IDFV` / `iOSAdTrackingPermissionID`; the permissioned-access view `main.bridgeclaw_permitted_data.appflyer_reports`; the `BI_DB.dbo.SP_AppFlyer_Reports` Synapse loader; the multi-touch attribution chain (`Contributor1/2/3*`); the SDK vs S2S event-source reconciliation; the iOS14 ATT-framework identifier-decline workstream; install-to-FTD cohort analysis via the CID join; per-Partner / per-MediaSource / per-Campaign / per-Adset / per-Ad performance; the retargeting / re-engagement columns (currently dormant — flagged in warnings).

Out of scope: vendor-side cost / impression / click feeds (those live in Fivetran-fed `bronze_fivetran_apple_search_ads_*` / `bronze_fivetran_tiktok_ads_*` / `bronze_fivetran_adwords_*` etc., aggregated up to `v_marketing_campaigns_social` / `_google` — see `affiliate-and-paid-media.md`); Fiktivo affiliate platform metrics; SFMC email engagement; Mixpanel web pageview / event telemetry (`domain-product-analytics/mixpanel-events-and-pageviews.md`); ABtoro experiment variant assignment; the actual FTD-definition formula and IsFunded SCD walk; finance / treasury cost-allocation of mobile spend.

Last verified: 2026-06-08

## Critical Warnings

1. **Tier 0 — Always filter `EtoroReport`.** The fact mixes three event classes that should never be summed together. `OrganicInstalls` (86.5M) + `Installs` (7.0M) = total installs, but `InAppEvents` (37.8M) is post-install events on already-installed devices. Counting installs without `EtoroReport IN ('Installs','OrganicInstalls')` triple-counts via InAppEvents that share an InstallTime. Counting in-app events without `EtoroReport = 'InAppEvents'` includes install-class rows where `EventName = 'install'` artificially.

2. **Tier 0 — Always filter `EventSource IN ('SDK','S2S')`.** ~1M rows carry malformed values in `EventSource` from an upstream AppFlyer export bug — values like `""af_revenue"":""0""}"`, `USD`, `None`, `""is_copy"":""False""` (JSON fragments leaked into a column they don't belong in). Without the filter, any group-by on `EventSource` is dominated by garbage strings.

3. **Tier 0 — Prefer `_S2S` events for revenue / FTD / registration.** `Registration_S2S` / `FTD_S2S` / `FTDE_S2S` / `Redeposit_S2S` are server-to-server postbacks from the eToro backend — survive ad-blockers, SDK init failures, and ATT opt-out. The matching SDK events (`registration`, `FTD`, `Redeposit`) under-count systematically.

4. **Tier 1 — `CustomerUserID` is empty on installs.** On `Installs` and `OrganicInstalls` the user has not yet registered, so no CID exists — `CustomerUserID` is NULL / empty. Only 26% of total fact rows (34.4M / 131.4M) carry a populated `CustomerUserID`. For per-CID install attribution, join via `bronze_marketperformance_tracking_customer.AppsflyerID` instead — the bridge resolves device-to-CID once registration happens.

5. **Tier 1 — iOS14 ATT killed IDFA.** Apple's App Tracking Transparency framework (iOS 14.5+, released 2021-04) requires per-app opt-in for IDFA. Empirical coverage: 10.8M / 131.4M rows have a real IDFA (~8% total; ~36% of iOS rows). For iOS install attribution use `AppsFlyerID` (vendor's privacy-safe install-level ID) — not IDFA — as the primary device key. Use `iOSAdTrackingPermissionID` on `bronze_marketperformance_tracking_customer` to filter by ATT-consent state. The `MediaSource = 'restricted'` bucket (2.5M rows) is SKAdNetwork-aggregated attribution from iOS opt-out users — exclusive of any other MediaSource for that install.

6. **Tier 1 — `Date` ≠ `InstallTime` on InAppEvents.** `Date` is the event date (when the trade / registration / FTD happened); `InstallTime` is when the device first installed the app. A 2026 trade event on a device installed in 2023 has `Date = 2026-XX-XX`, `InstallTime = 2023-XX-XX`. For event-period analysis (`"FTDs last month"`) filter `Date` or `DateID`. For install-cohort analysis (`"of installs in 2026-01, how many FTD'd by 2026-03"`) filter `InstallTime` and roll up `Date`.

7. **Tier 1 — Do NOT sum `FTD_S2S` here with `FTD_S2S` in `v_marketing_campaigns_social`.** Same business event, different attribution lens. `v_marketing_campaigns_social` (in `affiliate-and-paid-media.md`) is pre-aggregated to Region × Channel × Date with web + mobile attribution merged. This table is per-event, per-device, mobile-only. Use ONE source per question. Reconciliation queries that compare the two should JOIN, not UNION.

8. **Tier 1 — `Contributor1TouchTime` and `Contributor2TouchTime` are STRING, not TIMESTAMP.** The SP converts `'None'`/`'USD'`/`'usd'` placeholder strings to NULL but stores the rest as varchar. `Contributor3TouchTime` IS TIMESTAMP. Watch the type asymmetry when ordering touches chronologically — cast Contributor1/2 with `try_to_timestamp` first.

9. **Tier 1 — `IsRetargeting` is always `'false'` or empty in the current snapshot.** Zero rows with `IsRetargeting = 'true'` as of 2026-06-08. The column is wired into AppFlyer but eToro is not running retargeting / re-engagement campaigns through the MMP integration. Don't filter on it expecting results — `RetargetingConversionType` is correspondingly always NULL. (Flag for vendor onboarding if a re-engagement campaign launches.)

10. **Tier 1 — `UpdateDate` is always NULL.** Column exists in DDL but is excluded from the SP INSERT list — never populated. For freshness use `MAX(Date)` or `MAX(InstallTime)`.

11. **Tier 1 — `City` is DDM-masked.** Default-masking function applied; non-privileged users see `'xxxx'`. Cannot pivot by city without elevated access. `Region` / `CountryCode` / `State` / `PostalCode` / `DMA` are NOT masked.

12. **Tier 2 — `Platform` and `MediaSource` carry dirty values.** `Platform`: ~3M rows have GUID-shaped strings (looks like an IDFA leaked into the wrong column) — filter `Platform IN ('android','ios','None')` for clean grouping. `MediaSource`: `'0.0'` (1.07M rows) and pure-numeric strings (e.g. `'65315'`) appear due to upstream export bugs — they cluster with `EventSource = 'None'`.

13. **Tier 2 — Naming: AppFlyer (no `s`) vs AppsFlyer (with `s`).** The vendor's product is **AppsFlyer**. eToro stores the fact table as **AppFlyer** (no `s`) and exposes columns like `AppsFlyerID` (vendor spelling preserved). The bridge table uses **AppsflyerID** (lowercase `f`). When searching the catalog or grep'ing schema files, try both spellings.

14. **Tier 2 — `Region` is AppFlyer's macro-region code (EU / AS / NA), not eToro's `newmarketingregion`.** Do not join on `Region` to the marketing-region SCD; the codes differ. Use `CountryCode` (ISO-2, with the SP's `UK → GB` standardisation) for country-grain joins.

15. **Tier 2 — `EtoroAppID` vs `AppID` notation.** `AppID` uses dot-notation (`'com.etoro.openbook'` on Android, `'id674984916'` on iOS — the native store identifiers). `EtoroAppID` uses underscore-notation (`'com_etoro_openbook'`, `'id674984916'`) for the AppFlyer-export-config key. Both identify the same app per platform.

## Common queries (skeletons)

**Daily installs, organic vs paid:**

```sql
SELECT Date, EtoroReport,
       SUM(CASE WHEN MediaSource = 'Organic' OR EtoroReport = 'OrganicInstalls' THEN 1 ELSE 0 END) AS organic,
       SUM(CASE WHEN MediaSource <> 'Organic' AND EtoroReport = 'Installs' THEN 1 ELSE 0 END) AS paid
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
WHERE EtoroReport IN ('Installs','OrganicInstalls')
  AND Date BETWEEN DATE'2026-05-01' AND DATE'2026-05-31'
GROUP BY Date, EtoroReport ORDER BY Date
```

**Install → FTD funnel by MediaSource (last 30 days), S2S only:**

```sql
WITH inst AS (
  SELECT MediaSource, AppsFlyerID, MIN(InstallTime) AS install_ts
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
  WHERE EtoroReport IN ('Installs','OrganicInstalls')
    AND InstallTime >= current_timestamp() - INTERVAL 30 DAYS
  GROUP BY MediaSource, AppsFlyerID
),
ftd AS (
  SELECT AppsFlyerID, MIN(Date) AS ftd_date
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
  WHERE EtoroReport = 'InAppEvents'
    AND EventName = 'FTD_S2S'
    AND EventSource IN ('SDK','S2S')
  GROUP BY AppsFlyerID
)
SELECT inst.MediaSource,
       COUNT(*) AS installs,
       COUNT(ftd.AppsFlyerID) AS ftds,
       100.0 * COUNT(ftd.AppsFlyerID) / COUNT(*) AS pct
FROM inst LEFT JOIN ftd USING (AppsFlyerID)
GROUP BY inst.MediaSource
ORDER BY installs DESC
```

**SDK vs S2S coverage on FTD events:**

```sql
SELECT Platform, EventSource, COUNT(*) AS rows
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
WHERE EtoroReport = 'InAppEvents'
  AND EventName IN ('FTD','FTD_S2S')
  AND EventSource IN ('SDK','S2S')
  AND Platform IN ('android','ios')
  AND Date >= current_date() - INTERVAL 30 DAYS
GROUP BY Platform, EventSource
ORDER BY Platform, EventSource
```

**Per-CID mobile-event lookup via the bridge:**

```sql
SELECT mp.CID, a.EventName, a.EventRevenueUSD, a.MediaSource, a.Date
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports a
JOIN main.bi_db.bronze_marketperformance_tracking_customer mp
  ON a.AppsFlyerID = mp.AppsflyerID
WHERE a.EtoroReport = 'InAppEvents'
  AND a.EventSource IN ('SDK','S2S')
  AND mp.CID = :cid
ORDER BY a.Date
```
