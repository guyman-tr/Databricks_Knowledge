---
table: BI_DB_dbo.BI_DB_AppFlyer_Geo
schema: BI_DB_dbo
documented: 2026-04-22
batch: 51
quality_score: 8.5
tier: Tier 3
row_count_approx: 500000+
date_range: 2022-10-29 to 2023-09-17
etl_frequency: Daily
etl_sp: BI_DB_dbo.SP_AppFlyer_Geo
opsdb_priority: 0
---

# BI_DB_AppFlyer_Geo

## 1. Purpose

Daily mobile app acquisition metrics from the **AppFlyer attribution platform**, aggregated at the **country × media source × campaign × app** level. This table is the geographic-level AppFlyer report — each row represents a unique combination of date, country, advertising channel, campaign, and eToro mobile app, with aggregate funnel and revenue metrics for that segment.

Used by marketing analytics teams to evaluate mobile acquisition channel performance by geography and to attribute funnel conversions (registrations, FTDs, redeposits) to specific paid and organic media sources.

## 2. Source & Lineage

| Layer | Object |
|-------|--------|
| Origin | AppFlyer Platform (third-party mobile attribution SaaS) |
| Staging | `BI_DB_dbo.BI_DB_AppFlyer_Geo_Ext` (all-varchar, HEAP staging) |
| Writer SP | `BI_DB_dbo.SP_AppFlyer_Geo` (Katy F, 2016-06-15) |
| ETL pattern | Daily DELETE+INSERT (single-day replace by `EtoroDateID`) |
| OpsDB | Priority 0, SB_Daily, ProcessType SQL |

AppFlyer data enters via lake/Fivetran batch export → all-varchar staging (`_Ext` table) → SP applies numeric type coercion and column reordering → typed target table. No eToro production database is upstream; this is external marketing attribution data.

See [BI_DB_AppFlyer_Geo.lineage.md](BI_DB_AppFlyer_Geo.lineage.md) for full pipeline detail.

## 3. Grain

One row per **Date × Country × AgencyPMD × MediaSource × Campaign × EtoroAppID**.

- `Date` is the attribution date (when the install or event occurred, per AppFlyer)
- Multiple rows per date are expected (one per unique media source / campaign / country / app combination)
- `EtoroAppID` partitions rows by mobile platform (Android vs iOS)

## 4. Distribution & Clustering

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN |
| Clustering | CLUSTERED COLUMNSTORE INDEX on `Date ASC` |
| Date range (live) | 2022-10-29 → 2023-09-17 |
| Row count | 500 000+ |

## 5. Column Reference

### Dimension Columns

| Column | Type | Description |
|--------|------|-------------|
| `Date` | DATE | Attribution date — the calendar date for which AppFlyer aggregated this row's metrics. Primary time dimension. |
| `Country` | NVARCHAR(50) | ISO-2 country code of the device user (AppFlyer geo attribution). Raw AppFlyer value; no UK→GB standardization applied (unlike `BI_DB_AppFlyer_Reports`). 'UK' may appear instead of 'GB'. |
| `AgencyPMD` | NVARCHAR(500) | Media buying agency or PMD (Preferred Marketing Developer) identifier. 'None' for direct buys or organic. Identifies the intermediary agency that ran the campaign. |
| `MediaSource` | NVARCHAR(500) | Attribution source — the ad network or channel credited with the install or event. Common values: `Organic`, `bytedanceglobal_int` (TikTok), `googleadwords_int` (Google UAC), `Facebook Ads` (Meta), `smadex_int`, `Website`, and dozens of DSP/network identifiers. |
| `Campaign` | NVARCHAR(500) | Campaign name as reported by AppFlyer. Format varies by network (e.g., `AFFID_115812_App And SPC - Regs`). 'None' for organic. |
| `EtoroDateID` | INT | ETL partition key in YYYYMMDD integer format (matches `CONVERT(@dt_e, 112)` in SP). Used for daily delete+insert targeting. |
| `EtoroDate` | DATETIME | Datetime representation of the attribution date. Same calendar date as `Date` with time component 00:00:00. |
| `EtoroAppID` | NVARCHAR(100) | AppFlyer app identifier. Two values: `com_etoro_openbook` (Android) and `id674984916` (iOS). Partitions all rows by mobile OS. |
| `EtoroAppName` | NVARCHAR(100) | AppFlyer report type identifier — always `'Geo'`. AppFlyer export metadata constant; not a business dimension. |
| `EtoroReport` | NVARCHAR(100) | AppFlyer aggregation level identifier — always `'Date'`. AppFlyer export metadata constant indicating this is the date-level geo report. |

### Install & Engagement Metrics

| Column | Type | Description |
|--------|------|-------------|
| `Clicks` | BIGINT | Number of ad clicks attributed to this channel/campaign/country combination on this date. Zero for organic. |
| `Installs` | BIGINT | Number of app installs attributed to this channel/campaign/country combination. The primary acquisition metric. |
| `ConversionRate` | DECIMAL(10,4) | Install-to-click conversion rate as a decimal ratio (Installs / Clicks). Zero when Clicks = 0 (organic). Example: 6 installs / 2623 clicks = 0.0023. |
| `Sessions` | BIGINT | Total number of app sessions by users attributed to this segment on this date. |
| `LoyalUsers` | BIGINT | Count of users deemed "loyal" by AppFlyer (typically defined as users with more than 3 sessions after install). |
| `LoyalUsersInstalls` | DECIMAL(10,4) | Ratio of loyal users to total installs (LoyalUsers / Installs). Measures post-install engagement quality of the acquisition channel. |
| `TotalRevenue` | BIGINT | Total in-app revenue in USD attributed to this segment by AppFlyer. |
| `ARPU` | DECIMAL(10,4) | Average Revenue Per User = TotalRevenue / Installs, in USD. Measures monetization quality of installs from this source/campaign. |

### Funnel Event Metrics

Each funnel event (`ftd`, `loginlead`, `redeposit`, `registration`) has three sub-columns:

| Pattern | Description |
|---------|-------------|
| `{event}Uniqueusers` | Count of unique users who triggered this event in the segment. |
| `{event}Eventcounter` | Total event occurrences (can exceed unique users if the event fires multiple times per user). |
| `{event}SalesinUSD` | Revenue in USD attributed to this event by AppFlyer, for this segment. |

| Column Group | Business Meaning |
|-------------|-----------------|
| `ftd*` | **First Time Deposit** — user made their first deposit. The primary revenue conversion event. `ftdSalesinUSD` is the USD deposit amount attributed to this source. |
| `loginlead*` | **Login lead** — user completed registration and first login. A mid-funnel qualification step; typically `loginleadSalesinUSD = 0` as no monetary event occurs at this stage. |
| `redeposit*` | **Redeposit** — returning user made an additional deposit. Indicates retained monetization. |
| `registration*` | **Registration** — user completed the sign-up form. Top-of-funnel event; `registrationSalesinUSD` is typically 0. |

**Note:** All numeric/funnel columns are cleaned from varchar in the ETL SP — values of `'N/A'`, `'0.0000'`, or non-numeric strings are coerced to `0`.

## 6. ETL Notes

- **SP_AppFlyer_Geo** runs daily with parameter `@dt_e DATE`. It creates a temp table `#Geo_tmp`, loads from `BI_DB_AppFlyer_Geo_Ext` WHERE `EtoroDateID = @dt_int`, then deletes and reinserts the matching day in the target table.
- The `loginlead*` columns occupy different positions in `BI_DB_AppFlyer_Geo_Ext` vs the target table. The SP explicitly reorders them during the SELECT.
- `redepositSalesinUSD` had a commented-out CASE block in an earlier SP draft; the final version includes it (appears in INSERT list, populated as 0 when no redeposit revenue exists).
- No JOIN operations — purely a type-coercion ETL from varchar staging.
- `Country` receives no ISO standardization (unlike `BI_DB_AppFlyer_Reports` which maps UK→GB).

## 7. Usage Notes

- **Channel performance by geo**: Join to `BI_DB_AppFlyer_Reports` (user-level) on `EtoroDateID + EtoroAppID + MediaSource` for user-level detail behind these aggregates.
- **Platform split**: Filter `EtoroAppID = 'com_etoro_openbook'` for Android; `EtoroAppID = 'id674984916'` for iOS.
- **Organic baseline**: `MediaSource = 'Organic'` and `AgencyPMD = 'None'` / `Campaign = 'None'` — use as a baseline for organic acquisition quality.
- **ARPU as quality signal**: High `Installs` with low `ARPU` or low `LoyalUsersInstalls` indicates low-quality acquisition (installs without engagement). Used to optimize media mix.
- **No CID linkage**: This is aggregate geo-level data; there is no `CID` column. For user-level AppFlyer attribution, use `BI_DB_AppFlyer_Reports`.

## 8. Quality & Caveats

| Issue | Detail |
|-------|--------|
| Country code inconsistency | `Country = 'UK'` appears instead of `'GB'` (ISO standard). Unlike `BI_DB_AppFlyer_Reports`, no UK→GB standardization is applied in the ETL. Downstream queries should handle both. |
| Numeric coercion | All metrics originated as varchar and were coerced. Values of exactly `0` may represent true zeros OR cleaned invalid strings — check `Installs > 0` before computing ratios (ConversionRate, ARPU, LoyalUsersInstalls). |
| Date range | Live data starts 2022-10-29. Earlier historical data may not be loaded. |
| Sparse funnel columns | `loginleadSalesinUSD` is typically 0 (no monetary event at login stage). `Installs` can be 0 for click-only rows. Divide-by-zero guards required when computing ConversionRate or ARPU from this table. |
| EtoroAppName / EtoroReport | Always constant (`'Geo'`, `'Date'`). These are AppFlyer export metadata tags — not filterable business dimensions. |

<!-- APPSFLYER_PDF_APPENDIX_2026_06_10 -->

## AppsFlyer field reference (PDF cross-reference)

> Added 2026-06-10 by the one-shot AppsFlyer deployment.

**UC FQN**: `(Synapse-only - not migrated to UC)`

**Note**: AppsFlyer GEO aggregate at Country x AgencyPMD x MediaSource x Campaign x Date x EtoroAppID grain. Funnel + revenue rollups (Installs / Sessions / LoyalUsers / ftd / loginlead / redeposit / registration / TotalRevenue / ARPU). NOT one of the 86 raw fields - this is a separate aggregate report from AppsFlyer.

The authoritative AppsFlyer-vendor descriptions for every column live in the PDF cross-reference at `proposals/AppsFlyer_Fields.pdf`. The mapping covers every field used in the eToro pipeline against AppsFlyer's documented field name (e.g. `MediaSource <-> media_source`, `Partner <-> af_prt`, `SubParam1..5 <-> af_sub1..5`).

Deployed UC ALTER scripts grounded in the PDF:

| Object | UC ALTER file |
|---|---|
| Silver fact (1:1 with PDF) | `knowledge/UC_generated/de_output/Tables/de_output_appsflyer_silver_reports.alter.sql` |
| Gold mirror (this object's UC face if migrated) | `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AppFlyer_Reports.alter.sql` |
| CID bridge | `knowledge/UC_generated/bi_db/Tables/bronze_marketperformance_tracking_customer.alter.sql` |
| Permissioned view | `knowledge/UC_generated/bridgeclaw_permitted_data/Views/appflyer_reports.alter.sql` |

The five eToro custom fields (`DateID`, `Date`, `EtoroAppID`, `EtoroAppName`, `EtoroReport`) are not in the AppsFlyer schema - see "Custom eToro Fields (Not in AppsFlyer Documentation)" in the PDF.
