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
