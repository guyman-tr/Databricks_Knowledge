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
