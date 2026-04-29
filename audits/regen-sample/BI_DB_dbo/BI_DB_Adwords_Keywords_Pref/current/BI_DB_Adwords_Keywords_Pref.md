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
