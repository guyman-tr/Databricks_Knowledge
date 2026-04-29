# BI_DB_dbo.BI_DB_Adwords_Keywords_Pref

> **STALE DATA — last refreshed 2023-09-18.** 223,519-row Google Ads keyword-level performance metrics table. Contains impressions, clicks, cost (in micros), video views, interactions, conversions, quality score, and search impression share metrics per keyword, device, and match type. Performance counterpart to BI_DB_Adwords_Keywords_Conv (which has the funnel breakdown). Part of SP_Adwords_Pref_Conv cluster (Table #3 of 12). Date range: 2023-06-19 to 2023-09-17. Devices: DESKTOP (56%), MOBILE (41%), TABLET (3%). Match types: EXACT, PHRASE, BROAD.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report → SP_Adwords_Pref_Conv |
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

`BI_DB_Adwords_Keywords_Pref` stores **Google Ads keyword-level performance metrics** — impressions, clicks, cost, video views, interactions, conversions, and search impression share at the advertiser-defined keyword level. This is the performance/spend counterpart to `BI_DB_Adwords_Keywords_Conv` (which tracks funnel conversions: Registration, V2, FTD, MultipleDeposit, LTV, and Open Trade events). Together they enable keyword-level ROI analysis for Google Ads campaigns.

Each row represents one keyword's daily performance for a given device, match type, Google Ads account, campaign, and ad group. The table includes keyword quality scores and three search impression share metrics (total share, budget-lost share, rank-lost share) that are unique to the keyword-level tables in the Adwords cluster — enabling search visibility and budget optimization analysis.

This is Table #3 in SP_Adwords_Pref_Conv. The SP sources from Fivetran's Google Ads keywords performance report (`adwords_keywords_perf` schema), performing column renames (e.g., `keyword_text` → `criteria`, `ad_group_criterion_status` → `status`, `quality_info_quality_score` → `quality_score`, `cost_micros` → `cost`, `customer_currency_code` → `account_currency_code`, `keyword_match_type` → `KeywordMatchType`). The `id` column exists in the DDL but is commented out in the SP INSERT — always NULL.

**DATA IS STALE**: Date range 2023-06-19 to 2023-09-17. All rows have identical UpdateDate (2023-09-18 16:37:31), indicating a single bulk load. SP has not run since Synapse migration (2023-09-12). 9 Google Ads accounts, all USD.

---

## 2. Business Logic

### 2.1 Keyword Performance Metrics

**What**: Standard Google Ads performance metrics at the advertiser-defined keyword level.
**Columns Involved**: impressions, clicks, cost, video_views, interactions, Conversions
**Rules**:
- All metrics are direct passthrough from Fivetran source
- cost is renamed from cost_micros (value in Google Ads micros — divide by 1,000,000 for actual currency)
- Conversions = total conversion count (not funnel-pivoted — use Keywords_Conv for funnel breakdown)
- No aggregation in SP — direct 1:1 from Fivetran source per keyword/date/device/account row

### 2.2 Search Impression Share Metrics

**What**: Competitive visibility metrics unique to keyword-level tables.
**Columns Involved**: search_impression_share, search_budget_lost_top_impression_share, search_rank_lost_impression_share
**Rules**:
- search_impression_share = fraction of eligible impressions received (nvarchar, may need CAST)
- search_budget_lost_top_impression_share = fraction lost due to budget constraints
- search_rank_lost_impression_share = fraction lost due to ad rank
- These three metrics sum conceptually: share + budget_lost + rank_lost ≈ 1.0
- Stored as nvarchar(256) — contains string representations of decimals

### 2.3 Keyword Quality Score

**What**: Google Ads keyword quality assessment.
**Columns Involved**: quality_score
**Rules**:
- Integer 0-10. 0 = not enough data to compute. Higher = better relevance/expected CTR/landing page experience.
- Mapped from Fivetran quality_info_quality_score
- Distribution: 0 (32%), 5 (17%), 3 (15%), 7 (8%), 1 (8%)

### 2.4 Keyword Match Type Classification

**What**: Google Ads keyword matching strategy.
**Columns Involved**: KeywordMatchType
**Rules**:
- EXACT = exact keyword match (46% of rows)
- PHRASE = phrase match (45%)
- BROAD = broad match (9%)
- Mapped from Fivetran keyword_match_type
- Part of row grain — same keyword can appear with different match types

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID ASC. With 224K rows, scans are fast but date-range predicates benefit from the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top keywords by spend | `SUM(cost) / 1000000.0 GROUP BY criteria ORDER BY SUM(cost) DESC` |
| Click-through rate by keyword | `SUM(clicks) * 1.0 / NULLIF(SUM(impressions), 0) GROUP BY criteria` |
| Quality score distribution | `GROUP BY quality_score ORDER BY quality_score` |
| Budget-constrained keywords | `WHERE search_budget_lost_top_impression_share > '0' GROUP BY criteria` |
| Match type effectiveness | `GROUP BY KeywordMatchType` with SUM of impressions, clicks, cost |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Keywords_Conv | date, customer_id, device, criteria, campaign_id, ad_group_id, week, KeywordMatchType | Combine keyword performance + funnel conversion metrics for ROI analysis |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign name, bidding strategy, budget |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group name and status |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-09-17.
- **cost is in micros** — divide by 1,000,000 to get actual currency amount. The column is renamed from cost_micros in Fivetran but the value is NOT converted.
- **id is always NULL** — column exists in DDL but SP has the INSERT commented out (`--,id`).
- **external_customer_id = customer_id** — always identical, redundant duplicate.
- **search_impression_share metrics are nvarchar** — not numeric types. CAST to float for calculations.
- **quality_score = 0 means "not enough data"** — not "zero quality." 32% of rows have quality_score = 0.
- **criteria is the advertiser's keyword** — not the user's actual search query. For search queries, see BI_DB_Adwords_Search_Perf/Search_Conv.
- **KeywordMatchType is the advertiser's match setting** — not how the query actually matched. For actual match type, see Search_Perf/Search_Conv query_match_type_with_variant.

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
| 1 | date | date | NO | Google Ads report date. Calendar day for keyword performance metrics. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer. Computed by DateToDateID(date). Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer account ID. Identifies the Google Ads account. 9 distinct accounts. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | status | nvarchar(256) | YES | Ad group criterion (keyword) status. Mapped from Fivetran ad_group_criterion_status. ENABLED (99.98%), PAUSED (0.02%). (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | impressions | bigint | YES | Number of times ads were shown for this keyword. Standard Google Ads metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | quality_score | int | YES | Google Ads keyword quality score (0-10). 0 = insufficient data. Higher values indicate better keyword relevance, expected CTR, and landing page experience. Mapped from Fivetran quality_info_quality_score. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP (56%), MOBILE (41%), TABLET (3%). Part of row grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | criteria | nvarchar(256) | YES | Advertiser-defined keyword text. Mapped from Fivetran keyword_text. Contains multi-language terms (e.g., 'broker plataforma', 'Tesla Stocks', 'ibex35', 'copy trading platform'). Not the user's actual search query — see Search_Perf for that. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | video_views | bigint | YES | Number of video ad views. Standard Google Ads video metric. Passthrough from Fivetran. 0 for non-video keywords. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | cost | float | YES | Advertising cost in Google Ads micros. Renamed from Fivetran cost_micros. Divide by 1,000,000 for actual currency (e.g., 10300000.0 micros = $10.30 USD). 17% of rows have cost > 0. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. Set to customer_id in SP. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | search_budget_lost_top_impression_share | nvarchar(256) | YES | Fraction of top-of-page impressions lost due to budget constraints. String type — CAST to float for calculations. Part of the search visibility triad with search_impression_share and search_rank_lost_impression_share. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | account_currency_code | nvarchar(256) | YES | Google Ads account currency. Mapped from Fivetran customer_currency_code. All values are 'USD' in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | interactions | bigint | YES | Total interactions (clicks, video views, calls). Standard Google Ads engagement metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | search_impression_share | nvarchar(256) | YES | Fraction of eligible search impressions actually received. String type — CAST to float for calculations. Values range from 0 to 1. Only meaningful for search campaigns. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | id | bigint | YES | Keyword/criterion ID placeholder. NOT populated — SP comments out this column (`--,id`). Always NULL across all 223,519 rows. (Tier 4 — inferred from DDL) |
| 18 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | clicks | bigint | YES | Number of ad clicks for this keyword. Standard Google Ads metric. Passthrough from Fivetran. 17% of rows have clicks > 0. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | search_rank_lost_impression_share | nvarchar(256) | YES | Fraction of impressions lost due to ad rank (quality score × bid). String type — CAST to float for calculations. High values indicate need for higher bids or better quality scores. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | week | nvarchar(256) | YES | ISO week start date from Fivetran (e.g., '2023-06-19'). Used for weekly aggregation. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). All rows show 2023-09-18 16:37:31 (single bulk load). (Tier 5 — ETL infrastructure) |
| 23 | Conversions | bigint | YES | Total conversions (all types combined). Standard Google Ads metric. Passthrough from Fivetran. Unlike Keywords_Conv which breaks down by funnel stage, this is the aggregate total. 0.8% of rows have Conversions > 0. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | KeywordMatchType | nvarchar(256) | YES | Google Ads keyword match type setting. EXACT (46%), PHRASE (45%), BROAD (9%). Part of row grain. Mapped from Fivetran keyword_match_type. Added 2021-04-05 by Amir. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| date, customer_id, impressions, video_views, interactions, clicks, week | Fivetran Google Ads | Same names | Passthrough |
| DateID | Fivetran Google Ads | date | DateToDateID() |
| status | Fivetran Google Ads | ad_group_criterion_status | Rename |
| quality_score | Fivetran Google Ads | quality_info_quality_score | Rename |
| criteria | Fivetran Google Ads | keyword_text | Rename |
| cost | Fivetran Google Ads | cost_micros | Rename (value unchanged — still in micros) |
| external_customer_id | Fivetran Google Ads | customer_id | Duplicate |
| account_currency_code | Fivetran Google Ads | customer_currency_code | Rename |
| search_impression_share, search_budget_lost_top_impression_share, search_rank_lost_impression_share | Fivetran Google Ads | Same names | Passthrough |
| Conversions | Fivetran Google Ads | conversions | Passthrough |
| KeywordMatchType | Fivetran Google Ads | keyword_match_type | Rename |
| id | N/A | N/A | Not inserted (commented out in SP) |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API (keyword-level performance report)
  |-- Fivetran connector (adwords_keywords_perf_new_api schema) ---|
  v
Bronze Data Lake (ADLS Gen2 Parquet)
  |-- External Table ---|
  v
BI_DB_dbo.External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #3, P99, SB_FinanceReportSPS) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT passthrough
  |   Column renames: keyword_text→criteria, ad_group_criterion_status→status,
  |   quality_info_quality_score→quality_score, cost_micros→cost,
  |   customer_currency_code→account_currency_code, keyword_match_type→KeywordMatchType
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
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata lookup (name, bidding strategy, budget) |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata lookup (name, status) |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in SSDT. Terminal reporting table typically joined with Keywords_Conv for complete keyword-level analysis.

---

## 7. Sample Queries

### 7.1 Top Keywords by Spend and CTR

```sql
SELECT TOP 20 criteria AS keyword, KeywordMatchType,
       SUM(impressions) AS total_impressions,
       SUM(clicks) AS total_clicks,
       SUM(cost) / 1000000.0 AS total_spend_usd,
       CAST(SUM(clicks) AS FLOAT) / NULLIF(SUM(impressions), 0) AS ctr
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Pref]
WHERE impressions > 0
GROUP BY criteria, KeywordMatchType
ORDER BY total_spend_usd DESC
```

### 7.2 Quality Score vs Performance Analysis

```sql
SELECT quality_score,
       COUNT(*) AS keywords,
       SUM(impressions) AS total_impressions,
       SUM(clicks) AS total_clicks,
       SUM(cost) / 1000000.0 AS total_spend_usd,
       CAST(SUM(clicks) AS FLOAT) / NULLIF(SUM(impressions), 0) AS avg_ctr
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Pref]
GROUP BY quality_score
ORDER BY quality_score
```

### 7.3 Keyword Performance + Conversion Combined

```sql
SELECT p.criteria AS keyword, p.KeywordMatchType,
       SUM(p.impressions) AS impressions, SUM(p.clicks) AS clicks,
       SUM(p.cost) / 1000000.0 AS spend_usd,
       SUM(c.FTD) AS ftds, SUM(c.Registration) AS regs
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Pref] p
LEFT JOIN [BI_DB_dbo].[BI_DB_Adwords_Keywords_Conv] c
  ON p.date = c.date AND p.customer_id = c.customer_id
     AND p.device = c.device AND p.criteria = c.criteria
     AND p.campaign_id = c.campaign_id AND p.ad_group_id = c.ad_group_id
     AND p.week = c.week AND p.KeywordMatchType = c.KeywordMatchType
GROUP BY p.criteria, p.KeywordMatchType
HAVING SUM(p.clicks) > 0
ORDER BY spend_usd DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. SP authored by Amir G (2021-02-22), with KeywordMatchType column added by Amir (2021-04-05) and Conversions column added in the same change.

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 22 T2, 0 T3, 1 T4, 1 T5 | Elements: 24/24, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Keywords_Pref | Type: Table | Production Source: Fivetran Google Ads (keywords performance report)*
