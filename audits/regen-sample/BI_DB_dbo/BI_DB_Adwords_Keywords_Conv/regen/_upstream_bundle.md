# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_Adwords_Keywords_Conv`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_Adwords_Keywords_Conv.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_Adwords_Keywords_Conv]
(
	[date] [date] NOT NULL,
	[DateID] [int] NOT NULL,
	[customer_id] [bigint] NOT NULL,
	[status] [nvarchar](256) NULL,
	[device] [nvarchar](256) NULL,
	[criteria] [nvarchar](256) NULL,
	[external_customer_id] [bigint] NULL,
	[account_currency_code] [nvarchar](256) NULL,
	[campaign_id] [bigint] NULL,
	[id] [bigint] NULL,
	[ad_group_id] [bigint] NULL,
	[week] [nvarchar](256) NULL,
	[Registration] [int] NULL,
	[V2] [int] NULL,
	[FTD] [int] NULL,
	[MultipleDeposit] [int] NULL,
	[FTDA] [int] NULL,
	[MTDA] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[android_reg] [float] NULL,
	[android_v2] [float] NULL,
	[android_ftd] [float] NULL,
	[ios_reg] [float] NULL,
	[ios_v2] [float] NULL,
	[ios_ftd] [float] NULL,
	[LTV_Count] [int] NULL,
	[LTV_Value] [int] NULL,
	[KeywordMatchType] [nvarchar](50) NULL,
	[Regs_IOS2] [int] NULL,
	[V2_IOS2] [int] NULL,
	[FTD_IOS2] [int] NULL,
	[Regs_Android2] [int] NULL,
	[V2_android2] [int] NULL,
	[FTD_Android2] [int] NULL,
	[OpenTrade_And] [int] NULL,
	[OpenTrade_iOS] [int] NULL,
	[OpenTrade_iOS2] [int] NULL,
	[OpenTrade] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[DateID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 9 upstream wiki(s). Read EACH one in full.


### Upstream `BI_DB_dbo.BI_DB_Adwords_Geo_Pref` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Geo_Pref`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Geo_Pref.md`

# BI_DB_dbo.BI_DB_Adwords_Geo_Pref

> **STALE DATA — last refreshed 2023-09-18.** 239,828-row Google Ads geographic-level performance metrics table. Contains impressions, clicks, cost (in micros), video views, interactions, and total conversions by country, campaign, ad group, device, and date. Performance counterpart to BI_DB_Adwords_Geo_Conv (which has the funnel breakdown). Part of SP_Adwords_Pref_Conv cluster (Table #1 of 12). Date range: 2023-06-19 to 2023-09-17. Devices: DESKTOP, MOBILE, TABLET, CONNECTED_TV, OTHER.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_geo_perf_new_api_perf_geo_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 239,828 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Geo_Pref` stores **Google Ads geographic-level performance metrics** — the "how much was spent and what engagement was achieved" counterpart to `BI_DB_Adwords_Geo_Conv` (which tracks "what conversions resulted"). Together they provide a complete geographic view of Google Ads campaign effectiveness.

Each row represents one combination of date, device, campaign, ad group, country, and Google Ads account. Columns are mostly **passthrough from Fivetran** (no conversion pivot), containing standard Google Ads performance metrics: impressions, clicks, cost (in micros), video views, interactions, and total conversions.

This is Table #1 in SP_Adwords_Pref_Conv (the first table processed). The SP denormalizes campaign/ad group names and statuses directly into the performance row, making JOINs to dictionary tables optional for basic analysis.

**DATA IS STALE**: Last updated 2023-09-18. Largest table in this batch by row count (240K).

---

## 2. Business Logic

### 2.1 Passthrough Performance Metrics

**What**: Standard Google Ads performance metrics passed through from Fivetran with minimal transformation.
**Columns Involved**: impressions, clicks, cost, video_views, interactions, Conversions
**Rules**:
- All metrics are direct passthrough from Fivetran source
- cost is renamed from cost_micros (value in Google Ads micros — divide by 1,000,000 for actual currency)
- No aggregation or pivot — grain matches the Fivetran source

### 2.2 Denormalized Campaign/Ad Group Metadata

**What**: Campaign and ad group names/statuses embedded directly in the performance row.
**Columns Involved**: campaign_name, campaign_status, ad_group_name, ad_group_status
**Rules**:
- Passthrough from Fivetran source, avoiding need for dictionary JOINs
- Status values from Fivetran (may differ in casing from dictionary tables)

### 2.3 Geographic Grain

**What**: Country-level geographic attribution.
**Columns Involved**: country_criteria_id, region_criteria_id
**Rules**:
- country_criteria_id maps to Google Ads geocriteria codes
- region_criteria_id is hardcoded to NULL (removed 2021-08-23)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID ASC. With 240K rows, scans are fast but date-range predicates benefit from the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Campaign spend by country | SUM(cost) / 1000000.0 GROUP BY country_criteria_id |
| Click-through rate by device | SUM(clicks) * 1.0 / NULLIF(SUM(impressions), 0) GROUP BY device |
| Cost per conversion by country | SUM(cost) / NULLIF(SUM(Conversions), 0) GROUP BY country_criteria_id |
| Top campaigns by impressions | GROUP BY campaign_name ORDER BY SUM(impressions) DESC |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Geo_Conv | date, customer_id, device, campaign_id, ad_group_id, country_criteria_id | Combine performance + funnel conversion metrics |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Canonical campaign metadata (bidding strategy, budget) |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Canonical ad group metadata |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-09-17.
- **cost is in micros** — divide by 1,000,000 to get actual currency amount. The column is renamed from cost_micros in Fivetran but the value is NOT converted.
- **region_criteria_id is always NULL** — column retained in DDL but unused.
- **external_customer_id = customer_id** — redundant duplicate.
- **Campaign/ad group names are denormalized** — may differ from dictionary table values if they were renamed between the performance report and the dictionary snapshot.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NO | Google Ads report date. Calendar day for performance metrics. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer. Computed by DateToDateID(date). Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer account ID. Identifies the Google Ads account. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | impressions | bigint | YES | Number of times ads were shown. Standard Google Ads metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | ad_group_status | nvarchar(256) | YES | Ad group operational status. Denormalized from Fivetran source (e.g., ENABLED, PAUSED). (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | campaign_status | nvarchar(256) | YES | Campaign operational status. Denormalized from Fivetran source (e.g., ENABLED, PAUSED). (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET, CONNECTED_TV, OTHER. Part of row grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | campaign_name | nvarchar(256) | YES | Google Ads campaign name. Denormalized from Fivetran source. Encodes region, product, channel metadata. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | ad_group_name | nvarchar(256) | YES | Google Ads ad group name. Denormalized from Fivetran source. Encodes keyword theme and targeting. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | video_views | bigint | YES | Number of video ad views. Standard Google Ads video metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | cost | float | YES | Advertising cost in Google Ads micros. Renamed from Fivetran cost_micros. Divide by 1,000,000 for actual currency (e.g., 270485.0 micros = $0.27 USD). (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. Set to customer_id in SP. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | region_criteria_id | int | YES | Google Ads region criteria ID. Hardcoded to NULL since 2021-08-23. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | interactions | bigint | YES | Total interactions (clicks, video views, calls). Standard Google Ads engagement metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | clicks | bigint | YES | Number of ad clicks. Standard Google Ads metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | country_criteria_id | int | YES | Google Ads geographic country criteria ID. Maps to geocriteria codes (e.g., 2840=US, 2826=UK, 2100=Italy). Mapped from Fivetran country_criterion_id. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | week | nvarchar(256) | YES | ISO week start date from Fivetran (e.g., '2023-09-11'). Used for weekly aggregation. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) |
| 21 | Conversions | bigint | YES | Total conversions (all types combined). Standard Google Ads metric. Passthrough from Fivetran. Unlike Geo_Conv which breaks down by funnel stage, this is the aggregate total. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Most columns | Fivetran Google Ads | Same names | Passthrough |
| DateID | Fivetran Google Ads | date | DateToDateID() |
| cost | Fivetran Google Ads | cost_micros | Rename (value unchanged — still in micros) |
| external_customer_id | Fivetran Google Ads | customer_id | Duplicate |
| region_criteria_id | N/A | N/A | Hardcoded NULL |
| country_criteria_id | Fivetran Google Ads | country_criterion_id | Rename |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_geo_perf_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_geo_perf_new_api_perf_geo_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #1, P99) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT passthrough
  v
BI_DB_dbo.BI_DB_Adwords_Geo_Pref (239,828 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata lookup |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata lookup |

### 6.2 Referenced By (other objects point to this)

No known consumers. Join with Geo_Conv for complete geographic analysis.

---

## 7. Sample Queries

### 7.1 Campaign Cost and CTR by Country

```sql
SELECT country_criteria_id,
       SUM(cost) / 1000000.0 AS cost_usd,
       SUM(clicks) AS total_clicks,
       SUM(impressions) AS total_impressions,
       CAST(SUM(clicks) AS FLOAT) / NULLIF(SUM(impressions), 0) AS ctr
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Pref]
WHERE DateID BETWEEN 20230801 AND 20230901
GROUP BY country_criteria_id
ORDER BY cost_usd DESC
```

### 7.2 Device Performance Breakdown

```sql
SELECT device,
       SUM(impressions) AS impressions, SUM(clicks) AS clicks,
       SUM(cost) / 1000000.0 AS cost_usd, SUM(Conversions) AS conversions
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Pref]
GROUP BY device
ORDER BY cost_usd DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 20 T2, 0 T3, 0 T4, 1 T5 | Elements: 21/21, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Geo_Pref | Type: Table | Production Source: Fivetran Google Ads*


### Upstream `BI_DB_dbo.BI_DB_Adwords_Ad_Pref` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Ad_Pref`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Ad_Pref.md`

# BI_DB_dbo.BI_DB_Adwords_Ad_Pref

> **STALE DATA — last refreshed ~2023-08.** 1.64M-row Google Ads ad-level performance table tracking impressions, clicks, cost, video views, and video quartile completion rates per ad creative. Contains ad copy text (headlines, descriptions) including responsive search ad JSON. Covers Sept 2022 to Sept 2023 across multiple Google Ads accounts. Part of SP_Adwords_Pref_Conv Fivetran cluster (Table #2 of 12).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_ad_perf_new_api_perf_ad_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran ~2023-08. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 1,635,224 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Ad_Pref` stores **Google Ads ad-level performance metrics** — impressions, clicks, cost, video views, and engagement data at the individual ad creative level. This is the performance/spend counterpart to `BI_DB_Adwords_Ad_Conv` (conversion tracking). Together they enable cost-per-conversion analysis at the ad creative level.

Each row represents one ad's performance for a given date, device, and Google Ads account. The table includes ad creative text (headlines, descriptions) for both expanded text ads and responsive search ads (RSA). RSA data is stored as JSON arrays in `responsive_search_ad_headlines` and `responsive_search_ad_descriptions`, containing per-asset performance labels and approval status.

The SP sources from Fivetran's Google Ads ad performance report (`adwords_ad_perf` schema), with column renames from Google Ads API naming to more readable names (e.g., `expanded_text_ad_description` → `description`, `policy_summary_approval_status` → `combined_approval_status`, `cost_micros` → `cost`).

**DATA IS STALE**: Date range 2022-09-01 to 2023-09-17. SP has not run since Synapse migration (2023-09-12).

---

## 2. Business Logic

### 2.1 Ad Performance Metrics

**What**: Standard Google Ads performance metrics at the ad creative level.
**Columns Involved**: impressions, clicks, cost, video_views, interactions, Conversions
**Rules**:
- cost = cost_micros from Google (in micros, divide by 1,000,000 for currency units)
- interactions = clicks + video views + other engagement actions
- Conversions = total conversion count (not pivoted by funnel stage — use Ad_Conv for that)

### 2.2 Video Completion Tracking

**What**: Video ad completion rates at 25/50/75/100% quartiles.
**Columns Involved**: video_quartile_25_rate through video_quartile_100_rate
**Rules**:
- Rates as float (0.0 to 1.0)
- Only populated for video ad types (0.0 for non-video ads)
- Sourced from video_quartile_p_*_rate in Fivetran (note 'p' prefix in source)

### 2.3 Responsive Search Ad Content

**What**: RSA headline and description variants stored as JSON.
**Columns Involved**: responsive_search_ad_headlines, responsive_search_ad_descriptions, ad_name
**Rules**:
- JSON arrays with per-asset objects containing: text, assetPerformanceLabel (GOOD/LEARNING/PENDING), policySummaryInfo (approval status)
- Can contain Unicode escapes (\u0026 = &, \u0027 = ')
- Only populated for RESPONSIVE_SEARCH_AD ad_type

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CI(DateID). Filter on DateID for efficient range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily ad spend | `SELECT date, SUM(cost)/1000000 AS spend FROM ... GROUP BY date` |
| Top performing ads | `ORDER BY clicks DESC` or `ORDER BY Conversions DESC` |
| Video ad performance | `WHERE ad_type LIKE '%VIDEO%' AND video_views > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_Adwords_Ad_Conv | date, customer_id, id, ad_group_id, device | Join spend/impressions with conversion data for CPA analysis |
| BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign name lookup |
| BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group name lookup |

### 3.4 Gotchas

- **DATA IS STALE**: Last update ~August 2023. Do not use for current analysis.
- **cost is in micros**: Divide by 1,000,000 to get actual currency amount.
- **RSA JSON columns**: `responsive_search_ad_headlines` and `responsive_search_ad_descriptions` are nvarchar(max) containing JSON. Parse with OPENJSON for structured analysis.
- **external_customer_id = customer_id**: Always the same value.
- **Column renames from Fivetran**: description ← expanded_text_ad_description, headline ← expanded_text_ad_headline_part_3 (not headline_part_1 — potential SP mapping issue).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NO | Google Ads reporting date. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Integer date key in YYYYMMDD format. Computed by DateToDateID(date). Clustered index. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer/account ID. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | description | nvarchar(256) | YES | Ad description text. Mapped from expanded_text_ad_description in Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | ad_type | nvarchar(256) | YES | Google Ads ad type: RESPONSIVE_SEARCH_AD, EXPANDED_TEXT_AD, VIDEO_AD, etc. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | video_views | bigint | YES | Total video views for video ad types. 0 for non-video ads. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | cost | float | YES | Ad spend in micros (divide by 1,000,000 for currency units). Mapped from cost_micros in Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | accent_color | nvarchar(256) | YES | Legacy responsive display ad accent color. Mapped from legacy_responsive_display_ad_accent_color. Rarely populated. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | description_2 | nvarchar(256) | YES | Second ad description line. Mapped from expanded_text_ad_description_2 in Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | description_1 | nvarchar(256) | YES | First ad description line. Mapped from expanded_text_ad_description in Fivetran (same source as 'description' column). (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | headline_part_1 | nvarchar(256) | YES | First headline component. Mapped from expanded_text_ad_headline_part_1 in Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | campaign_id | bigint | YES | Google Ads campaign ID. FK to Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | headline_part_2 | nvarchar(256) | YES | Second headline component. Mapped from expanded_text_ad_headline_part_2 in Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | headline | nvarchar(256) | YES | Third headline component. Note: mapped from expanded_text_ad_headline_part_3 in Fivetran (not main headline). (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | combined_approval_status | nvarchar(256) | YES | Ad policy approval status. Mapped from policy_summary_approval_status. Values: APPROVED, DISAPPROVED, etc. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | status | nvarchar(256) | YES | Ad delivery status: ENABLED, PAUSED, REMOVED. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | impressions | bigint | YES | Number of times the ad was shown. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | device | nvarchar(256) | YES | Device type: DESKTOP, MOBILE, TABLET. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | creative_final_urls | nvarchar(256) | YES | Landing page URLs for the ad. JSON array format. Mapped from ad_final_urls. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | labels | nvarchar(256) | YES | Google Ads labels applied to the ad. JSON array of label resource names. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | external_customer_id | bigint | YES | Duplicate of customer_id. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | expanded_text_ad_headline_part_3 | nvarchar(256) | YES | Third headline component for expanded text ads. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | interactions | bigint | YES | Total interactions (clicks + video views + other engagements). (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | id | bigint | YES | Google Ads ad ID (renamed from ad_id). Unique creative identifier. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | ad_group_id | bigint | YES | Google Ads ad group ID. FK to Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | clicks | bigint | YES | Number of clicks on the ad. (Tier 2 — SP_Adwords_Pref_Conv) |
| 27 | expanded_text_ad_description_2 | nvarchar(256) | YES | Second description for expanded text ads. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 28 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at SP execution time. (Tier 5 — SP_Adwords_Pref_Conv) |
| 29 | Conversions | bigint | YES | Total conversion count across all conversion actions. Not funnel-pivoted (use Ad_Conv for funnel breakdown). (Tier 2 — SP_Adwords_Pref_Conv) |
| 30 | video_quartile_25_rate | float | YES | Video 25% completion rate (0.0-1.0). 0 for non-video ads. Mapped from video_quartile_p_25_rate. (Tier 2 — SP_Adwords_Pref_Conv) |
| 31 | video_quartile_50_rate | float | YES | Video 50% completion rate. (Tier 2 — SP_Adwords_Pref_Conv) |
| 32 | video_quartile_75_rate | float | YES | Video 75% completion rate. (Tier 2 — SP_Adwords_Pref_Conv) |
| 33 | video_quartile_100_rate | float | YES | Video 100% completion rate (full view). (Tier 2 — SP_Adwords_Pref_Conv) |
| 34 | ad_name | nvarchar(max) | YES | Human-readable ad name (Google Ads UI label). Added May 2022 by Jan. (Tier 2 — SP_Adwords_Pref_Conv) |
| 35 | responsive_search_ad_headlines | nvarchar(max) | YES | JSON array of RSA headline assets with text, performance label, and approval status. Only populated for RESPONSIVE_SEARCH_AD type. (Tier 2 — SP_Adwords_Pref_Conv) |
| 36 | responsive_search_ad_descriptions | nvarchar(max) | YES | JSON array of RSA description assets with text, pinned field position, performance label, and approval status. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| All columns | Google Ads API via Fivetran | adwords_ad_perf schema | Passthrough with column renames |
| cost | Fivetran | cost_micros | Rename (still in micros) |
| DateID | date | date | DateToDateID() function |

### 5.2 ETL Pipeline

```
Google Ads API (ad-level performance report)
  |-- Fivetran connector (adwords_ad_perf schema) ---|
  v
External_Bronze_Fivetran_adwords_ad_perf_new_api_perf_ad_performance_report (Parquet/Bronze)
  |-- SP_Adwords_Pref_Conv @date (Table #2) ---|
  |   DELETE old + INSERT (90-day window)
  |   Column renames from Google API names
  v
BI_DB_dbo.BI_DB_Adwords_Ad_Pref (1.64M rows — STALE since ~2023-08)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | Campaign name/config |
| ad_group_id | BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | Ad group name |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in SSDT.

---

## 7. Sample Queries

### 7.1 Top 20 Ads by Click Volume

```sql
SELECT TOP 20 id AS ad_id, campaign_id, ad_type, SUM(clicks) AS total_clicks, SUM(cost)/1000000.0 AS total_spend
FROM [BI_DB_dbo].[BI_DB_Adwords_Ad_Pref]
GROUP BY id, campaign_id, ad_type
ORDER BY total_clicks DESC
```

### 7.2 RSA Asset Performance Analysis

```sql
SELECT id, ad_name, responsive_search_ad_headlines
FROM [BI_DB_dbo].[BI_DB_Adwords_Ad_Pref]
WHERE ad_type = 'RESPONSIVE_SEARCH_AD'
  AND responsive_search_ad_headlines IS NOT NULL
  AND DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_Adwords_Ad_Pref])
```

---

## 8. Atlassian Knowledge Sources

No specific sources found. SP authored by Amir G (2021), with video quartile columns added by Chen (2021-11) and RSA columns by Jan Iablunovskey (2022-05).

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 35 T2, 0 T3, 0 T4, 1 T5 | Elements: 36/36, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Ad_Pref | Type: Table | Production Source: Fivetran Google Ads (ad performance report)*


### Upstream `BI_DB_dbo.BI_DB_Adwords_Keywords_Pref` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Keywords_Pref`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Keywords_Pref.md`

# BI_DB_dbo.BI_DB_Adwords_Keywords_Pref

> **STALE DATA — last refreshed 2023-09-18.** 223,519-row Google Ads keyword-level performance metrics table. Contains impressions, clicks, cost (in micros), quality score, video views, interactions, conversions, keyword match type, and search impression share metrics by keyword, device, campaign, and date. Performance counterpart to BI_DB_Adwords_Keywords_Conv. Part of SP_Adwords_Pref_Conv cluster (Table #3 of 12). Date range: 2023-06-19 to 2023-09-17. Keywords: multi-language search terms ('comprar acciones', 'etoro', 'crypto trading').

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 223,519 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Keywords_Pref` stores **Google Ads keyword-level performance metrics** — the "how much was spent and what engagement was achieved" counterpart to `BI_DB_Adwords_Keywords_Conv` (which tracks funnel conversions). Each row represents one keyword's performance metrics for a given date, device, campaign, ad group, and Google Ads account.

Columns are mostly **passthrough from Fivetran** with no conversion pivot, containing: impressions, clicks, cost (in micros), quality score (1-10), video views, interactions, total conversions, keyword match type, and search impression share metrics for competitive analysis. The keyword text is in the `criteria` column and includes multi-language search terms across all eToro markets.

This is Table #3 in SP_Adwords_Pref_Conv. The large row count (224K) versus Keywords_Conv (3.5K) reflects that many keyword impressions never generate tracked conversions — performance data exists for all active keywords regardless of conversion.

**DATA IS STALE**: Last updated 2023-09-18.

---

## 2. Business Logic

### 2.1 Passthrough Performance Metrics

**What**: Standard Google Ads keyword performance metrics passed through from Fivetran.
**Columns Involved**: impressions, clicks, cost, video_views, interactions, Conversions
**Rules**:
- All direct passthrough from Fivetran source
- cost renamed from cost_micros (divide by 1,000,000 for currency)
- No aggregation — grain matches Fivetran source

### 2.2 Quality Score

**What**: Google Ads quality score — a 1-10 rating of keyword/ad relevance.
**Columns Involved**: quality_score
**Rules**:
- Renamed from quality_info_quality_score in Fivetran
- 0 typically indicates insufficient data for scoring
- Higher scores correlate with lower cost-per-click and better ad positions

### 2.3 Search Impression Share Metrics

**What**: Competitive position metrics showing share of available search impressions.
**Columns Involved**: search_impression_share, search_budget_lost_top_impression_share, search_rank_lost_impression_share
**Rules**:
- search_impression_share = percentage of eligible impressions received
- search_budget_lost_top_impression_share = top-of-page impressions lost due to budget
- search_rank_lost_impression_share = impressions lost due to ad rank
- Stored as nvarchar (percentage strings from Fivetran), value "0" means no loss

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID ASC. 224K rows — moderate size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| CPC by keyword | SUM(cost) / NULLIF(SUM(clicks), 0) / 1000000.0 GROUP BY criteria |
| Keywords with high quality score | WHERE quality_score >= 7 |
| Search impression share gaps | WHERE search_rank_lost_impression_share > '0' |
| Cost per conversion by match type | SUM(cost) / NULLIF(SUM(Conversions), 0) GROUP BY KeywordMatchType |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Keywords_Conv | date, customer_id, device, criteria, campaign_id, ad_group_id, week, KeywordMatchType | Combine performance + funnel conversion metrics |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign metadata |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group metadata |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-09-17.
- **cost is in micros** — divide by 1,000,000 for actual currency.
- **id column is always NULL** — in DDL but SP skips it.
- **external_customer_id = customer_id** — redundant.
- **search_*_share columns are nvarchar** — percentages stored as strings, not numbers. Cast before math.
- **quality_score = 0** means "not enough data" not "worst quality."

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 4 | Inferred ��� column not populated by SP | DDL only |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NO | Google Ads report date. Calendar day for performance metrics. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer. Computed by DateToDateID(date). Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer account ID. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | status | nvarchar(256) | YES | Keyword criterion status. Mapped from Fivetran ad_group_criterion_status. ENABLED=active. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | impressions | bigint | YES | Number of times ads were shown for this keyword. Standard Google Ads metric. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | quality_score | int | YES | Google Ads keyword quality score (1-10). Mapped from Fivetran quality_info_quality_score. 0=insufficient data. Higher=better ad position and lower CPC. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET. Part of row grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | criteria | nvarchar(256) | YES | Search keyword text. Mapped from Fivetran keyword_text. Multi-language terms (e.g., 'comprar acciones', 'etoro', 'investir en bourse'). (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | video_views | bigint | YES | Video ad views for video-enabled keywords. Standard Google Ads metric. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | cost | float | YES | Advertising cost in Google Ads micros. Renamed from cost_micros. Divide by 1,000,000 for currency (e.g., 2200000 = $2.20). (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | search_budget_lost_top_impression_share | nvarchar(256) | YES | Percentage of top-of-page search impressions lost due to budget constraints. Stored as string. '0'=no loss. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | account_currency_code | nvarchar(256) | YES | Google Ads account currency code. Mapped from Fivetran customer_currency_code. Typically 'USD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | interactions | bigint | YES | Total interactions (clicks + video views + calls). Standard Google Ads engagement metric. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | search_impression_share | nvarchar(256) | YES | Percentage of eligible search impressions received. Stored as string. Indicates competitive visibility. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | id | bigint | YES | Keyword/criterion ID placeholder. NOT populated — SP comments out this column. Always NULL. (Tier 4 — inferred from DDL) |
| 18 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | clicks | bigint | YES | Number of ad clicks for this keyword. Standard Google Ads metric. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | search_rank_lost_impression_share | nvarchar(256) | YES | Percentage of search impressions lost due to ad rank (quality + bid). Stored as string. '0'=no loss. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | week | nvarchar(256) | YES | ISO week start date from Fivetran (e.g., '2023-09-11'). Part of row grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted (GETDATE()). (Tier 5 — ETL infrastructure) |
| 23 | Conversions | bigint | YES | Total conversions (all types combined). Standard Google Ads metric. Unlike Keywords_Conv which breaks by funnel stage. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | KeywordMatchType | nvarchar(256) | YES | Google Ads keyword match type. BROAD, EXACT, PHRASE. Mapped from keyword_match_type. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Most columns | Fivetran Google Ads | Various (renamed) | Passthrough/Rename |
| DateID | Fivetran Google Ads | date | DateToDateID() |
| cost | Fivetran Google Ads | cost_micros | Rename |
| quality_score | Fivetran Google Ads | quality_info_quality_score | Rename |
| criteria | Fivetran Google Ads | keyword_text | Rename |
| status | Fivetran Google Ads | ad_group_criterion_status | Rename |
| account_currency_code | Fivetran Google Ads | customer_currency_code | Rename |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_keywords_perf_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #3, P99) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT passthrough
  v
BI_DB_dbo.BI_DB_Adwords_Keywords_Pref (223,519 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata |

### 6.2 Referenced By (other objects point to this)

No known consumers. Paired with Keywords_Conv for complete keyword analysis.

---

## 7. Sample Queries

### 7.1 Keyword Cost-Per-Click Analysis

```sql
SELECT criteria AS keyword, KeywordMatchType, quality_score,
       SUM(clicks) AS clicks, SUM(cost) / NULLIF(SUM(clicks), 0) / 1000000.0 AS cpc_usd
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Pref]
WHERE clicks > 0
GROUP BY criteria, KeywordMatchType, quality_score
ORDER BY cpc_usd DESC
```

### 7.2 High-Quality Keywords with Low Impression Share

```sql
SELECT criteria, quality_score, search_impression_share, search_rank_lost_impression_share
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Pref]
WHERE quality_score >= 7 AND search_impression_share != '0'
  AND DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Pref])
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 22 T2, 0 T3, 1 T4, 1 T5 | Elements: 24/24, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Keywords_Pref | Type: Table | Production Source: Fivetran Google Ads*


### Upstream `BI_DB_dbo.BI_DB_Adwords_Geo_Conv` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Geo_Conv`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Geo_Conv.md`

# BI_DB_dbo.BI_DB_Adwords_Geo_Conv

> **STALE DATA — last refreshed 2023-09-18.** 10,984-row Google Ads geographic-level conversion tracking table. Pivots conversion_action_name into funnel columns (Registration, V2, FTD, MultipleDeposit, FTDA, MTDA) plus Android/iOS 1st-gen app conversions, grouped by country_criteria_id for geographic attribution. Part of SP_Adwords_Pref_Conv cluster (Table #4 of 12). Date range: 2023-06-19 to 2023-09-16.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_geo_conv_new_api_conv_geo_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 10,984 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Geo_Conv` tracks **Google Ads geographic-level conversion performance** for eToro's marketing acquisition funnel. Each row represents conversions for a specific date, device, campaign, ad group, country, and Google Ads account combination. The geographic dimension (country_criteria_id) enables country-level attribution of marketing conversions.

The table is Table #4 in SP_Adwords_Pref_Conv and includes both funnel conversion counts (Registration, V2, FTD, MultipleDeposit) and conversion values (FTDA, MTDA) — unlike the campaign-level Conversion_Performance_Report which lacks value columns. The geographic grain enables answering "which countries generate the most FTDs from Google Ads?"

Conversion formula: `all_conversions - view_through_conversions` (click-through only). Value columns (FTDA, MTDA) use `all_conversions_value`.

**DATA IS STALE**: Last updated 2023-09-18.

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot with Values

**What**: Raw Fivetran rows pivoted into funnel columns, including monetary values.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit, FTDA, MTDA
**Rules**:
- Registration/V2/FTD/MultipleDeposit = SUM(all_conversions - view_through_conversions) per action
- FTDA = SUM(all_conversions_value) WHERE 'FTD' — FTD conversion monetary value
- MTDA = SUM(all_conversions_value) WHERE 'Multiple Deposit' — multi-deposit monetary value

### 2.2 App Conversion Tracking (1st-Gen Only)

**What**: Device-specific conversion tracking for Android and iOS 1st-gen eToro apps.
**Columns Involved**: android_reg, android_v2, android_ftd, ios_reg, ios_v2, ios_ftd
**Rules**:
- Android tracks "eToro - Invest in stocks, crypto & trade CFDs (Android)" actions
- iOS tracks "eToro Cryptocurrency Trading (iOS)" actions
- No 2nd-gen app columns in this table (unlike Ad_Conv and Keywords_Conv)

### 2.3 Geographic Grain

**What**: Country-level attribution via Google Ads geographic criteria.
**Columns Involved**: country_criteria_id, region_criteria_id
**Rules**:
- country_criteria_id maps to Google Ads geographic criteria (e.g., 2840=US, 2826=UK, 2276=DE)
- region_criteria_id is hardcoded to NULL (removed 2021-08-23 by Amir)
- GROUP BY includes country_criterion_id for geographic disaggregation

### 2.4 Rolling Window Retention

**What**: Historical data management.
**Columns Involved**: date
**Rules**:
- DELETE old data (> 1 year from first-of-month)
- DELETE + INSERT 90-day rolling window
- Filtered by 10 specific conversion_action_name values

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID ASC for date-range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top countries by FTD conversions | GROUP BY country_criteria_id ORDER BY SUM(FTD) DESC |
| Campaign × country performance | GROUP BY campaign_id, country_criteria_id |
| FTD conversion value by country | SUM(FTDA) GROUP BY country_criteria_id |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Resolve campaign name and bidding strategy |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Resolve ad group name |
| BI_DB_Adwords_Geo_Pref | date, customer_id, device, campaign_id, ad_group_id, country_criteria_id | Combine geo conversion + performance metrics |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-09-16.
- **region_criteria_id is always NULL** — column kept in DDL but SP sets it to NULL.
- **external_customer_id = customer_id** — always identical, redundant column.
- **country_criteria_id is Google Ads geocriteria** — not an ISO country code. Requires Google Ads geocriteria mapping to resolve to country names (e.g., 2840=US, 2826=UK).
- **No 2nd-gen app columns** — unlike Ad_Conv and Keywords_Conv.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NO | Google Ads report date. Calendar day for conversion metrics. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer. Computed by DateToDateID(date). Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer account ID. Identifies the Google Ads account. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET, CONNECTED_TV, OTHER. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. Set to customer_id in SP. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | region_criteria_id | int | YES | Google Ads region criteria ID. Hardcoded to NULL since 2021-08-23 (originally used for sub-country regions). (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | country_criteria_id | int | YES | Google Ads geographic country criteria ID. Maps to Google geocriteria codes (e.g., 2840=US, 2826=UK, 2276=DE, 2724=ES, 2414=LTM). Enables country-level attribution. Mapped from Fivetran country_criterion_id. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | week | nvarchar(256) | YES | ISO week start date from Fivetran (e.g., '2023-09-11'). Used for weekly aggregation. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | Registration | int | YES | Click-through registration conversions. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | V2 | int | YES | Click-through V2 (Level 2 verification) conversions. SUM WHERE 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | FTD | int | YES | Click-through first-time deposit conversions. SUM WHERE 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | MultipleDeposit | int | YES | Click-through multiple deposit conversions. SUM WHERE 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | FTDA | int | YES | FTD conversion monetary value. SUM(all_conversions_value) WHERE 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | MTDA | int | YES | Multiple deposit conversion monetary value. SUM(all_conversions_value) WHERE 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) |
| 18 | android_reg | float | YES | 1st-gen Android app registration conversions. SUM WHERE 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | android_v2 | float | YES | 1st-gen Android app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | android_ftd | float | YES | 1st-gen Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | ios_reg | float | YES | 1st-gen iOS app registration conversions. SUM WHERE 'eToro Cryptocurrency Trading (iOS) registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | ios_v2 | float | YES | 1st-gen iOS app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | ios_ftd | float | YES | 1st-gen iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| date, customer_id, device, campaign_id, ad_group_id, week | Fivetran Google Ads | Same names | Passthrough |
| DateID | Fivetran Google Ads | date | DateToDateID() |
| external_customer_id | Fivetran Google Ads | customer_id | Duplicate |
| region_criteria_id | N/A | N/A | Hardcoded NULL |
| country_criteria_id | Fivetran Google Ads | country_criterion_id | Rename |
| Registration..MTDA | Fivetran Google Ads | conversion_action_name pivot | CASE WHEN + SUM |
| android_*/ios_* | Fivetran Google Ads | conversion_action_name (app actions) | CASE WHEN + SUM |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_geo_conv_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_geo_conv_new_api_conv_geo_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #4, P99) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT with CASE WHEN pivot
  |   GROUP BY date, customer_id, device, campaign_id, ad_group_id, country_criterion_id, week
  v
BI_DB_dbo.BI_DB_Adwords_Geo_Conv (10,984 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata lookup |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata lookup |

### 6.2 Referenced By (other objects point to this)

No known consumers. Terminal reporting table typically joined with Geo_Pref for complete geo analysis.

---

## 7. Sample Queries

### 7.1 Top Countries by FTD Conversions

```sql
SELECT country_criteria_id,
       SUM(FTD) AS total_ftds, SUM(FTDA) AS total_ftd_value,
       SUM(Registration) AS total_regs
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Conv]
GROUP BY country_criteria_id
ORDER BY total_ftds DESC
```

### 7.2 Geo Conversions + Performance Combined

```sql
SELECT c.date, c.country_criteria_id,
       SUM(c.FTD) AS ftds, SUM(p.clicks) AS clicks, SUM(p.cost) AS cost_micros
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Conv] c
JOIN [BI_DB_dbo].[BI_DB_Adwords_Geo_Pref] p
  ON c.date = p.date AND c.customer_id = p.customer_id
     AND c.device = p.device AND c.campaign_id = p.campaign_id
     AND c.ad_group_id = p.ad_group_id AND c.country_criteria_id = p.country_criteria_id
GROUP BY c.date, c.country_criteria_id
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 1 T5 | Elements: 23/23, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Geo_Conv | Type: Table | Production Source: Fivetran Google Ads*


### Upstream `BI_DB_dbo.BI_DB_Adwords_Ad_Conv` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Ad_Conv`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Ad_Conv.md`

# BI_DB_dbo.BI_DB_Adwords_Ad_Conv

> **STALE DATA — last refreshed 2023-09-18.** 10,201-row Google Ads ad-level conversion tracking table. Pivots Fivetran conversion_action_name rows into funnel columns (Registration, V2, FTD, MultipleDeposit) plus Android/iOS app-specific conversions. Covers ad-level attribution for Google Ads campaigns across DESKTOP, MOBILE, TABLET devices. Part of the SP_Adwords_Pref_Conv Fivetran cluster (Table #5 of 12). Date range: 2023-06-19 to 2023-09-16.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Fivetran_adwords_ad_conv_new_api_conv_ad_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 10,201 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Ad_Conv` tracks **Google Ads ad-level conversion performance** for eToro's marketing funnel. Each row represents one ad's conversion metrics for a given date, device, and Google Ads customer account. The table pivots Fivetran's raw conversion action rows into columnar funnel metrics: Registration, V2 (Level 2 verification), FTD (first-time deposit), and MultipleDeposit — the core marketing acquisition funnel.

The SP (`SP_Adwords_Pref_Conv`, authored by Amir G in 2021-02-22, migrated to Synapse by Chen in 2023-09-12) is a large batch SP that refreshes 12 Adwords-related tables from Fivetran external tables. This table is Table #5 in the SP. The conversion actions are filtered to specific eToro app store listings (Android: "eToro - Invest in stocks, crypto & trade CFDs", iOS: "eToro Cryptocurrency Trading", plus 2nd-gen apps) and platform funnel events.

**DATA IS STALE**: The last UpdateDate is 2023-09-18 and the date range covers only 2023-06-19 to 2023-09-16. The SP has not run since the Synapse migration. If current Google Ads data is needed, query the Fivetran external tables directly or check Databricks.

Conversion formula: `all_conversions - view_through_conversions` (click-through conversions only, excluding view-through).

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot

**What**: Raw Fivetran rows with conversion_action_name are pivoted into column per funnel stage.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit, FTDA, MTDA
**Rules**:
- Registration = SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'
- V2 = same formula WHERE 'V2 Status'
- FTD = same WHERE 'FTD'
- MultipleDeposit = same WHERE 'Multiple Deposit'
- FTDA = SUM(all_conversions_value) WHERE 'FTD' — FTD conversion value (in micros)
- MTDA = SUM(all_conversions_value) WHERE 'Multiple Deposit'

### 2.2 App-Specific Conversion Tracking

**What**: Separate conversion tracking for each mobile app store listing.
**Columns Involved**: android_reg/v2/ftd, ios_reg/v2/ftd, Regs_IOS2/V2_IOS2/FTD_IOS2, Regs_Android2/V2_android2/FTD_Android2
**Rules**:
- android_* = "eToro - Invest in stocks, crypto & trade CFDs (Android)" app conversions
- ios_* = "eToro Cryptocurrency Trading (iOS)" app conversions
- *_IOS2 = "eToro: Crypto. Stocks. Social. (iOS)" 2nd-gen app
- *_Android2 = "eToro: Investing made social (Android)" 2nd-gen app

### 2.3 Rolling Window Management

**What**: Data retention follows a rolling window with year-ago floor.
**Columns Involved**: date, DateID
**Rules**:
- DELETE dates older than DATEADD(year, -1, first-of-month)
- DELETE dates within the 90-day refresh window
- INSERT fresh data from Fivetran for the 90-day window

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CI(DateID). Filter on DateID for range queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily conversion funnel | `SELECT date, SUM(Registration), SUM(V2), SUM(FTD) FROM ... GROUP BY date` |
| Ad-level performance | `WHERE id = {ad_id} AND DateID BETWEEN ...` |
| Device breakdown | `GROUP BY device` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_Adwords_Ad_Pref | date, customer_id, id, ad_group_id, device | Join conversion data with performance data (impressions, clicks, cost) |
| BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign name, bidding strategy |
| BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group name |

### 3.4 Gotchas

- **DATA IS STALE**: Last update September 2023. Do not use for current analysis.
- **android_*/ios_* are float**: These conversion columns are float, not int — may contain fractional values from Google's attribution model.
- **Regs_IOS2/Android2 are int**: The 2nd-gen app columns use int type, unlike the float-typed 1st-gen columns.
- **external_customer_id = customer_id**: These are always the same value (SP duplicates customer_id).
- **FTDA/MTDA are conversion VALUES, not counts**: These are monetary amounts in micros, not conversion counts.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NO | Google Ads reporting date. Range: rolling 90-day window with year-ago floor. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Integer date key in YYYYMMDD format. Computed by DateToDateID(date) function. Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer/account ID. Identifies the Google Ads account running the campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | campaign_id | bigint | YES | Google Ads campaign ID. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | device | nvarchar(256) | YES | Device type: DESKTOP, MOBILE, TABLET. From Google Ads segmentation. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | id | bigint | YES | Google Ads ad ID (renamed from ad_id in Fivetran source). Unique creative identifier within an ad group. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | ad_group_id | bigint | YES | Google Ads ad group ID. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | week | nvarchar(256) | YES | ISO week start date (Monday) for the reporting period. From Google Ads API. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | external_customer_id | bigint | YES | Duplicate of customer_id. SP sets this = customer_id. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | Registration | int | YES | Click-through registration conversions (all_conversions - view_through_conversions) for conversion_action_name = 'Registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | V2 | int | YES | Click-through Level 2 verification conversions for conversion_action_name = 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | FTD | int | YES | Click-through first-time deposit conversions for conversion_action_name = 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | MultipleDeposit | int | YES | Click-through multiple deposit conversions for conversion_action_name = 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | FTDA | int | YES | FTD conversion value (all_conversions_value) — monetary amount attributed to FTD conversions. Not a count. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | MTDA | int | YES | Multiple Deposit conversion value (all_conversions_value). Not a count. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at SP execution time. (Tier 5 — SP_Adwords_Pref_Conv) |
| 17 | android_reg | float | YES | Android app ("eToro - Invest in stocks, crypto & trade CFDs") registration conversions. Float due to Google's fractional attribution. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | android_v2 | float | YES | Android app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | android_ftd | float | YES | Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | ios_reg | float | YES | iOS app ("eToro Cryptocurrency Trading") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | ios_v2 | float | YES | iOS app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | ios_ftd | float | YES | iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | Regs_IOS2 | int | YES | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social.") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | V2_IOS2 | int | YES | 2nd-gen iOS app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | FTD_IOS2 | int | YES | 2nd-gen iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | Regs_Android2 | int | YES | 2nd-gen Android app ("eToro: Investing made social") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 27 | V2_android2 | int | YES | 2nd-gen Android app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 28 | FTD_Android2 | int | YES | 2nd-gen Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| date-week, campaign_id, device, ad_group_id | Google Ads API via Fivetran | Direct fields | Passthrough |
| id | Google Ads API | ad_id | Rename |
| Registration-FTD_Android2 | Google Ads API | conversion_action_name + all_conversions | Pivot (CASE WHEN) |
| DateID | date | date | DateToDateID() function |

### 5.2 ETL Pipeline

```
Google Ads API (ad-level conversion report)
  |-- Fivetran connector (adwords_ad_conv schema) ---|
  v
External_Fivetran_adwords_ad_conv_new_api_conv_ad_performance_report (Parquet/Bronze)
  |-- SP_Adwords_Pref_Conv @date (Table #5) ---|
  |   DELETE old + INSERT (90-day window)
  |   PIVOT: conversion_action_name → funnel columns
  v
BI_DB_dbo.BI_DB_Adwords_Ad_Conv (10,201 rows — STALE since 2023-09-18)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | Campaign name/config lookup |
| ad_group_id | BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | Ad group name lookup |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in SSDT.

---

## 7. Sample Queries

### 7.1 Daily Funnel Summary

```sql
SELECT date, SUM(Registration) AS regs, SUM(V2) AS v2, SUM(FTD) AS ftd
FROM [BI_DB_dbo].[BI_DB_Adwords_Ad_Conv]
GROUP BY date
ORDER BY date DESC
```

### 7.2 Top Converting Ads

```sql
SELECT TOP 20 id AS ad_id, campaign_id, SUM(FTD) AS total_ftd, SUM(Registration) AS total_regs
FROM [BI_DB_dbo].[BI_DB_Adwords_Ad_Conv]
GROUP BY id, campaign_id
ORDER BY total_ftd DESC
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence or Jira sources found. SP comment references Fivetran Google Tables collection (Amir G, 2021).

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 27 T2, 0 T3, 0 T4, 1 T5 | Elements: 28/28, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Ad_Conv | Type: Table | Production Source: Fivetran Google Ads (ad conversion report)*


### Upstream `BI_DB_dbo.BI_DB_Adwords_Campaign_Performance_Report` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Campaign_Performance_Report`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Campaign_Performance_Report.md`

# BI_DB_dbo.BI_DB_Adwords_Campaign_Performance_Report

> **STALE DATA — last refreshed 2023-09-18.** 31K-row Google Ads campaign-level performance report tracking impressions, clicks, cost, conversions, video views, and search impression share per campaign and device. Covers Jun-Sep 2023 across multiple Google Ads accounts. Part of SP_Adwords_Pref_Conv Fivetran cluster (Table #7 of 12).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_new_api_campaign_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 31,318 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Campaign_Performance_Report` stores **Google Ads campaign-level performance** — the highest aggregation level in the Adwords table family. Each row represents one campaign's daily performance for a given device and Google Ads account. This table provides the campaign-level KPIs (spend, impressions, clicks, search impression share) used for budget allocation and campaign optimization.

The SP sources from Fivetran's campaign performance report, performing column renames (e.g., `status` → `campaign_status`, `id` → `campaign_id`, `name` → `campaign_name`, `cost_micros` → `cost`). The `average_position` column exists in the DDL but is deprecated — the SP's INSERT statement has it commented out, so it will be NULL.

**DATA IS STALE**: Date range 2023-06-19 to 2023-09-17. SP has not run since Synapse migration (2023-09-12).

---

## 2. Business Logic

### 2.1 Campaign-Level Aggregation

**What**: One row per campaign × date × device with performance metrics.
**Columns Involved**: impressions, clicks, cost, all_conversions, video_views, interactions
**Rules**:
- cost = cost_micros from Google (in micros, divide by 1,000,000 for currency)
- all_conversions = total conversions across all conversion actions (not pivoted by funnel)
- search_impression_share = fraction of eligible impressions actually received (for search campaigns)
- No aggregation in SP — direct 1:1 from Fivetran source

### 2.2 Search Impression Share Tracking

**What**: Campaign-level search impression share for competitive analysis.
**Columns Involved**: search_impression_share
**Rules**:
- String type (nvarchar) — may contain formatted percentages or decimals
- Only meaningful for Search campaigns (not Display/Video)
- Values < 1.0 indicate budget or quality constraints limiting impression delivery

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CI(DateID). Filter on DateID for range queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily total spend | `SELECT date, SUM(cost)/1000000 AS spend FROM ... GROUP BY date` |
| Campaign performance ranking | `GROUP BY campaign_id, campaign_name ORDER BY SUM(clicks) DESC` |
| Device breakdown | `GROUP BY device` |
| Search impression share trend | `WHERE campaign_status = 'ENABLED' AND search_impression_share != '0'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_Adwords_Ad_Conv | campaign_id, date, device, customer_id | Campaign-level conversion breakdown |
| BI_DB_dbo.BI_DB_Adwords_Ad_Pref | campaign_id, date, device, customer_id | Ad-level detail within campaign |
| BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign bidding strategy, budget |

### 3.4 Gotchas

- **DATA IS STALE**: Last update September 2023.
- **cost is in micros**: Divide by 1,000,000 for actual currency amount.
- **average_position is always NULL**: The column exists in DDL but the SP's INSERT has it commented out (deprecated by Google).
- **search_impression_share is nvarchar**: Not a numeric type — may need CAST for calculations.
- **labels is nvarchar(max)**: JSON array of Google Ads label resource names.
- **DDL has 17 columns** (not 18 as stated in batch assignment): average_position column counts but is never populated.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | YES | Google Ads reporting date. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | bigint | YES | Integer date key in YYYYMMDD format. Computed by DateToDateID(date). Clustered index. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | impressions | bigint | YES | Number of times ads in this campaign were shown on the reporting date. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | campaign_status | nvarchar(max) | YES | Campaign delivery status: ENABLED, PAUSED, REMOVED. Mapped from Fivetran 'status' field. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | campaign_id | bigint | YES | Google Ads campaign ID. Mapped from Fivetran 'id' field. FK to Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | average_position | float | YES | **DEPRECATED — always NULL.** Google retired average position in September 2019. SP has this column commented out in INSERT. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | campaign_name | nvarchar(max) | YES | Human-readable campaign name from Google Ads UI. Mapped from Fivetran 'name' field. Naming convention encodes region, channel, objective. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | search_impression_share | nvarchar(max) | YES | Fraction of eligible search impressions received. String type — may need CAST for numeric operations. Only meaningful for search campaigns. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | clicks | bigint | YES | Number of clicks on ads in this campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | cost | float | YES | Campaign spend in micros (divide by 1,000,000 for currency units). Mapped from cost_micros. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | all_conversions | float | YES | Total conversion count across all conversion actions. Not pivoted by funnel stage. Float due to Google's data-driven attribution model. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | device | nvarchar(max) | YES | Device type: DESKTOP, MOBILE, TABLET. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | customer_id | bigint | YES | Google Ads customer/account ID. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | labels | nvarchar(max) | YES | Google Ads labels applied to the campaign. JSON array of label resource names. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | video_views | bigint | YES | Total video views for video campaigns. 0 for non-video campaigns. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | interactions | bigint | YES | Total interactions (clicks + video views + other engagements). (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | UpdateDate | datetime | NO | ETL metadata: GETDATE() at SP execution time. NOT NULL in DDL. (Tier 5 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| campaign_status | Fivetran | status | Rename |
| campaign_id | Fivetran | id | Rename |
| campaign_name | Fivetran | name | Rename |
| cost | Fivetran | cost_micros | Rename (still in micros) |
| DateID | date | date | DateToDateID() |
| All others | Fivetran | Same name | Passthrough |

### 5.2 ETL Pipeline

```
Google Ads API (campaign performance report)
  |-- Fivetran connector (adwords_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_new_api_campaign_performance_report (Parquet/Bronze)
  |-- SP_Adwords_Pref_Conv @date (Table #7) ---|
  |   DELETE old + INSERT (90-day window)
  |   Column renames: status→campaign_status, id→campaign_id, name→campaign_name
  v
BI_DB_dbo.BI_DB_Adwords_Campaign_Performance_Report (31,318 rows — STALE since 2023-09-18)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | Campaign config/bidding strategy |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in SSDT.

---

## 7. Sample Queries

### 7.1 Daily Campaign Spend Summary

```sql
SELECT date, COUNT(DISTINCT campaign_id) AS campaigns,
       SUM(impressions) AS total_impressions, SUM(clicks) AS total_clicks,
       SUM(cost)/1000000.0 AS total_spend_usd
FROM [BI_DB_dbo].[BI_DB_Adwords_Campaign_Performance_Report]
WHERE campaign_status = 'ENABLED'
GROUP BY date
ORDER BY date DESC
```

### 7.2 Top Campaigns by Clicks

```sql
SELECT TOP 20 campaign_id, campaign_name,
       SUM(clicks) AS total_clicks, SUM(cost)/1000000.0 AS total_spend
FROM [BI_DB_dbo].[BI_DB_Adwords_Campaign_Performance_Report]
GROUP BY campaign_id, campaign_name
ORDER BY total_clicks DESC
```

---

## 8. Atlassian Knowledge Sources

No specific sources found. SP authored by Amir G (2021), campaign report added by Chen (2021-11).

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 16 T2, 0 T3, 0 T4, 1 T5 | Elements: 17/17, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Campaign_Performance_Report | Type: Table | Production Source: Fivetran Google Ads (campaign performance report)*


### Upstream `BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Conversion_Performance_Report.md`

# BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report

> **STALE DATA — last refreshed 2023-09-18.** 4,678-row Google Ads campaign-level conversion tracking table. Pivots Fivetran conversion_action_name rows into funnel columns (Registration, V2, FTD, MultipleDeposit) plus full app lifecycle tracking (FirstOpen, Registration, V2, FTD, Redeposit) for Android and iOS 1st-gen and 2nd-gen eToro apps. Part of the SP_Adwords_Pref_Conv Fivetran cluster (Table #8 of 12). Date range: 2023-06-19 to 2023-09-16. Device breakdown: DESKTOP, MOBILE, TABLET, CONNECTED_TV.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_new_api_conversion_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 4,678 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Conversion_Performance_Report` tracks **Google Ads campaign-level conversion performance** for eToro's marketing acquisition funnel. Each row represents one campaign's conversion metrics for a given date, device type, and Google Ads customer account. The table pivots Fivetran's raw conversion action rows into columnar funnel metrics at the campaign level — the broadest conversion aggregation in the Adwords cluster.

The SP (`SP_Adwords_Pref_Conv`, authored by Amir G 2021-02-22, migrated to Synapse by Chen 2023-09-12) refreshes 12 Adwords-related tables from Fivetran external tables. This table is Table #8 in the SP. It differs from the ad-level (`BI_DB_Adwords_Ad_Conv`) and keyword-level (`BI_DB_Adwords_Keywords_Conv`) tables by providing a campaign-level view with **full app lifecycle tracking** — including FirstOpen and Redeposit events not tracked in other conversion tables.

**DATA IS STALE**: The last UpdateDate is 2023-09-18 and the date range covers only 2023-06-19 to 2023-09-16. The SP has not run since the Synapse migration. If current Google Ads data is needed, query the Fivetran external tables directly or check Databricks.

Conversion formula: `all_conversions - view_through_conversions` (click-through conversions only, excluding view-through).

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot

**What**: Raw Fivetran rows with conversion_action_name are pivoted into one column per funnel stage at campaign level.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit
**Rules**:
- Registration = SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'
- V2 = same formula WHERE 'V2 Status'
- FTD = same WHERE 'FTD'
- MultipleDeposit = same WHERE 'Multiple Deposit'
- Unlike Ad_Conv and Geo_Conv, this table does NOT have FTDA/MTDA value columns

### 2.2 App Lifecycle Tracking (1st-Gen)

**What**: Full app lifecycle conversion tracking for the original Android and iOS app store listings.
**Columns Involved**: Android_FirstOpen, Android_Registration, Android_V2, Android_FTD, Android_Redeposit, iOS_FirstOpen, iOS_Registration, iOS_V2, iOS_FTD, iOS_Redeposit
**Rules**:
- Android columns track "eToro - Invest in stocks, crypto & trade CFDs (Android)" conversion actions
- iOS columns track "eToro Cryptocurrency Trading (iOS)" conversion actions
- Includes FirstOpen and Redeposit events unique to this table (not in Ad_Conv or Keywords_Conv)
- Formula: SUM(all_conversions - view_through_conversions) per action

### 2.3 App Conversion Tracking (2nd-Gen)

**What**: Conversion tracking for newer eToro app store listings (added 2022-05-10).
**Columns Involved**: Regs_IOS2, V2_IOS2, FTD_IOS2, Regs_Android2, V2_android2, FTD_Android2
**Rules**:
- IOS2 columns track "eToro: Crypto. Stocks. Social. (iOS)" app
- Android2 columns track "eToro: Investing made social (Android)" app
- Only tracks Registration, V2, FTD events (no FirstOpen/Redeposit)
- These columns appear mostly NULL/empty in current data — likely the newer app listings had low adoption before data went stale

### 2.4 Rolling Window Retention

**What**: Historical data management to keep ~1 year of data.
**Columns Involved**: date, DateID
**Rules**:
- DELETE rows WHERE date < first day of month one year ago
- DELETE rows WHERE date >= @FromDate (90 days back) AND date < today (overlap window)
- INSERT new rows for the 90-day window from Fivetran source

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution is ROUND_ROBIN (no skew). Clustered index on DateID ASC optimizes date-range scans. No distribution key available for colocation — all JOINs to Dictionary tables will be broadcast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Campaign funnel performance for a date range | `WHERE DateID BETWEEN 20230701 AND 20230901` — uses clustered index |
| Compare web vs Android vs iOS conversions | SUM Registration vs Android_Registration vs iOS_Registration |
| Find top-converting campaigns | GROUP BY campaign_id, campaign_name ORDER BY SUM(FTD) DESC |
| Device breakdown | GROUP BY Device |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Dictionary_Campaign | campaign_id = campaign_id | Resolve campaign metadata, bidding strategy, status |
| BI_DB_Adwords_Conversion_Performance_Report self | Same campaign_id across dates | Time-series trend analysis |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-09-16. Do not use for current reporting.
- **No FTDA/MTDA columns** — unlike Ad_Conv and Geo_Conv, this table has no conversion value columns. Use Ad_Conv for FTD monetary values.
- **2nd-gen app columns mostly empty** — Regs_IOS2, V2_IOS2 etc. are largely NULL in the available data.
- **float vs int inconsistency** — web funnel columns (Registration, V2, FTD, MultipleDeposit) are float, while 2nd-gen columns (Regs_IOS2 etc.) are int. The float type on web columns is an artifact of the Fivetran schema.
- **labels is JSON** — contains Google Ads label arrays like `[customers/5486244699/labels/21683977523]`. Parse with JSON functions.
- **campaign_id comes from Fivetran `id`** — the SP maps `id` (campaign ID in Fivetran) to `campaign_id` in this table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | YES | Google Ads report date. The calendar day for which conversion metrics are aggregated. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | bigint | YES | Date as YYYYMMDD integer. Computed by DateToDateID(date) function. Clustered index key for date-range queries. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | campaign_id | bigint | YES | Google Ads campaign identifier. Mapped from Fivetran `id` column. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | campaign_name | nvarchar(max) | YES | Google Ads campaign name. Mapped from Fivetran `name` column. Encodes targeting metadata: region, product, channel, language, affiliate ID (e.g., 'UK_Discovery_Regular_General3_EN_117057_New'). (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | customer_id | bigint | YES | Google Ads customer account ID (MCC or sub-account). Identifies the Google Ads account running the campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | labels | nvarchar(max) | YES | Google Ads campaign labels as JSON array. Contains resource name paths like `[customers/{id}/labels/{label_id}]`. Used for campaign categorization in Google Ads. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | Registration | float | YES | Web funnel: click-through registration conversions. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'. Excludes view-through. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | V2 | float | YES | Web funnel: click-through V2 (Level 2 verification) conversions. SUM WHERE conversion_action_name = 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | FTD | float | YES | Web funnel: click-through first-time deposit conversions. SUM WHERE conversion_action_name = 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | MultipleDeposit | float | YES | Web funnel: click-through multiple deposit conversions. SUM WHERE conversion_action_name = 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | Android_FirstOpen | float | YES | 1st-gen Android app: first open events. SUM WHERE 'eToro - Invest in stocks, crypto & trade CFDs (Android) first_open'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | Android_FTD | float | YES | 1st-gen Android app: first-time deposit conversions. SUM WHERE '...(Android) FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | Android_Redeposit | float | YES | 1st-gen Android app: redeposit conversions. SUM WHERE '...(Android) Redeposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | Android_Registration | float | YES | 1st-gen Android app: registration conversions. SUM WHERE '...(Android) registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | Android_V2 | float | YES | 1st-gen Android app: Level 2 verification conversions. SUM WHERE '...(Android) Verification Level - 2'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | iOS_FirstOpen | float | YES | 1st-gen iOS app: first open events. SUM WHERE 'eToro Cryptocurrency Trading (iOS) first_open'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | iOS_FTD | float | YES | 1st-gen iOS app: first-time deposit conversions. SUM WHERE '...(iOS) FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | iOS_Redeposit | float | YES | 1st-gen iOS app: redeposit conversions. SUM WHERE '...(iOS) Redeposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | iOS_Registration | float | YES | 1st-gen iOS app: registration conversions. SUM WHERE '...(iOS) registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | iOS_V2 | float | YES | 1st-gen iOS app: Level 2 verification conversions. SUM WHERE '...(iOS) Verification Level - 2'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) |
| 22 | Regs_IOS2 | int | YES | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social."): registration conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | V2_IOS2 | int | YES | 2nd-gen iOS app: Level 2 verification conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | FTD_IOS2 | int | YES | 2nd-gen iOS app: first-time deposit conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | Regs_Android2 | int | YES | 2nd-gen Android app ("eToro: Investing made social"): registration conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | V2_android2 | int | YES | 2nd-gen Android app: Level 2 verification conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 27 | FTD_Android2 | int | YES | 2nd-gen Android app: first-time deposit conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 28 | Device | nvarchar(50) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET, CONNECTED_TV. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| date | Fivetran Google Ads | date | Passthrough |
| DateID | Fivetran Google Ads | date | DateToDateID() function |
| campaign_id | Fivetran Google Ads | id | Rename |
| campaign_name | Fivetran Google Ads | name | Rename |
| customer_id | Fivetran Google Ads | customer_id | Passthrough |
| labels | Fivetran Google Ads | labels | Passthrough |
| Registration..MultipleDeposit | Fivetran Google Ads | conversion_action_name + all_conversions + view_through_conversions | CASE WHEN pivot + SUM |
| Android_* | Fivetran Google Ads | conversion_action_name (1st-gen Android app actions) | CASE WHEN pivot + SUM |
| iOS_* | Fivetran Google Ads | conversion_action_name (1st-gen iOS app actions) | CASE WHEN pivot + SUM |
| *_IOS2, *_Android2 | Fivetran Google Ads | conversion_action_name (2nd-gen app actions) | CASE WHEN pivot + SUM |
| UpdateDate | SP | N/A | GETDATE() |
| Device | Fivetran Google Ads | device | Passthrough |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_new_api_conversion_performance_report (Fivetran external table)
  |-- SP_Adwords_Pref_Conv @date (Table #8, P99, SB_FinanceReportSPS) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT with CASE WHEN pivot
  v
BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report (4,678 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Resolves to campaign metadata (name, bidding strategy, budget, status) |

### 6.2 Referenced By (other objects point to this)

No known consumers. This is a terminal reporting table.

---

## 7. Sample Queries

### 7.1 Campaign Funnel Performance by Date

```sql
SELECT date, campaign_name,
       SUM(Registration) AS regs, SUM(V2) AS v2s, SUM(FTD) AS ftds,
       SUM(MultipleDeposit) AS multi_deps
FROM [BI_DB_dbo].[BI_DB_Adwords_Conversion_Performance_Report]
WHERE DateID BETWEEN 20230801 AND 20230901
GROUP BY date, campaign_name
ORDER BY SUM(FTD) DESC
```

### 7.2 Web vs Android vs iOS Conversion Comparison

```sql
SELECT campaign_name,
       SUM(Registration) AS web_reg,
       SUM(Android_Registration) AS android_reg,
       SUM(iOS_Registration) AS ios_reg,
       SUM(Regs_Android2) AS android2_reg,
       SUM(Regs_IOS2) AS ios2_reg
FROM [BI_DB_dbo].[BI_DB_Adwords_Conversion_Performance_Report]
GROUP BY campaign_name
HAVING SUM(Registration) + SUM(ISNULL(Android_Registration,0)) + SUM(ISNULL(iOS_Registration,0)) > 0
ORDER BY web_reg DESC
```

### 7.3 Device Type Breakdown

```sql
SELECT Device,
       COUNT(*) AS rows,
       SUM(Registration) AS total_regs,
       SUM(FTD) AS total_ftds
FROM [BI_DB_dbo].[BI_DB_Adwords_Conversion_Performance_Report]
GROUP BY Device
ORDER BY total_ftds DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. The Adwords Fivetran cluster is managed by the BI team (originally authored by Amir G, with contributions from Chen, Jan Iablunovskey, and Eti per SP change history).

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 1 T5 | Elements: 28/28, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report | Type: Table | Production Source: Fivetran Google Ads*


### Upstream `BI_DB_dbo.BI_DB_Adwords_Search_Perf` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Search_Perf`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Search_Perf.md`

# BI_DB_dbo.BI_DB_Adwords_Search_Perf

> **STALE DATA — last refreshed 2023-09-18.** 14M-row Google Ads search query performance table at monthly granularity. Captures actual user search terms with impression/click/cost metrics aggregated by month, device, match type, account, and ad group. Part of SP_Adwords_Pref_Conv cluster (Table #9 of 12). Month range: 2023-05-01 to 2023-09-01. 13 Google Ads accounts, 1,146 ad groups. Predominantly MOBILE traffic (85%).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_search_perf_new_api_perf_search_query_performance_report → SP_Adwords_Pref_Conv |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Monthly rolling DELETE+INSERT with 1-year floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (month ASC) |
| **Row Count** | 14,034,434 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Search_Perf` tracks **actual user search query performance** in Google Ads — impressions, top-impressions, clicks, and cost for every unique search term that triggered an eToro ad. Unlike `BI_DB_Adwords_Search_Conv` (which tracks conversions from search queries), this table captures the raw advertising performance metrics before any conversion analysis.

Each row represents one search query's performance metrics for a given month, device, match type, Google Ads account (customer_id), currency, and ad group. The monthly grain aggregates daily Fivetran data via `SUM` to keep volume manageable given the extremely high cardinality of search queries (14M rows across just 5 months).

This is Table #9 in SP_Adwords_Pref_Conv. The SP first loads raw data from the Fivetran external table into `#search_perf_prep` (computing `top_impressions` = `top_impression_percentage * impressions`), then aggregates into the target table. DELETE window: removes data older than 1 year and reloads the target month range.

**DATA IS STALE**: Last updated 2023-09-18. Only 5 months of data (May–Sept 2023). All UpdateDate values are identical (single bulk load). 3 columns (query_targeting_status, keyword_id, search_key) are NOT populated by the SP and are always NULL.

---

## 2. Business Logic

### 2.1 Monthly Performance Aggregation

**What**: Daily search query performance is aggregated to monthly grain via SUM.
**Columns Involved**: impressions, top_impressions, clicks, cost
**Rules**:
- impressions = SUM of daily impressions for each unique query/device/account/ad_group/month combination
- top_impressions = SUM(top_impression_percentage * impressions) — weighted impressions appearing in top ad positions
- clicks = SUM of daily clicks
- cost = SUM(cost_micros) — value stored in MICROS (divide by 1,000,000 for currency units)

### 2.2 Search Query Match Types

**What**: How the user's actual search matched the advertiser's keyword targeting.
**Columns Involved**: query_match_type_with_variant
**Rules**:
- BROAD = broad match, loosely related (89% of rows)
- EXACT = exact keyword match (5.4%)
- NEAR_PHRASE = close variant of phrase match (2.9%)
- NEAR_EXACT = close variant of exact match (1.6%)
- PHRASE = phrase contained in query (0.9%)

### 2.3 Unpopulated Columns

**What**: Three DDL columns are never populated by the SP.
**Columns Involved**: query_targeting_status, keyword_id, search_key
**Rules**:
- These columns exist in the DDL but the INSERT statement does not include them
- All 14M rows have NULL for these columns
- query_targeting_status and query_match_type_with_variant are functionally the same field (same Fivetran source: search_term_match_type), but only query_match_type_with_variant is populated

### 2.4 Device Distribution

**What**: Ad impression device breakdown.
**Columns Involved**: device
**Rules**:
- MOBILE = 85% (11.9M rows)
- DESKTOP = 12.7% (1.8M rows)
- CONNECTED_TV = 2% (276K rows)
- TABLET = 0.4% (56K rows)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no co-located JOINs. CLUSTERED INDEX on `month` enables efficient range scans by time period.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Top search terms by impressions for a month | `WHERE month = '2023-08-01' ORDER BY impressions DESC` |
| Cost per click by match type | `SUM(cost)/1000000.0 / NULLIF(SUM(clicks), 0) GROUP BY query_match_type_with_variant` |
| Mobile vs Desktop performance | `GROUP BY device` with SUM of impressions, clicks, cost |
| Top-of-page impression rate | `SUM(top_impressions) / NULLIF(SUM(impressions), 0)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id = ad_group_id | Resolve ad group name and status |
| BI_DB_Adwords_Search_Conv | month + customer_id + query + device + query_match_type_with_variant | Match performance to conversions |

### 3.4 Gotchas

- **cost is in MICROS**: Divide by 1,000,000 to get actual currency amount (USD)
- **3 always-NULL columns**: query_targeting_status, keyword_id, search_key are never populated — do not filter on them
- **external_customer_id = customer_id**: Identical values, duplicated in the INSERT (SELECT customer_id twice)
- **STALE since Sept 2023**: No new data. Fivetran pipeline appears decommissioned
- **Monthly grain NOT daily**: Unlike most Adwords tables, this aggregates at monthly level (too many unique search queries for daily)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis (SP_Adwords_Pref_Conv) | High — verified from stored procedure logic |
| Tier 4 | Inferred from data patterns | Medium — confirmed from live data but no upstream documentation |
| Tier 5 | Standard ETL metadata | Canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | month | nvarchar(256) | YES | Monthly period start date (first day of month, e.g., '2023-08-01'). Aggregation grain for search query performance. Range: 2023-05-01 to 2023-09-01. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | customer_id | bigint | NO | Google Ads account identifier (MCC-level customer ID). 13 distinct accounts. Used as GROUP BY key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | query | nvarchar(256) | YES | Actual search term the user typed that triggered the ad impression. Renamed from Fivetran field 'search_term'. High cardinality (millions of unique queries). (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | device | nvarchar(256) | YES | Device type where the ad was shown. Values: MOBILE, DESKTOP, CONNECTED_TV, TABLET. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | query_targeting_status | nvarchar(256) | YES | **NOT POPULATED** — column exists in DDL but SP does not insert data. Always NULL across all 14M rows. Functionally same as query_match_type_with_variant. (Tier 4 — not inserted by SP) |
| 6 | external_customer_id | bigint | YES | Duplicate of customer_id — SP inserts customer_id into both columns. Same 13 distinct values. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | query_match_type_with_variant | nvarchar(256) | YES | How the search query matched the advertiser's keyword. BROAD=89%, EXACT=5.4%, NEAR_PHRASE=2.9%, NEAR_EXACT=1.6%, PHRASE=0.9%. Renamed from Fivetran field 'search_term_match_type'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | keyword_id | bigint | YES | **NOT POPULATED** — column exists in DDL but SP does not insert data. Always NULL. Intended for Google Ads keyword identifier. (Tier 4 — not inserted by SP) |
| 9 | account_currency_code | nvarchar(256) | YES | Google Ads account currency. Renamed from Fivetran field 'customer_currency_code'. All sampled values are 'USD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | ad_group_id | bigint | YES | Google Ads ad group identifier. 1,146 distinct ad groups across 13 accounts. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | search_key | nvarchar(1340) | YES | **NOT POPULATED** — column exists in DDL but SP does not insert data. Always NULL. Likely intended as composite search key. (Tier 4 — not inserted by SP) |
| 12 | impressions | bigint | YES | Total ad impressions for this search query/month/device/account/ad_group combination. SUM aggregation from daily Fivetran data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | top_impressions | float | YES | Weighted top-of-page impressions. Computed as SUM(top_impression_percentage * impressions) from source. Represents estimated impressions appearing above organic results. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | clicks | bigint | YES | Total ad clicks for this search query/month/device/account/ad_group combination. SUM aggregation from daily Fivetran data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | cost | float | YES | Total advertising cost in MICROS (divide by 1,000,000 for currency amount). SUM(cost_micros) from source. Currency determined by account_currency_code (USD). (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was loaded by SP_Adwords_Pref_Conv (GETDATE()). All rows show 2023-09-18 (single bulk load). (Tier 5 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| month | Fivetran Google Ads API | month | Passthrough |
| customer_id | Fivetran Google Ads API | customer_id | Passthrough |
| query | Fivetran Google Ads API | search_term | Rename |
| device | Fivetran Google Ads API | device | Passthrough |
| query_targeting_status | — | — | Not inserted |
| external_customer_id | Fivetran Google Ads API | customer_id | Duplicate of customer_id |
| query_match_type_with_variant | Fivetran Google Ads API | search_term_match_type | Rename |
| keyword_id | — | — | Not inserted |
| account_currency_code | Fivetran Google Ads API | customer_currency_code | Rename |
| ad_group_id | Fivetran Google Ads API | ad_group_id | Passthrough |
| search_key | — | — | Not inserted |
| impressions | Fivetran Google Ads API | impressions | SUM aggregation |
| top_impressions | Fivetran Google Ads API | top_impression_percentage * impressions | SUM(computed) |
| clicks | Fivetran Google Ads API | clicks | SUM aggregation |
| cost | Fivetran Google Ads API | cost_micros | SUM (value in micros) |
| UpdateDate | — | GETDATE() | ETL-generated |

### 5.2 ETL Pipeline

```
Google Ads API (search_query_performance_report)
  |-- Fivetran connector (adwords_new_api) ---|
  v
Bronze Data Lake (adwords/search_perf/new_api/perf/)
  |-- External Table (ADLS Gen2 Parquet) ---|
  v
BI_DB_dbo.External_Bronze_Fivetran_adwords_search_perf_new_api_perf_search_query_performance_report
  |-- SP_Adwords_Pref_Conv (Table #9) ---|
  |   1. Load into #search_perf_prep (compute top_impressions)
  |   2. DELETE old data (>1 year + target month window)
  |   3. INSERT aggregated (GROUP BY month/customer/query/device/match_type/currency/ad_group)
  v
BI_DB_dbo.BI_DB_Adwords_Search_Perf (14M rows, STALE since 2023-09-18)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| ad_group_id | BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | Resolves ad group name and status |

### 6.2 Referenced By (other objects point to this)

No known consumers in the documented wiki corpus.

---

## 7. Sample Queries

### 7.1 Top Search Terms by Impressions

```sql
SELECT TOP 20
    query,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(cost) / 1000000.0 AS total_cost_usd,
    CAST(SUM(clicks) AS FLOAT) / NULLIF(SUM(impressions), 0) AS ctr
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Perf]
WHERE month = '2023-08-01'
GROUP BY query
ORDER BY total_impressions DESC
```

### 7.2 Cost Per Click by Match Type

```sql
SELECT
    query_match_type_with_variant,
    SUM(cost) / 1000000.0 AS total_cost_usd,
    SUM(clicks) AS total_clicks,
    SUM(cost) / 1000000.0 / NULLIF(SUM(clicks), 0) AS cpc_usd
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Perf]
GROUP BY query_match_type_with_variant
ORDER BY total_cost_usd DESC
```

### 7.3 Top-of-Page Rate by Device

```sql
SELECT
    device,
    SUM(impressions) AS total_impressions,
    SUM(top_impressions) AS total_top_impressions,
    SUM(top_impressions) / NULLIF(CAST(SUM(impressions) AS FLOAT), 0) AS top_rate
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Perf]
GROUP BY device
ORDER BY total_impressions DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this Google Ads Fivetran table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 12 T2, 0 T3, 3 T4, 1 T5 | Elements: 16/16, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Search_Perf | Type: Table | Production Source: Fivetran Google Ads → SP_Adwords_Pref_Conv*


### Upstream `BI_DB_dbo.BI_DB_Adwords_Search_Conv` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Adwords_Search_Conv`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Search_Conv.md`

# BI_DB_dbo.BI_DB_Adwords_Search_Conv

> **STALE DATA — last refreshed 2023-09-18.** 12,992-row Google Ads search query conversion tracking table at monthly granularity. Captures actual user search terms (not just keywords) that triggered conversions, with funnel pivot (Registration/V2/FTD/MultipleDeposit/FTDA/MTDA) plus 1st-gen app conversions. Only Adwords table with HASH(customer_id) distribution. Part of SP_Adwords_Pref_Conv cluster (Table #10 of 12). Month range: 2023-05-01 to 2023-08-01. Match types: EXACT, NEAR_EXACT, NEAR_PHRASE, BROAD, PHRASE.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. 4-month rolling DELETE+INSERT + year-ago floor. Monthly grain. |
| **Synapse Distribution** | HASH (customer_id) |
| **Synapse Index** | CLUSTERED INDEX (month ASC) |
| **Row Count** | 12,992 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Search_Conv` tracks **actual user search queries** that triggered conversions in Google Ads. Unlike Keywords tables (which track advertiser-defined keywords), this table captures the real search terms users typed. This enables search intent analysis — understanding exactly what users searched for before converting on eToro.

Each row represents one search query's conversion metrics for a given month, device, campaign, ad group, match type, landing page (final_url), and Google Ads account. The monthly grain (vs daily in other tables) keeps volume manageable given the high cardinality of unique search queries.

This is Table #10 in SP_Adwords_Pref_Conv and the only table in the Adwords cluster using HASH distribution (on customer_id) and monthly granularity. The DELETE window is 4 months (not 90 days) matching the monthly grain. Examples of search queries captured: 'robinhood option', 'invest in virtual reality stocks', 'investimenti in borsa'.

**DATA IS STALE**: Last updated 2023-09-18. Month range: May to August 2023 only.

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot

**What**: Standard conversion pivot from conversion_action_name at search query level.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit, FTDA, MTDA
**Rules**:
- Same SUM(all_conversions - view_through_conversions) formula
- FTDA/MTDA = conversion monetary values
- 10 conversion_action_name values filtered (fewer than Keywords_Conv which has 21)

### 2.2 Search Query Match Types

**What**: How the user's actual search query matched the advertiser's keyword.
**Columns Involved**: query_targeting_status, query_match_type_with_variant
**Rules**:
- EXACT = search query matched keyword exactly
- NEAR_EXACT = close variant of exact match (e.g., plural, typo)
- NEAR_PHRASE = close variant of phrase match
- PHRASE = search query contains keyword phrase
- BROAD = broad match (loosely related)
- Both columns map from same Fivetran field (search_term_match_type) — functionally identical

### 2.3 Monthly Grain & Window

**What**: Monthly aggregation with 4-month rolling window.
**Columns Involved**: month
**Rules**:
- month column is a date representing first-of-month (e.g., '2023-05-01')
- DELETE WHERE month < first-of-month one year ago (annual floor)
- DELETE WHERE month >= 4 months back AND < first-of-next-month (refresh window)
- INSERT for 4-month window from Fivetran source
- Longer window than daily tables (4 months vs 90 days) due to monthly grain

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(customer_id) distribution — optimal for JOINs on customer_id. CLUSTERED INDEX on month ASC for time-range scans. This is the only hash-distributed table in the Adwords cluster.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top search queries by FTD | GROUP BY query ORDER BY SUM(FTD) DESC |
| Match type distribution | GROUP BY query_targeting_status |
| Landing page conversion effectiveness | GROUP BY final_url |
| Search intent analysis by language | Filter query column by language-specific terms |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign metadata |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group metadata |
| BI_DB_Adwords_Search_Perf | month, customer_id, query, device, query_match_type_with_variant, ad_group_id | Combine search query conversions + performance (impressions, clicks, cost) |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-05-01 to 2023-08-01.
- **Monthly grain** — unlike other Adwords tables which are daily. Cannot drill to day-level.
- **keyword_id and search_key are always NULL** — in DDL but SP comments them out.
- **query_targeting_status and query_match_type_with_variant are identical** — both map from search_term_match_type. Redundant columns.
- **external_customer_id = customer_id** — redundant duplicate.
- **final_url contains full URLs** — e.g., 'https://www.etoro.com/en-us/', 'https://go.etoro.com/en/evergreen-stocks'. Mapped from ad_final_urls.
- **No 2nd-gen app columns** — unlike Ad_Conv and Keywords_Conv.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 4 | Inferred — column not populated by SP | DDL only |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | month | nvarchar(256) | YES | First-of-month date string (e.g., '2023-05-01'). Time grain for this table — monthly, not daily. Passthrough from Fivetran. Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | customer_id | bigint | NO | Google Ads customer account ID. Hash distribution key for this table. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | query | nvarchar(256) | YES | Actual user search query that triggered the ad. Mapped from Fivetran search_term. Multi-language (e.g., 'robinhood option', 'investimenti in borsa'). (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET. Part of row grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | query_targeting_status | nvarchar(256) | YES | How the search query matched the keyword. EXACT, NEAR_EXACT, NEAR_PHRASE, PHRASE, BROAD. Mapped from search_term_match_type. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | query_match_type_with_variant | nvarchar(256) | YES | Identical to query_targeting_status — both map from search_term_match_type. Redundant column kept for backward compatibility. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | keyword_id | bigint | YES | Google Ads keyword ID that the search query matched. NOT populated — SP comments out this column. Always NULL. (Tier 4 — inferred from DDL) |
| 9 | account_currency_code | nvarchar(256) | YES | Google Ads account currency. Mapped from Fivetran customer_currency_code. Typically 'USD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | final_url | nvarchar(256) | YES | Landing page URL that the ad linked to. Mapped from Fivetran ad_final_urls. Contains full URLs like 'https://www.etoro.com/en-us/'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | search_key | nvarchar(1340) | YES | Composite search key. NOT populated — SP comments out this column. Originally: ad_group_id + device + month + search_term + keyword_id + match_type concatenation. Always NULL. (Tier 4 — inferred from DDL) |
| 14 | Registration | float | YES | Click-through registration conversions for this search query. SUM(all_conversions - view_through_conversions) WHERE 'Registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | V2 | float | YES | Click-through V2 verification conversions. SUM WHERE 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | FTD | float | YES | Click-through first-time deposit conversions. SUM WHERE 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | MultipleDeposit | float | YES | Click-through multiple deposit conversions. SUM WHERE 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | FTDA | float | YES | FTD conversion monetary value. SUM(all_conversions_value) WHERE 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | MTDA | float | YES | Multiple deposit conversion monetary value. SUM(all_conversions_value) WHERE 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted (GETDATE()). (Tier 5 — ETL infrastructure) |
| 21 | android_reg | float | YES | 1st-gen Android app registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | android_v2 | float | YES | 1st-gen Android app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | android_ftd | float | YES | 1st-gen Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | ios_reg | float | YES | 1st-gen iOS app registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | ios_v2 | float | YES | 1st-gen iOS app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | ios_ftd | float | YES | 1st-gen iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| month, customer_id, device, campaign_id, ad_group_id | Fivetran Google Ads | Same | Passthrough |
| query | Fivetran Google Ads | search_term | Rename |
| query_targeting_status | Fivetran Google Ads | search_term_match_type | Rename |
| query_match_type_with_variant | Fivetran Google Ads | search_term_match_type | Rename (duplicate) |
| external_customer_id | Fivetran Google Ads | customer_id | Duplicate |
| account_currency_code | Fivetran Google Ads | customer_currency_code | Rename |
| final_url | Fivetran Google Ads | ad_final_urls | Rename |
| Registration..MTDA | Fivetran Google Ads | conversion_action_name pivot | CASE WHEN + SUM |
| android_*/ios_* | Fivetran Google Ads | conversion_action_name (app) | CASE WHEN + SUM |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_search_conv_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #10, P99) ---|
  |   DELETE old (>1yr) + DELETE 4-month overlap + INSERT with CASE WHEN pivot
  |   GROUP BY month, customer_id, search_term, device, match_type, currency, campaign_id, ad_group_id, ad_final_urls
  v
BI_DB_dbo.BI_DB_Adwords_Search_Conv (12,992 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata |

### 6.2 Referenced By (other objects point to this)

No known consumers. Terminal reporting table paired with Search_Perf.

---

## 7. Sample Queries

### 7.1 Top Search Queries by FTD

```sql
SELECT query, query_targeting_status,
       SUM(FTD) AS ftds, SUM(FTDA) AS ftd_value,
       SUM(Registration) AS regs
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Conv]
GROUP BY query, query_targeting_status
HAVING SUM(FTD) > 0
ORDER BY ftds DESC
```

### 7.2 Landing Page Conversion Analysis

```sql
SELECT final_url,
       SUM(Registration) AS regs, SUM(FTD) AS ftds
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Conv]
WHERE final_url IS NOT NULL
GROUP BY final_url
ORDER BY ftds DESC
```

### 7.3 Match Type Effectiveness

```sql
SELECT query_targeting_status,
       COUNT(DISTINCT query) AS unique_queries,
       SUM(Registration) AS total_regs, SUM(FTD) AS total_ftds
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Conv]
GROUP BY query_targeting_status
ORDER BY total_ftds DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 22 T2, 0 T3, 2 T4, 1 T5 | Elements: 26/26, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Search_Conv | Type: Table | Production Source: Fivetran Google Ads*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_Adwords_Pref_Conv`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Adwords_Pref_Conv.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_Adwords_Pref_Conv] @date [DATE] AS   
       
/********************************************************************************************        
Author:      Amir G         
Date:        2021-02-22        
Description: collects the Google Tables from Fivetran 
        
**************************        
** Change History        
**************************        
Date         Author       Description         
2021-03-01   Amir          Change @FromDate
2021-04-05   Amir         Adding 4 columns:
                         1.Conversions into dbo.BI_DB_Adwords_Geo_Pref
								 2.Conversions into dbo.BI_DB_Adwords_Ad_Pref
								 3.Conversions into  dbo.BI_DB_Adwords_Keywords_Pref
								 4.KeywordMatchType into  dbo.BI_DB_Adwords_Keywords_Pref
2021-05-16  Amir         Add Column to  BI_DB_Adwords_Dictionary_AdGroup
2021-05-30  Amir         Add Column to  BI_DB_Adwords_Dictionary_Campaign
2021-08-23  Amir         Remove Column region_criteria_id
2021-11-18  Chen         1. Add 4 columns to BI_DB_Adwords_Ad_Pref (VideoQuartile25Rate, VideoQuartile50Rate, VideoQuartile75Rate, VideoQuartile100Rate)
						 2. Import 4 additional tables: 
						    adwords.campaign_performance_report 
						    adwords.conversion_performance_report
						    adwords_search_perf.perf_search_query_performance_report
							adwords_search_conv.conv_search_query_performance_report
						 3. Limit the historical data of all tables to a year back (exc. dictionary tables)
2022-04-24 Eyal Boas	 Add "new_api" suffix to all Finetran schemas	
2022-05-10 Jan Iablunovskey	Add 6 columns :
                                 eToro - Invest in stocks, crypto & trade CFDs (Android) registration
                                 eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2
                                 eToro - Invest in stocks, crypto & trade CFDs (Android) FTD
                                 eToro Cryptocurrency Trading (iOS) registration
                                 eToro Cryptocurrency Trading (iOS) Verification Level - 2
                                 eToro Cryptocurrency Trading (iOS) FTD
								Into :
								 BI_DB_Adwords_Ad_Conv
								 BI_DB_Adwords_Keywords_Conv
								 BI_DB.dbo.BI_DB_Adwords_Geo_Conv
                                 BI_DB.dbo.BI_DB_Adwords_Search_Conv
2022-05-17 Jan Iablunovskey Add columns : - ad_name
                                          - responsive_search_ad_headlines
                                          - responsive_search_ad_descriptions
							to BI_DB_Adwords_Ad_Pref
2022-07-14    Eti          add columns LTV_Count, LTV_Value to table BI_DB_Adwords_Keywords_Conv
2022-07-19    Eti          add column KeywordMatchType to table BI_DB_Adwords_Keywords_Conv and adding filter conversion_action_name in tables
                           BI_DB_Adwords_Keywords_Conv / BI_DB_Adwords_Ad_Conv / BI_DB_Adwords_Conversion_Performance_Report
2023-09-12    Chen		   Migration to Synapse
----------    ----------   ------------------------------------*/        
 
  
BEGIN  

--DECLARE @date DATE = CAST(GETDATE()-1 as date)
DECLARE @Today DATE = DATEADD(DAY,1,@date)
DECLARE @FromDate DATE = DATEADD(DAY,-90,@date)
DECLARE @FirstDayOfMonthYearAgo DATE = cast(DATEADD(year,-1,DATEADD(month, DATEDIFF(month, 0, @date), 0)) AS date)
DECLARE @FromMonth DATE = CAST(DATEADD(MONTH,-4,DATEADD(month, DATEDIFF(month, 0, @date), 0)) AS DATE)
DECLARE @FirstDayOfNextMonth DATE = DATEADD(DAY,1,EOMONTH(@date))

/***********Table #1 **************************/

DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Geo_Pref WHERE date < @FirstDayOfMonthYearAgo
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Geo_Pref WHERE date >= @FromDate AND  date < @Today

INSERT INTO  [BI_DB_dbo].BI_DB_Adwords_Geo_Pref
(date  
,DateID
,customer_id  
,impressions 
,ad_group_status 
,campaign_status
,device
,campaign_name 
,ad_group_name
,video_views
,cost
,external_customer_id
,region_criteria_id
,campaign_id
,interactions
,ad_group_id
,clicks
,country_criteria_id
,week
,UpdateDate
,Conversions
)  
SELECT  date 
       ,[BI_DB_dbo].DateToDateID(date)
       ,customer_id  
       ,impressions 
       ,ad_group_status 
       ,campaign_status
       ,device 
       ,campaign_name 
       ,ad_group_name
       ,video_views
       ,cost_micros
       ,customer_id
       ,NULL --region_criteria_id
       ,campaign_id
       ,interactions
       ,ad_group_id
       ,clicks
       ,country_criterion_id
       ,week 
		 ,GETDATE() AS UpdateDate
		 ,conversions
FROM  [BI_DB_dbo].[External_Bronze_Fivetran_adwords_geo_perf_new_api_perf_geo_performance_report]
 WHERE date < @Today
 AND  date >= @FromDate 

/***********Table #2 **************************/
 
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Ad_Pref WHERE date < @FirstDayOfMonthYearAgo 
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Ad_Pref WHERE date >= @FromDate AND date < @Today

INSERT INTO  [BI_DB_dbo].BI_DB_Adwords_Ad_Pref
(date
,DateID
,customer_id 
,description
,ad_type
,video_views
,cost
,accent_color  
,description_2  
,description_1  
,headline_part_1 
,campaign_id 
,headline_part_2
,headline 
,combined_approval_status 
,status
,impressions
,device
,creative_final_urls
,labels
,external_customer_id
,expanded_text_ad_headline_part_3
,interactions
,id
,ad_group_id
,clicks
,expanded_text_ad_description_2 
,UpdateDate
,Conversions
,video_quartile_25_rate
,video_quartile_50_rate
,video_quartile_75_rate
,video_quartile_100_rate
,ad_name 
,responsive_search_ad_headlines 
,responsive_search_ad_descriptions
)  
SELECT  date
       ,[BI_DB_dbo].DateToDateID(date)
       ,customer_id 
       ,expanded_text_ad_description
       ,ad_type
       ,video_views
       ,cost_micros
       ,legacy_responsive_display_ad_accent_color  
       ,expanded_text_ad_description_2  
       ,expanded_text_ad_description  
       ,expanded_text_ad_headline_part_1 
       ,campaign_id 
       ,expanded_text_ad_headline_part_2
       ,expanded_text_ad_headline_part_3 
       ,policy_summary_approval_status 
       ,status
       ,impressions
       ,device
       ,ad_final_urls
       ,labels
       ,customer_id
       ,expanded_text_ad_headline_part_3
       ,interactions
       ,ad_id
       ,ad_group_id
       ,clicks
       ,expanded_text_ad_description_2 
	   ,GETDATE() AS UpdateDate
	   ,conversions
	   ,video_quartile_p_25_rate
	   ,video_quartile_p_50_rate
	   ,video_quartile_p_75_rate
	   ,video_quartile_p_100_rate
	   ,ad_name 
       ,responsive_search_ad_headlines 
       ,responsive_search_ad_descriptions
FROM [BI_DB_dbo].[External_Bronze_Fivetran_adwords_ad_perf_new_api_perf_ad_performance_report]
 WHERE date < @Today
  AND  date >= @FromDate 


 /***********Table #3 **************************/

DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Keywords_Pref WHERE date < @FirstDayOfMonthYearAgo 
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Keywords_Pref WHERE date >= @FromDate AND date < @Today

INSERT INTO  [BI_DB_dbo].BI_DB_Adwords_Keywords_Pref
(date 
,DateID
,customer_id  
,status 
,impressions
,quality_score 
,device
,criteria 
,video_views
,cost 
,external_customer_id 
,search_budget_lost_top_impression_share 
,account_currency_code
,campaign_id
,interactions 
,search_impression_share  
--,id
,ad_group_id
,clicks 
,search_rank_lost_impression_share 
,week  
,UpdateDate 
,Conversions
,KeywordMatchType
)  
SELECT  date 
       ,[BI_DB_dbo].DateToDateID(date)
       ,customer_id  
       ,ad_group_criterion_status 
       ,impressions
       ,quality_info_quality_score 
       ,device
       ,keyword_text 
       ,video_views
       ,cost_micros 
       ,customer_id 
       ,search_budget_lost_top_impression_share 
       ,customer_currency_code
       ,campaign_id
       ,interactions 
       ,search_impression_share  
       --,id
       ,ad_group_id
       ,clicks 
       ,search_rank_lost_impression_share 
       ,week 
		 ,GETDATE() AS UpdateDate
		 ,conversions
		 ,keyword_match_type

FROM [BI_DB_dbo].[External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report]
 WHERE date < @Today
  AND  date >= @FromDate 

 /***********Table #4 **************************/

DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Geo_Conv WHERE date < @FirstDayOfMonthYearAgo 
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Geo_Conv WHERE date >= @FromDate AND date < @Today 

INSERT INTO  [BI_DB_dbo].BI_DB_Adwords_Geo_Conv
(date  
,DateID
,customer_id  
,device  
,external_customer_id
,region_criteria_id  
,campaign_id 
,ad_group_id 
,country_criteria_id 
,week  
,Registration 
,V2 
,FTD 
,MultipleDeposit
,FTDA
,MTDA
,UpdateDate 
,android_reg
,android_v2
,android_ftd
,ios_reg
,ios_v2
,ios_ftd
)  
SELECT  date  
       ,[BI_DB_dbo].DateToDateID(date)
       ,customer_id  
       ,device  
       ,customer_id
       ,NULL --region_criteria_id  
       ,campaign_id 
       ,ad_group_id 
       ,country_criterion_id 
       ,week  
       ,SUM(CASE WHEN conversion_action_name = 'Registration'     THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Registration 
       ,SUM(CASE WHEN conversion_action_name = 'V2 Status'        THEN (all_conversions - view_through_conversions) ELSE 0 END) AS V2 
       ,SUM(CASE WHEN conversion_action_name = 'FTD'              THEN (all_conversions - view_through_conversions) ELSE 0 END) AS FTD 
       ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS MultipleDeposit 
		 ,SUM(CASE WHEN conversion_action_name = 'FTD'              THEN all_conversions_value ELSE 0 END) AS FTDA 
       ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit' THEN all_conversions_value ELSE 0 END) AS MTDA 
		 ,GETDATE() AS UpdateDate
		 ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_reg 
       ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2'   THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_v2
       ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD'  THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_ftd
       ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) registration' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_reg
	   ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) Verification Level - 2'     THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_v2
       ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) FTD' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_ftd
FROM  [BI_DB_dbo].[External_Bronze_Fivetran_adwords_geo_conv_new_api_conv_geo_performance_report]
  WHERE date < @Today
  AND  date >= @FromDate 
  AND conversion_action_name IN('Registration','V2 Status','FTD','Multiple Deposit',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) registration',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD',
   'eToro Cryptocurrency Trading (iOS) registration',
   'eToro Cryptocurrency Trading (iOS) Verification Level - 2',
   'eToro Cryptocurrency Trading (iOS) FTD')
 GROUP BY date  
       ,customer_id  
       ,device  
       ,customer_id
     --  ,region_criteria_id  
       ,campaign_id 
       ,ad_group_id 
       ,country_criterion_id 
       ,week  
	
		 
/***********Table #5 **************************/


DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Ad_Conv WHERE date < @FirstDayOfMonthYearAgo 
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Ad_Conv WHERE date >= @FromDate AND date < @Today

INSERT INTO  [BI_DB_dbo].BI_DB_Adwords_Ad_Conv
(date  
,DateID
,customer_id 
,campaign_id 
,device 
,id 
,ad_group_id 
,week 
,external_customer_id 
,Registration
,V2
,FTD 
,MultipleDeposit
,FTDA
,MTDA
,UpdateDate 
,android_reg
,android_v2
,android_ftd
,ios_reg
,ios_v2
,ios_ftd
,Regs_IOS2
,V2_IOS2
,FTD_IOS2
,Regs_Android2 
,V2_android2
,FTD_Android2
)  
SELECT  date  
       ,[BI_DB_dbo].DateToDateID(date)
       ,customer_id 
       ,campaign_id 
       ,device 
       ,ad_id 
       ,ad_group_id 
       ,week 
       ,customer_id 
       ,SUM(CASE WHEN conversion_action_name = 'Registration'     THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Registration 
       ,SUM(CASE WHEN conversion_action_name = 'V2 Status'        THEN (all_conversions - view_through_conversions) ELSE 0 END) AS V2 
       ,SUM(CASE WHEN conversion_action_name = 'FTD'              THEN (all_conversions - view_through_conversions) ELSE 0 END) AS FTD 
       ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS MultipleDeposit
	   ,SUM(CASE WHEN conversion_action_name = 'FTD'              THEN all_conversions_value ELSE 0 END) AS FTDA 
       ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit' THEN all_conversions_value ELSE 0 END) AS MTDA 
	   ,GETDATE() AS UpdateDate
	   ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_reg 
       ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2'   THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_v2
       ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD'  THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_ftd
       ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) registration' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_reg
	   ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) Verification Level - 2'     THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_v2
       ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) FTD' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_ftd
	   ,SUM(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) registration' THEN all_conversions-view_through_conversions END) AS Regs_IOS2
       ,SUM(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) Verification Level - 2' THEN all_conversions-view_through_conversions END) AS V2_IOS2
       ,SUM(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) FTD' THEN all_conversions-view_through_conversions END) AS FTD_IOS2
       ,SUM(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) registration' THEN all_conversions-view_through_conversions END) AS Regs_Android2
       ,SUM(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) Verification Level - 2' THEN all_conversions-view_through_conversions END) AS V2_android2
       ,SUM(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) FTD' THEN all_conversions-view_through_conversions END) AS FTD_Android2
FROM [BI_DB_dbo].[External_Fivetran_adwords_ad_conv_new_api_conv_ad_performance_report]
WHERE date < @Today
   AND  date >= @FromDate 
   AND conversion_action_name IN ('Registration','V2 Status','FTD','LTV-30Day','Multiple Deposit',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) registration',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD',
   'eToro Cryptocurrency Trading (iOS) registration',
   'eToro Cryptocurrency Trading (iOS) Verification Level - 2',
   'eToro Cryptocurrency Trading (iOS) FTD',
   'eToro: Crypto. Stocks. Social. (iOS) Redeposit',
   'eToro: Crypto. Stocks. Social. (iOS) FTD',
   'eToro: Crypto. Stocks. Social. (iOS) registration',
   'eToro: Crypto. Stocks. Social. (iOS) Verification Level - 2',
   'eToro: Investing made social (Android) registration',
   'eToro: Investing made social (Android) Verification Level - 2',
   'eToro: Investing made social (Android) FTD',
   'eToro: Investing made social (Android) Redeposit')
 GROUP BY date  
       ,customer_id 
       ,campaign_id 
       ,device 
       ,ad_id 
       ,ad_group_id 
       ,week 
       ,customer_id

/***********Table #6 **************************/

DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Keywords_Conv WHERE date < @FirstDayOfMonthYearAgo 
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Keywords_Conv WHERE date >= @FromDate AND date < @Today

INSERT INTO  [BI_DB_dbo].BI_DB_Adwords_Keywords_Conv
(date 
,DateID
,customer_id  
,status 
,device 
,criteria 
,external_customer_id 
,account_currency_code  
,campaign_id 
--,id   
,ad_group_id 
,week
,KeywordMatchType
,Registration 
,V2 
,FTD 
,MultipleDeposit 
,FTDA
,MTDA
,UpdateDate 
,android_reg
,android_v2
,android_ftd
,ios_reg
,ios_v2
,ios_ftd
,LTV_Count
,LTV_Value
,Regs_IOS2
,V2_IOS2
,FTD_IOS2
,Regs_Android2 
,V2_android2
,FTD_Android2
,OpenTrade_And
,OpenTrade_iOS
,OpenTrade_iOS2
,OpenTrade
)  
SELECT date 
       ,[BI_DB_dbo].DateToDateID(date)
       ,customer_id  
       ,ad_group_criterion_status 
       ,device 
       ,keyword_text 
       ,customer_id 
       ,customer_currency_code  
       ,campaign_id 
       --,ad_id   
       ,ad_group_id 
       ,week
	   ,keyword_match_type
       ,SUM(CASE WHEN conversion_action_name = 'Registration'     THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Registration 
       ,SUM(CASE WHEN conversion_action_name = 'V2 Status'        THEN (all_conversions - view_through_conversions) ELSE 0 END) AS V2 
       ,SUM(CASE WHEN conversion_action_name = 'FTD'              THEN (all_conversions - view_through_conversions) ELSE 0 END) AS FTD 
       ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS MultipleDeposit 
	   ,SUM(CASE WHEN conversion_action_name = 'FTD'              THEN all_conversions_value ELSE 0 END) AS FTDA 
       ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit' THEN all_conversions_value ELSE 0 END) AS MTDA 
	   ,GETDATE() AS UpdateDate
	   ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_reg 
       ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2'   THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_v2
       ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD'  THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_ftd
       ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) registration' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_reg
	   ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) Verification Level - 2'     THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_v2
       ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) FTD' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_ftd
	   ,sum(CASE WHEN conversion_action_name ='LTV-30Day' THEN (all_conversions-view_through_conversions) ELSE 0 END) AS LTV_Count
	   ,sum(CASE WHEN conversion_action_name ='LTV-30Day' THEN (all_conversions_value) ELSE 0 END) AS LTV_Value
	   ,sum(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) registration'  THEN all_conversions-view_through_conversions END) AS Regs_IOS2
      ,sum(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) Verification Level - 2'  THEN all_conversions-view_through_conversions END) AS V2_IOS2
      ,sum(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) FTD'  THEN all_conversions-view_through_conversions END) AS FTD_IOS2
      ,sum(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) registration'   THEN all_conversions-view_through_conversions END) AS Regs_Android2
      ,sum(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) Verification Level - 2'   THEN all_conversions-view_through_conversions END) AS V2_android2
      ,sum(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) FTD'    THEN all_conversions-view_through_conversions END) AS FTD_Android2
	  ,sum(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) Open Trade' THEN all_conversions-view_through_conversions END) AS OpenTrade_And
	  ,sum(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) Open Trade' THEN all_conversions-view_through_conversions END) AS OpenTrade_iOS
	  ,sum(CASE WHEN conversion_action_name ='eToro: Investing made social (iOS) Open Trade' THEN all_conversions-view_through_conversions END) AS OpenTrade_iOS2
	  ,sum(CASE WHEN conversion_action_name ='Open Trade' THEN all_conversions-view_through_conversions END) AS OpenTrade
FROM [BI_DB_dbo].[External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report]
  WHERE date < @Today
   AND  date >= @FromDate 
   AND conversion_action_name IN('Registration','V2 Status','FTD','LTV-30Day','Multiple Deposit',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) registration',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD',
   'eToro Cryptocurrency Trading (iOS) registration',
   'eToro Cryptocurrency Trading (iOS) Verification Level - 2',
   'eToro Cryptocurrency Trading (iOS) FTD',
   'eToro: Crypto. Stocks. Social. (iOS) Redeposit',
   'eToro: Crypto. Stocks. Social. (iOS) FTD',
   'eToro: Crypto. Stocks. Social. (iOS) registration',
   'eToro: Crypto. Stocks. Social. (iOS) Verification Level - 2',
   'eToro: Investing made social (Android) registration',
   'eToro: Investing made social (Android) Verification Level - 2',
   'eToro: Investing made social (Android) FTD',
   'eToro: Investing made social (Android) Redeposit',
   'eToro: Investing made social (Android) Open Trade',
   'eToro: Crypto. Stocks. Social. (iOS) Open Trade',
   'eToro: Investing made social (iOS) Open Trade',
   'Open Trade')
 GROUP BY date 
       ,customer_id  
       ,ad_group_criterion_status 
       ,device 
       ,keyword_text 
       ,customer_id 
       ,customer_currency_code  
       ,campaign_id 
       --,ad_id   
       ,ad_group_id 
       ,week
	   ,keyword_match_type
	   

/***********Table #7 **************************/

DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Campaign_Performance_Report WHERE date < @FirstDayOfMonthYearAgo
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Campaign_Performance_Report WHERE date >= @FromDate AND date < @Today

INSERT INTO [BI_DB_dbo].BI_DB_Adwords_Campaign_Performance_Report
		   ([date]
		   ,[DateID]
		   ,[impressions]
		   ,[campaign_status]
		   ,[campaign_id]
		   --,[average_position]
		   ,[campaign_name]
		   ,[search_impression_share]
		   ,[clicks]
		   ,[cost]
		   ,[all_conversions]
		   ,[device]
		   ,[customer_id]
		   ,[labels]
		   ,[video_views]
		   ,[interactions]
		   ,[UpdateDate] 
		   )

SELECT [date]
	  ,[BI_DB_dbo].DateToDateID(date) AS DateID
	  ,[impressions]
      ,[status]
      ,[id]
      --,[average_position]
      ,[name]
      ,[search_impression_share]
      ,[clicks]
      ,[cost_micros]
      ,[all_conversions]
      ,[device]
      ,[customer_id]
      ,[labels]
      ,[video_views]
      ,[interactions]
	  ,GETDATE() AS UpdateDate
FROM  [BI_DB_dbo].[External_Bronze_Fivetran_adwords_new_api_campaign_performance_report]
WHERE date >= @FromDate and date < @Today


/***********Table #8 **************************/

DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Conversion_Performance_Report WHERE date < @FirstDayOfMonthYearAgo
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Conversion_Performance_Report WHERE date >= @FromDate AND date < @Today

INSERT INTO [BI_DB_dbo].BI_DB_Adwords_Conversion_Performance_Report
           ([date]
		   ,[DateID]
		   ,[campaign_id]
           ,[campaign_name]
           ,[customer_id]
           ,[labels]
		   ,Device
		   ,Registration
		   ,V2
		   ,FTD
		   ,MultipleDeposit
		   ,Android_FirstOpen
		   ,Android_FTD
		   ,Android_Redeposit
		   ,Android_Registration
		   ,Android_V2
		   ,iOS_FirstOpen
		   ,iOS_FTD
		   ,iOS_Redeposit
		   ,iOS_Registration
		   ,iOS_V2
		   ,Regs_IOS2
           ,V2_IOS2
	       ,FTD_IOS2
	       ,Regs_Android2 
	       ,V2_android2
	       ,FTD_Android2
		   ,[UpdateDate]
		   )

SELECT [date]
	  ,[BI_DB_dbo].DateToDateID(date) AS DateID
	  ,[id]
      ,[name]
      ,[customer_id]
      ,[labels]
	  ,device
	  ,SUM(CASE WHEN conversion_action_name = 'Registration'																	 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Registration
      ,SUM(CASE WHEN conversion_action_name = 'V2 Status'																		 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS V2
      ,SUM(CASE WHEN conversion_action_name = 'FTD'																			 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS FTD
      ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit'																 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS MultipleDeposit
	  ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) first_open'			 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Android_FirstOpen
	  ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD'					 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Android_FTD
	  ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) Redeposit'				 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Android_Redeposit
	  ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration'			 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Android_Registration
	  ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Android_V2
	  ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) first_open'									 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS iOS_FirstOpen
	  ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) FTD'										 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS iOS_FTD
	  ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) Redeposit'									 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS iOS_Redeposit
	  ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) registration'								 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS iOS_Registration
	  ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) Verification Level - 2'						 THEN (all_conversions - view_through_conversions) ELSE 0 END) AS iOS_V2
	  ,SUM(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) registration' THEN all_conversions-view_through_conversions END) AS Regs_IOS2
      ,SUM(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) Verification Level - 2' THEN all_conversions-view_through_conversions END) AS V2_IOS2
      ,SUM(CASE WHEN conversion_action_name ='eToro: Crypto. Stocks. Social. (iOS) FTD' THEN all_conversions-view_through_conversions END) AS FTD_IOS2
      ,SUM(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) registration' THEN all_conversions-view_through_conversions END) AS Regs_Android2
      ,SUM(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) Verification Level - 2' THEN all_conversions-view_through_conversions END) AS V2_android2
      ,SUM(CASE WHEN conversion_action_name ='eToro: Investing made social (Android) FTD' THEN all_conversions-view_through_conversions END) AS FTD_Android2
	  ,GETDATE() AS UpdateDate
FROM  [BI_DB_dbo].[External_Bronze_Fivetran_adwords_new_api_conversion_performance_report]
WHERE date >= @FromDate and date < @Today
	AND conversion_action_name IN ('Registration','V2 Status','FTD','LTV-30Day','Multiple Deposit',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) registration',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD',
   'eToro Cryptocurrency Trading (iOS) registration',
   'eToro Cryptocurrency Trading (iOS) Verification Level - 2',
   'eToro Cryptocurrency Trading (iOS) FTD',
   'eToro: Crypto. Stocks. Social. (iOS) Redeposit',
   'eToro: Crypto. Stocks. Social. (iOS) FTD',
   'eToro: Crypto. Stocks. Social. (iOS) registration',
   'eToro: Crypto. Stocks. Social. (iOS) Verification Level - 2',
   'eToro: Investing made social (Android) registration',
   'eToro: Investing made social (Android) Verification Level - 2',
   'eToro: Investing made social (Android) FTD',
   'eToro: Investing made social (Android) Redeposit')
GROUP BY [date]
	  ,[BI_DB_dbo].DateToDateID(date)
	  ,[id]
      ,[name]
      ,[customer_id]
      ,[labels]
	  ,device

/***********Table #9 *************************/


IF OBJECT_ID('tempdb..#search_perf_prep') IS NOT NULL DROP TABLE #search_perf_prep
CREATE TABLE #search_perf_prep
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT [date]
	  ,[month]
	  ,[search_term] query
      ,[device]
      ,[customer_id]
      ,[search_term_match_type] query_match_type_with_variant
      ,[customer_currency_code]
      ,[ad_group_id]
	  ,[impressions]
      ,[clicks]
	  ,[cost_micros]
	  ,[top_impression_percentage] * [impressions] AS top_impressions
FROM [BI_DB_dbo].[External_Bronze_Fivetran_adwords_search_perf_new_api_perf_search_query_performance_report]
WHERE [month] >= @FromMonth and [month] < @FirstDayOfNextMonth


DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Search_Perf WHERE [month] < @FirstDayOfMonthYearAgo
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Search_Perf WHERE [month] >= @FromMonth AND [month] < @FirstDayOfNextMonth

INSERT INTO [BI_DB_dbo].BI_DB_Adwords_Search_Perf
           ([month]
		   ,[customer_id]
           ,[query]
           ,[device]
           ,[external_customer_id]
           ,[query_match_type_with_variant]
           ,[account_currency_code]
           ,[ad_group_id]
		   ,[impressions]
		   ,[top_impressions]
           ,[clicks]
		   ,[cost]
		   ,[UpdateDate]
           )
SELECT [month]
	  ,[customer_id]
      ,[query]
      ,[device]
      ,[customer_id]
      ,[query_match_type_with_variant]
      ,[customer_currency_code]
      ,[ad_group_id]
	  ,SUM([impressions]) AS [impressions]
	  ,SUM([top_impressions]) AS [top_impressions]
      ,SUM([clicks]) AS [clicks]
	  ,SUM([cost_micros]) AS [cost]
	  ,GETDATE() AS UpdateDate
FROM #search_perf_prep
GROUP BY [month]
	  ,[customer_id]
      ,[query]
      ,[device]
      ,[customer_id]
      ,[query_match_type_with_variant]
      ,[customer_currency_code]
      ,[ad_group_id]

/***********Table #10 **************************/

DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Search_Conv WHERE [month] < @FirstDayOfMonthYearAgo
DELETE FROM [BI_DB_dbo].BI_DB_Adwords_Search_Conv WHERE [month] >= @FromMonth AND [month] < @FirstDayOfNextMonth

INSERT INTO [BI_DB_dbo].BI_DB_Adwords_Search_Conv
           ([month]
		   ,[customer_id]
           ,[query]
           ,[device]
           ,[query_targeting_status]
           ,[external_customer_id]
           ,[query_match_type_with_variant]
           --,[keyword_id]
           ,[account_currency_code]
           ,[campaign_id]
           ,[ad_group_id]
           ,[final_url]
		   --,[search_key]
		   ,[Registration]
		   ,[V2]
		   ,[FTD] 
		   ,[MultipleDeposit]
		   ,[FTDA]
		   ,[MTDA]
		   ,[UpdateDate]
		   ,android_reg
           ,android_v2
           ,android_ftd
           ,ios_reg
           ,ios_v2
           ,ios_ftd
		   )

SELECT [month]
	  ,[customer_id]
      ,[search_term]
      ,[device]
      ,[search_term_match_type]
      ,[customer_id]
      ,[search_term_match_type]
      --,[keyword_id]
      ,[customer_currency_code]
      ,[campaign_id]
      ,[ad_group_id]
      ,[ad_final_urls]
	  --,CAST([ad_group_id] AS VARCHAR)+[device]+[month]+[search_term]+CAST([keyword_id] AS VARCHAR)+[search_term_match_type]+[[earch_term_match_type] AS [search_key] 
	  ,SUM(CASE WHEN conversion_action_name = 'Registration'     THEN (all_conversions - view_through_conversions) ELSE 0 END) AS Registration
      ,SUM(CASE WHEN conversion_action_name = 'V2 Status'        THEN (all_conversions - view_through_conversions) ELSE 0 END) AS V2
      ,SUM(CASE WHEN conversion_action_name = 'FTD'              THEN (all_conversions - view_through_conversions) ELSE 0 END) AS FTD
      ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS MultipleDeposit
	  ,SUM(CASE WHEN conversion_action_name = 'FTD'              THEN all_conversions_value ELSE 0 END) AS FTDA
      ,SUM(CASE WHEN conversion_action_name = 'Multiple Deposit' THEN all_conversions_value ELSE 0 END) AS MTDA 
	  ,GETDATE() AS UpdateDate
	  ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_reg 
       ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2'   THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_v2
       ,SUM(CASE WHEN conversion_action_name = 'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD'  THEN (all_conversions - view_through_conversions) ELSE 0 END) AS android_ftd
       ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) registration' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_reg
	   ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) Verification Level - 2'     THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_v2
       ,SUM(CASE WHEN conversion_action_name = 'eToro Cryptocurrency Trading (iOS) FTD' THEN (all_conversions - view_through_conversions) ELSE 0 END) AS ios_ftd
FROM  [BI_DB_dbo].[External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report]
WHERE [month] >= @FromMonth AND [month] < @FirstDayOfNextMonth
	AND 
	conversion_action_name IN('Registration','V2 Status','FTD','Multiple Deposit',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) registration',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) Verification Level - 2',
   'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD',
   'eToro Cryptocurrency Trading (iOS) registration',
   'eToro Cryptocurrency Trading (iOS) Verification Level - 2',
   'eToro Cryptocurrency Trading (iOS) FTD')
GROUP BY [month]
	  ,[customer_id]
      ,[search_term]
      ,[device]
      ,[search_term_match_type]
      ,[customer_id]
      ,[search_term_match_type]
      --,[keyword_id]
      ,[customer_currency_code]
      ,[campaign_id]
      ,[ad_group_id]
      ,[ad_final_urls]
	  --,CAST([ad_group_id] AS VARCHAR)+[device]+[month]+[search_term]+CAST([keyword_id] AS VARCHAR)+[search_term_match_type]+[search_term_match_type]


/***********************Dictionary Tables***********************************/

/******************************Table #11 **************************/

TRUNCATE TABLE [BI_DB_dbo].BI_DB_Adwords_Dictionary_Campaign

INSERT INTO [BI_DB_dbo].BI_DB_Adwords_Dictionary_Campaign
(campaign_id  
,campaign_name  
,bidding_strategy_type  
,amount
,UpdateDate 
,campaign_status
 )
 SELECT DISTINCT 
        campaign_id  
       ,campaign_name  
       ,bidding_strategy_type  
       ,amount
       ,GETDATE() AS  UpdateDate 
		 ,campaign_status
 FROM [BI_DB_dbo].[External_Bronze_Fivetran_adwords_campaign_perf_perf_campaign_performance_report]
 WHERE campaign_name IS NOT NULL

 /******************************Table #12 **************************/

TRUNCATE TABLE [BI_DB_dbo].BI_DB_Adwords_Dictionary_AdGroup

INSERT INTO [BI_DB_dbo].BI_DB_Adwords_Dictionary_AdGroup
(campaign_id  
,ad_group_id  
,ad_group_name 
,UpdateDate 
,ad_group_status
 )
 SELECT DISTINCT 
        campaign_id  
       ,id  
       ,name  
       ,GETDATE() AS  UpdateDate 
	   ,status
FROM [BI_DB_dbo].[External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report]
 WHERE name IS NOT NULL

END  





GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_Adwords_Pref_Conv` | synapse_sp | BI_DB_dbo | SP_Adwords_Pref_Conv | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Adwords_Pref_Conv.sql` |
| `BI_DB_dbo.BI_DB_Adwords_Geo_Pref` | synapse | BI_DB_dbo | BI_DB_Adwords_Geo_Pref | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Geo_Pref.md` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_geo_perf_new_api_perf_geo_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_geo_perf_new_api_perf_geo_performance_report | `—` |
| `BI_DB_dbo.BI_DB_Adwords_Ad_Pref` | synapse | BI_DB_dbo | BI_DB_Adwords_Ad_Pref | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Ad_Pref.md` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_ad_perf_new_api_perf_ad_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_ad_perf_new_api_perf_ad_performance_report | `—` |
| `BI_DB_dbo.BI_DB_Adwords_Keywords_Pref` | synapse | BI_DB_dbo | BI_DB_Adwords_Keywords_Pref | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Keywords_Pref.md` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report | `—` |
| `BI_DB_dbo.BI_DB_Adwords_Geo_Conv` | synapse | BI_DB_dbo | BI_DB_Adwords_Geo_Conv | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Geo_Conv.md` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_geo_conv_new_api_conv_geo_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_geo_conv_new_api_conv_geo_performance_report | `—` |
| `BI_DB_dbo.BI_DB_Adwords_Ad_Conv` | synapse | BI_DB_dbo | BI_DB_Adwords_Ad_Conv | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Ad_Conv.md` |
| `BI_DB_dbo.External_Fivetran_adwords_ad_conv_new_api_conv_ad_performance_report` | unresolved | BI_DB_dbo | External_Fivetran_adwords_ad_conv_new_api_conv_ad_performance_report | `—` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report | `—` |
| `BI_DB_dbo.BI_DB_Adwords_Campaign_Performance_Report` | synapse | BI_DB_dbo | BI_DB_Adwords_Campaign_Performance_Report | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Campaign_Performance_Report.md` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_new_api_campaign_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_new_api_campaign_performance_report | `—` |
| `BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report` | synapse | BI_DB_dbo | BI_DB_Adwords_Conversion_Performance_Report | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Conversion_Performance_Report.md` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_new_api_conversion_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_new_api_conversion_performance_report | `—` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_search_perf_new_api_perf_search_query_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_search_perf_new_api_perf_search_query_performance_report | `—` |
| `BI_DB_dbo.BI_DB_Adwords_Search_Perf` | synapse | BI_DB_dbo | BI_DB_Adwords_Search_Perf | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Search_Perf.md` |
| `BI_DB_dbo.BI_DB_Adwords_Search_Conv` | synapse | BI_DB_dbo | BI_DB_Adwords_Search_Conv | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Adwords_Search_Conv.md` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report | `—` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_campaign_perf_perf_campaign_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_campaign_perf_perf_campaign_performance_report | `—` |
| `BI_DB_dbo.External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report` | unresolved | BI_DB_dbo | External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report | `—` |
