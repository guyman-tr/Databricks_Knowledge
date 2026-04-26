# BI_DB_dbo.BI_DB_DCM_Dashboard

> 6M-row daily media campaign performance dashboard combining Google Campaign Manager 360 (DCM) Fivetran data with internal back-office registration/FTD counts and first-action product breakdowns — three levels of detail (High Level, DCM Level, First Action) for Media/Content Partnerships/Media Performance/Media CPA affiliate channels, rolling 90-day backfill, refreshed daily via SP_DCM_Dashboard (author: Jan Iablunovskey, 2021-10-18).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_Fivetran_double_click_campaign_manager_media_campaign (DCM) + BI_DB_CIDFirstDates (reg/FTD) + BI_DB_First5Actions (product breakdown) via SP_DCM_Dashboard |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE last 90 days + INSERT via UNION of 3 LOD levels |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX([Date] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_DCM_Dashboard is a media campaign performance table that merges Google Campaign Manager 360 (formerly DoubleClick Campaign Manager / DCM) data with eToro's internal conversion tracking. The table contains 6M rows spanning August 2023 to April 2026, organized into three levels of detail (LOD):

1. **High Level** (27%): Aggregated DCM metrics merged with back-office registration and FTD counts. Grain: (Date, Country, AffiliateID). Campaign/Placement fields are NULL.
2. **DCM Level** (73%): Campaign and placement-level DCM detail. Grain: (Date, Country, AffiliateID, Campaign, Placement, Creative). FTD/Reg back-office counts are 0.
3. **First Action** (<1%): Product-type breakdown of FTDs (Stocks, CFDs, Crypto, Copy, SmartPortfolio). Grain: (Date, Country, AffiliateID). All metrics except product counts are 0.

The affiliate population is filtered to Media-related channels: active affiliates in Channel = 'Media', 'Content Partnerships', 'Media Performance', or 'Media CPA', plus affiliates whose DCM campaign names contain '_MP' (Media Performance).

AffiliateID is extracted from campaign names using complex reverse-parsing of the trailing numeric segment. DCM view-through and click-through conversions are split by activity type (FTD, Registration) and platform (Android, iOS, web).

The ETL uses a 90-day rolling window to capture late-arriving DCM conversion data (view-through conversions have a 7-day lookback).

---

## 2. Business Logic

### 2.1 Three-Level UNION Architecture

**What**: The INSERT is a UNION of three SELECTs, each producing a different LOD level.
**Columns Involved**: LOD, all metric columns
**Rules**:
- "High Level": FULL OUTER JOIN DCM + back-office data. Campaign/Placement/Creative = NULL. FTDs/Regs populated from BI_DB_CIDFirstDates.
- "DCM Level": DCM data only grouped by campaign/placement/creative. FTDs/Regs/FirstAction counts = 0.
- "First Action": Product breakdown only. All DCM metrics = 0. Stocks/CFDs/Crypto/Copy/SmartPortfolio/FirstActionNULL populated from BI_DB_First5Actions.

### 2.2 View-Through vs Click-Through Conversion Tracking

**What**: DCM conversions split by attribution type and platform.
**Columns Involved**: ViewFTD/ClickFTD, ViewAndroidFTD/ClickAndroidFTD, ViewIOSFTD/ClickIOSFTD, ViewRegistration/ClickRegistration, ViewAndroidRegistration/ClickAndroidRegistration, ViewIOSRegistration/ClickIOSRegistration
**Rules**:
- View-through: user saw the ad and later converted (without clicking)
- Click-through: user clicked the ad and converted
- Split by platform: base (web), Android, iOS
- Activity types from DCM: 'FTD', 'FTD_Android', 'FTD_IOS', 'Registration', 'Registration_Android', 'Registration_IOS'

### 2.3 AffiliateID Extraction from Campaign Names

**What**: Numeric AffiliateID extracted from the trailing segment of DCM campaign names.
**Columns Involved**: AffiliateID, Campaign
**Rules**:
- Uses REVERSE + PATINDEX + SUBSTRING to extract trailing numeric segment from campaign name
- Excludes campaigns with 'DV360' or 'BidManager' in the name
- UNION with Dim_Affiliate WHERE Channel IN ('Media', 'Content Partnerships', 'Media Performance', 'Media CPA')

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN
- **Clustered Index**: Date ASC — always filter by Date

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Campaign performance at high level | `WHERE LOD = 'High Level' AND Date >= @date` |
| Campaign drill-down with placements | `WHERE LOD = 'DCM Level' AND Campaign LIKE @pattern` |
| Product breakdown of FTDs | `WHERE LOD = 'First Action' AND Date >= @date` |
| Total conversions (view + click) | `SUM(ViewFTD + ClickFTD + ViewAndroidFTD + ClickAndroidFTD + ViewIOSFTD + ClickIOSFTD)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Affiliate | ON AffiliateID | Full affiliate details |
| DWH_dbo.Dim_Country | ON Country = Name | Full country details |

### 3.4 Gotchas

- **LOD column determines which metrics are populated** — never aggregate across LOD levels. FTDs/Regs in "High Level" and Stocks/CFDs/etc. in "First Action" are mutually exclusive
- **FTDs vs FTDs1, Regs vs Regs1**: FTDs and FTDs1 contain the same value at "High Level", both 0 at other levels. This is a legacy artifact from a calculation change (2021-11-16)
- **Campaign/CampaignId/Placement/PlacementId are NULL at "High Level" and "First Action"** — only populated for "DCM Level" rows
- **90-day rolling window** means data older than 90 days is permanent; recent data re-inserts daily
- **First Action columns** (Stocks, CFDs, Crypto, Copy, SmartPortfolio, FirstActionNULL) are 0 for non-"First Action" LOD levels
- **AffiliateID parsing** from campaign names may fail for non-standard naming — check for unexpected AffiliateID values
- **DCM data loaded via Fivetran** — ensure External_Fivetran table is populated before SP_DCM_Dashboard runs

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest — verified by source system owner |
| Tier 2 | SP code / ETL logic analysis | High — derived from version-controlled code |
| Tier 3 | Live data observation + schema inference | Medium — empirically verified but no code/wiki confirmation |
| Tier 4 | Inferred from naming / context | Lower — best-effort, needs reviewer validation |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard — canonical description for known ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Campaign reporting date. Range: 2023-08-27 to present, 961 distinct dates. Part of the natural grain. (Tier 2 — SP_DCM_Dashboard) |
| 2 | Country | varchar(100) | YES | Country name from Dim_Country, resolved via BI_DB_CountryDCM mapping for DCM data or directly from BI_DB_CIDFirstDates.Country for back-office data. (Tier 2 — SP_DCM_Dashboard) |
| 3 | AffiliateID | int | YES | Affiliate partner identifier. Extracted from DCM campaign names (trailing numeric segment) or from BI_DB_CIDFirstDates.SerialID. Filtered to Media/Content Partnerships/Media Performance/Media CPA channels. (Tier 2 — SP_DCM_Dashboard) |
| 4 | Impressions | bigint | YES | Total ad impressions from DCM. SUM across activities per group. 0 for First Action LOD. (Tier 2 — SP_DCM_Dashboard) |
| 5 | Clicks | int | YES | Total ad clicks from DCM. SUM across activities per group. 0 for First Action LOD. (Tier 2 — SP_DCM_Dashboard) |
| 6 | FTDs | int | YES | First-time deposit count from back-office (BI_DB_CIDFirstDates). High Level LOD only; 0 for DCM Level and First Action. (Tier 2 — SP_DCM_Dashboard) |
| 7 | Regs | int | YES | Registration count from back-office (BI_DB_CIDFirstDates). High Level LOD only; 0 for DCM Level and First Action. (Tier 2 — SP_DCM_Dashboard) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — Propagation) |
| 9 | Campaign | varchar(max) | YES | Full DCM campaign name from Fivetran. DCM Level LOD only; NULL for High Level and First Action. Contains affiliate ID, country code, and platform info. (Tier 2 — SP_DCM_Dashboard) |
| 10 | CampaignId | bigint | YES | DCM campaign numeric identifier from Fivetran. DCM Level LOD only; NULL for High Level and First Action. (Tier 2 — SP_DCM_Dashboard) |
| 11 | Placement | varchar(max) | YES | DCM ad placement name from Fivetran. DCM Level LOD only; NULL for High Level and First Action. (Tier 2 — SP_DCM_Dashboard) |
| 12 | PlacementId | int | YES | DCM placement numeric identifier from Fivetran. DCM Level LOD only; NULL for High Level and First Action. (Tier 2 — SP_DCM_Dashboard) |
| 13 | MediaCost | int | YES | Media advertising cost from DCM (media_cost). SUM per group. 0 for First Action LOD. (Tier 2 — SP_DCM_Dashboard) |
| 14 | ViewFTD | int | YES | View-through FTD conversions from DCM (activity='FTD', view_through_conversions). User saw ad and later deposited. (Tier 2 — SP_DCM_Dashboard) |
| 15 | ClickFTD | int | YES | Click-through FTD conversions from DCM (activity='FTD', click_through_conversions). User clicked ad and deposited. (Tier 2 — SP_DCM_Dashboard) |
| 16 | ViewAndroidFTD | int | YES | View-through FTD conversions from Android DCM tracking (activity='FTD_Android'). (Tier 2 — SP_DCM_Dashboard) |
| 17 | ClickAndroidFTD | int | YES | Click-through FTD conversions from Android DCM tracking (activity='FTD_Android'). (Tier 2 — SP_DCM_Dashboard) |
| 18 | ViewRegistration | int | YES | View-through registration conversions from DCM (activity='Registration'). (Tier 2 — SP_DCM_Dashboard) |
| 19 | ClickRegistration | int | YES | Click-through registration conversions from DCM (activity='Registration'). (Tier 2 — SP_DCM_Dashboard) |
| 20 | ViewAndroidRegistration | int | YES | View-through registration conversions from Android DCM tracking (activity='Registration_Android'). (Tier 2 — SP_DCM_Dashboard) |
| 21 | ClickAndroidRegistration | int | YES | Click-through registration conversions from Android DCM tracking (activity='Registration_Android'). (Tier 2 — SP_DCM_Dashboard) |
| 22 | LOD | varchar(100) | YES | Level of Detail indicator determining which metrics are populated. 'High Level' = aggregated DCM + back-office. 'DCM Level' = campaign/placement detail. 'First Action' = product breakdown. Never aggregate across LOD values. (Tier 2 — SP_DCM_Dashboard) |
| 23 | CampaignName | varchar(500) | YES | Short campaign name extracted from DCM campaign field (LEFT up to first underscore). DCM Level LOD only; NULL for others. (Tier 2 — SP_DCM_Dashboard) |
| 24 | FTDs1 | int | YES | Duplicate of FTDs — legacy artifact from 2021-11-16 calculation change. Same value as FTDs at High Level; 0 otherwise. (Tier 2 — SP_DCM_Dashboard) |
| 25 | Regs1 | int | YES | Duplicate of Regs — legacy artifact from 2021-11-16 calculation change. Same value as Regs at High Level; 0 otherwise. (Tier 2 — SP_DCM_Dashboard) |
| 26 | Stocks | int | YES | Count of FTDs whose first action was Stocks/ETFs. First Action LOD only; 0 otherwise. From BI_DB_First5Actions.FirstAction='Stocks/ETFs'. (Tier 2 — SP_DCM_Dashboard) |
| 27 | CFDs | int | YES | Count of FTDs whose first action was FX/Commodities/Indices (labeled CFDs). First Action LOD only; 0 otherwise. (Tier 2 — SP_DCM_Dashboard) |
| 28 | Crypto | int | YES | Count of FTDs whose first action was Crypto. First Action LOD only; 0 otherwise. (Tier 2 — SP_DCM_Dashboard) |
| 29 | Copy | int | YES | Count of FTDs whose first action was Copy (CopyTrader). First Action LOD only; 0 otherwise. (Tier 2 — SP_DCM_Dashboard) |
| 30 | SmartPortfolio | int | YES | Count of FTDs whose first action was Copy Fund (Smart Portfolio). First Action LOD only; 0 otherwise. (Tier 2 — SP_DCM_Dashboard) |
| 31 | FirstActionNULL | int | YES | Count of FTDs with no recorded first action. First Action LOD only; 0 otherwise. (Tier 2 — SP_DCM_Dashboard) |
| 32 | ViewIOSFTD | int | YES | View-through FTD conversions from iOS DCM tracking (activity='FTD_IOS'). (Tier 2 — SP_DCM_Dashboard) |
| 33 | ClickIOSFTD | int | YES | Click-through FTD conversions from iOS DCM tracking (activity='FTD_IOS'). (Tier 2 — SP_DCM_Dashboard) |
| 34 | ViewIOSRegistration | int | YES | View-through registration conversions from iOS DCM tracking (activity='Registration_IOS'). (Tier 2 — SP_DCM_Dashboard) |
| 35 | ClickIOSRegistration | int | YES | Click-through registration conversions from iOS DCM tracking (activity='Registration_IOS'). (Tier 2 — SP_DCM_Dashboard) |
| 36 | Creative | varchar(500) | YES | Ad creative name/identifier from DCM. DCM Level LOD only; NULL for others. (Tier 2 — SP_DCM_Dashboard) |
| 37 | NewMarketingRegion | varchar(100) | YES | Marketing region from Dim_Country.MarketingRegionManualName. Named "New" to distinguish from legacy region mapping. (Tier 2 — SP_DCM_Dashboard) |
| 38 | Contact | nvarchar(1000) | YES | Affiliate contact person from Dim_Affiliate.Contact. (Tier 2 — SP_DCM_Dashboard) |
| 39 | Channel | nvarchar(100) | YES | Affiliate channel from Dim_Affiliate.Channel. Expected values: 'Media', 'Content Partnerships', 'Media Performance', 'Media CPA'. (Tier 2 — SP_DCM_Dashboard) |
| 40 | SubChannel | nvarchar(100) | YES | Affiliate sub-channel from Dim_Affiliate.SubChannel. Finer granularity within Channel. (Tier 2 — SP_DCM_Dashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Impressions/Clicks/MediaCost | DCM Fivetran | impressions/clicks/media_cost | SUM per group |
| View*/Click* conversion cols | DCM Fivetran | view_through_conversions/click_through_conversions | SUM CASE by activity type |
| FTDs/Regs | BI_DB_CIDFirstDates | COUNT(*) | Internal count by date/country/affiliate |
| Stocks/CFDs/Crypto/Copy/etc | BI_DB_First5Actions | COUNT CASE by FirstAction | Product breakdown |
| Channel/SubChannel/Contact | DWH_dbo.Dim_Affiliate | Direct | Passthrough |

### 5.2 ETL Pipeline

```
External_Fivetran_double_click_campaign_manager_media_campaign (DCM data via Fivetran)
  + BI_DB_CountryDCM (country mapping)
  + DWH_dbo.Dim_Country (region)
  + DWH_dbo.Dim_Affiliate (channel, contact, AffID validation)
  |-- AffiliateID reverse-parsed from campaign name ---|
  |-- SUM CASE by activity type for View*/Click* ---|
  v
#DCM (temp: DCM metrics by date/country/campaign/placement)
  |
  |-- "High Level": FULL OUTER JOIN with #DB_RegFTD1 ---|
  |-- "DCM Level":  DCM data with campaign/placement detail ---|
  |-- "First Action": Product breakdown from #FirstAction ---|
  v
UNION of 3 levels
  |-- DELETE last 90 days + INSERT ---|
  v
BI_DB_dbo.BI_DB_DCM_Dashboard (6M rows, ROUND_ROBIN, CI(Date))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate dimension — channel, contact, sub-channel |
| Country | DWH_dbo.Dim_Country | Country dimension — marketing region |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none found in SSDT) | — | Media campaign performance dashboards |

---

## 7. Sample Queries

### 7.1 High-Level Campaign Performance by Country

```sql
SELECT Country, SUM(Impressions) AS impressions, SUM(Clicks) AS clicks,
       SUM(FTDs) AS ftds, SUM(Regs) AS regs,
       SUM(MediaCost) AS cost
FROM [BI_DB_dbo].[BI_DB_DCM_Dashboard]
WHERE LOD = 'High Level' AND Date >= '2026-04-01'
GROUP BY Country
ORDER BY SUM(FTDs) DESC;
```

### 7.2 First Action Product Breakdown

```sql
SELECT Date, Country,
       SUM(Stocks) AS stocks, SUM(CFDs) AS cfds,
       SUM(Crypto) AS crypto, SUM(Copy) AS copy,
       SUM(SmartPortfolio) AS smart_portfolio
FROM [BI_DB_dbo].[BI_DB_DCM_Dashboard]
WHERE LOD = 'First Action' AND Date >= '2026-04-01'
GROUP BY Date, Country
ORDER BY Date;
```

### 7.3 DCM View vs Click Attribution

```sql
SELECT Date,
       SUM(ViewFTD + ViewAndroidFTD + ViewIOSFTD) AS view_ftd,
       SUM(ClickFTD + ClickAndroidFTD + ClickIOSFTD) AS click_ftd,
       SUM(ViewRegistration + ViewAndroidRegistration + ViewIOSRegistration) AS view_reg,
       SUM(ClickRegistration + ClickAndroidRegistration + ClickIOSRegistration) AS click_reg
FROM [BI_DB_dbo].[BI_DB_DCM_Dashboard]
WHERE LOD = 'DCM Level' AND Date >= '2026-04-01'
GROUP BY Date
ORDER BY Date;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 0 T1, 39 T2, 0 T3, 0 T4, 1 T5 | Elements: 40/40, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_DCM_Dashboard | Type: Table | Production Source: DCM Fivetran + BI_DB_CIDFirstDates + BI_DB_First5Actions via SP_DCM_Dashboard*
