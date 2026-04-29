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
