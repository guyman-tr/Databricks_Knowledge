# BI_DB_dbo.BI_DB_Adwords_Search_Conv

> **STALE DATA — last refreshed 2023-09-18.** 12,992-row Google Ads search query conversion tracking table at monthly granularity. Pivots conversion_action_name into funnel columns (Registration, V2, FTD, MultipleDeposit, FTDA, MTDA) plus 1st-gen Android/iOS app conversions, grouped by search term, device, match type, campaign, ad group, and account. Conversion counterpart to BI_DB_Adwords_Search_Perf (which has performance metrics). Part of SP_Adwords_Pref_Conv cluster (Table #10 of 12). Month range: 2023-05-01 to 2023-08-01. 12 Google Ads accounts, 8,461 unique search queries.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report → SP_Adwords_Pref_Conv |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Monthly rolling DELETE+INSERT with 4-month window + year-ago floor. |
| **Synapse Distribution** | HASH (customer_id) |
| **Synapse Index** | CLUSTERED INDEX (month ASC) |
| **Row Count** | 12,992 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Search_Conv` tracks **Google Ads search query conversion performance** at monthly granularity — answering "which actual search terms typed by users led to eToro registrations, verifications, and deposits?" This is the conversion counterpart to `BI_DB_Adwords_Search_Perf` (which tracks impressions, clicks, and cost for the same search queries).

Each row represents conversions for a specific search query (the actual text the user typed), month, device, match type, campaign, ad group, and Google Ads account. The SP pivots raw Fivetran conversion action rows into columnar funnel metrics: Registration, V2, FTD, MultipleDeposit (counts) and FTDA, MTDA (monetary values). It also includes 1st-gen Android/iOS eToro app conversions.

This is Table #10 in SP_Adwords_Pref_Conv. The monthly grain (vs. daily for other tables in the cluster) keeps volume manageable given the high cardinality of search queries. Conversion formula: `all_conversions - view_through_conversions` (click-through only). The table has 12 Google Ads accounts, 130 campaigns, 613 ad groups, and 8,461 unique search queries including multi-language terms ('meilleur site crypto', 'etoro trading', 's&p 500').

Unlike `BI_DB_Adwords_Keywords_Conv` (Table #6), Search_Conv does NOT have: 2nd-gen app columns, LTV metrics, Open Trade events, or KeywordMatchType as a separate dimension. However, Search_Conv includes `final_url` and `campaign_id` which Keywords_Conv does not have (Keywords_Conv groups by keyword_text/criteria, while Search_Conv groups by actual search_term/query).

**DATA IS STALE**: Last updated 2023-09-18. Month range only 2023-05-01 to 2023-08-01. Volume drops sharply after June (May: 6,132, Jun: 5,863, Jul: 889, Aug: 108 rows).

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot with Values

**What**: Raw Fivetran rows with conversion_action_name are pivoted into one column per funnel stage plus monetary values, aggregated at monthly grain.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit, FTDA, MTDA
**Rules**:
- Registration = SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'
- V2 = same formula WHERE 'V2 Status'
- FTD = same WHERE 'FTD'
- MultipleDeposit = same WHERE 'Multiple Deposit'
- FTDA = SUM(all_conversions_value) WHERE 'FTD' — FTD conversion monetary value
- MTDA = SUM(all_conversions_value) WHERE 'Multiple Deposit' — multiple deposit monetary value
- Click-through only (excludes view-through conversions)

### 2.2 App Conversion Tracking (1st-Gen Only)

**What**: Device-specific conversion tracking for Android and iOS 1st-gen eToro apps.
**Columns Involved**: android_reg, android_v2, android_ftd, ios_reg, ios_v2, ios_ftd
**Rules**:
- Android tracks "eToro - Invest in stocks, crypto & trade CFDs (Android)" actions
- iOS tracks "eToro Cryptocurrency Trading (iOS)" actions
- No 2nd-gen app columns in this table (unlike Ad_Conv and Keywords_Conv)
- Conversion formula same as funnel columns: SUM(all_conversions - view_through_conversions)

### 2.3 Search Query Match Types

**What**: How the user's actual search matched the advertiser's keyword.
**Columns Involved**: query_match_type_with_variant, query_targeting_status
**Rules**:
- Both columns contain the SAME value (both mapped from search_term_match_type in Fivetran)
- EXACT = 39% (5,057 rows), NEAR_EXACT = 27% (3,530), NEAR_PHRASE = 16% (2,037), BROAD = 13% (1,648), PHRASE = 6% (720)

### 2.4 Monthly Rolling Window Retention

**What**: Historical data management.
**Columns Involved**: month
**Rules**:
- DELETE months older than 1 year from first-of-month
- DELETE + INSERT for 4-month rolling window (FromMonth to FirstDayOfNextMonth)
- Filtered by 10 specific conversion_action_name values (4 web funnel + 6 app)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(customer_id) distribution with CLUSTERED INDEX on month ASC. The HASH distribution enables co-located JOINs with Search_Perf (also HASH on customer_id). Month index optimizes time-range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top converting search terms | GROUP BY query ORDER BY SUM(FTD) DESC |
| Search query cost per FTD | JOIN with Search_Perf for cost, SUM(cost)/NULLIF(SUM(FTD),0) |
| Match type conversion effectiveness | GROUP BY query_match_type_with_variant |
| Campaign conversion by search term | GROUP BY campaign_id, query |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Search_Perf | month, customer_id, query, device, query_match_type_with_variant | Combine search query conversions + performance metrics (impressions, clicks, cost) |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign metadata (name, bidding strategy) |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group metadata (name, status) |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-05-01 to 2023-08-01. Volume drops to 108 rows in August.
- **query_targeting_status = query_match_type_with_variant** — always identical values (both from search_term_match_type). Redundant column.
- **keyword_id is always NULL** — column exists in DDL but SP has it commented out.
- **search_key is always NULL** — column exists in DDL but SP has it commented out (search_key composite formula also had a syntax error in the SP comment).
- **external_customer_id = customer_id** — always identical, redundant duplicate.
- **FTDA/MTDA are monetary VALUES, not counts** — SUM(all_conversions_value), not conversion counts.
- **Conversion columns are float** — may contain fractional values from Google's data-driven attribution model.
- **Monthly grain, not daily** — unlike most Adwords tables. Aggregated to keep volume manageable for high-cardinality search queries.
- **No 2nd-gen app columns** — unlike Ad_Conv and Keywords_Conv which have Regs_IOS2/Android2 columns.

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
| 1 | month | nvarchar(256) | YES | Monthly period start date (first day of month, e.g., '2023-08-01'). Aggregation grain for search query conversions. Range: 2023-05-01 to 2023-08-01. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | customer_id | bigint | NO | Google Ads account identifier (MCC-level customer ID). Distribution key. 12 distinct accounts. Used as GROUP BY key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | query | nvarchar(256) | YES | Actual search term the user typed that triggered the ad impression. Renamed from Fivetran field 'search_term'. High cardinality (8,461 unique queries). Multi-language terms ('meilleur site crypto', 'etoro trading', 's&p 500'). (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | device | nvarchar(256) | YES | Device type where the ad was shown. DESKTOP (61%), MOBILE (38%), TABLET (0.8%), CONNECTED_TV (0.2%). Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | query_targeting_status | nvarchar(256) | YES | Search term match type — ALWAYS identical to query_match_type_with_variant. Both mapped from Fivetran search_term_match_type. Redundant column. Values: EXACT, NEAR_EXACT, NEAR_PHRASE, BROAD, PHRASE. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | external_customer_id | bigint | YES | Duplicate of customer_id — SP inserts customer_id into both columns. Always identical. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | query_match_type_with_variant | nvarchar(256) | YES | How the search query matched the advertiser's keyword. EXACT (39%), NEAR_EXACT (27%), NEAR_PHRASE (16%), BROAD (13%), PHRASE (6%). Renamed from Fivetran field 'search_term_match_type'. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | keyword_id | bigint | YES | **NOT POPULATED** — column exists in DDL but SP has it commented out. Always NULL across all 12,992 rows. Intended for Google Ads keyword identifier. (Tier 4 — not inserted by SP) |
| 9 | account_currency_code | nvarchar(256) | YES | Google Ads account currency. Renamed from Fivetran field 'customer_currency_code'. All sampled values are 'USD'. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. 130 distinct campaigns. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. 613 distinct ad groups. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | final_url | nvarchar(256) | YES | Landing page URL for the ad that was shown. Renamed from Fivetran field 'ad_final_urls'. Contains eToro domain URLs (e.g., 'https://go.etoro.com/en/evergreen-stocks'). Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | search_key | nvarchar(1340) | YES | **NOT POPULATED** — column exists in DDL but SP has it commented out. Always NULL. Intended as composite search key (ad_group_id + device + month + search_term + keyword_id + match_type). (Tier 4 — not inserted by SP) |
| 14 | Registration | float | YES | Click-through registration conversions. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'. Excludes view-through. Float due to Google's fractional attribution. Total: ~19,874. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | V2 | float | YES | Click-through V2 (Level 2 verification) conversions. SUM WHERE conversion_action_name = 'V2 Status'. Total: ~11,736. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | FTD | float | YES | Click-through first-time deposit conversions. SUM WHERE conversion_action_name = 'FTD'. Total: ~2,702. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | MultipleDeposit | float | YES | Click-through multiple deposit conversions. SUM WHERE conversion_action_name = 'Multiple Deposit'. Total: ~6,774. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | FTDA | float | YES | FTD conversion monetary value. SUM(all_conversions_value) WHERE conversion_action_name = 'FTD'. Not a count — represents attributed dollar value of first-time deposits. Total: ~$1.3M. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | MTDA | float | YES | Multiple deposit conversion monetary value. SUM(all_conversions_value) WHERE conversion_action_name = 'Multiple Deposit'. Not a count. Total: ~$6.0M. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was loaded by SP_Adwords_Pref_Conv (GETDATE()). All rows show 2023-09-18 (single bulk load). (Tier 5 — SP_Adwords_Pref_Conv) |
| 21 | android_reg | float | YES | 1st-gen Android app ("eToro - Invest in stocks, crypto & trade CFDs") registration conversions. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name matches Android registration. Float due to fractional attribution. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | android_v2 | float | YES | 1st-gen Android app Level 2 verification conversions. SUM WHERE '...(Android) Verification Level - 2'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | android_ftd | float | YES | 1st-gen Android app first-time deposit conversions. SUM WHERE '...(Android) FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | ios_reg | float | YES | 1st-gen iOS app ("eToro Cryptocurrency Trading") registration conversions. SUM WHERE conversion_action_name matches iOS registration. Float due to fractional attribution. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | ios_v2 | float | YES | 1st-gen iOS app Level 2 verification conversions. SUM WHERE '...(iOS) Verification Level - 2'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | ios_ftd | float | YES | 1st-gen iOS app first-time deposit conversions. SUM WHERE '...(iOS) FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| month | Fivetran Google Ads | month | Passthrough |
| customer_id | Fivetran Google Ads | customer_id | Passthrough |
| query | Fivetran Google Ads | search_term | Rename |
| device | Fivetran Google Ads | device | Passthrough |
| query_targeting_status | Fivetran Google Ads | search_term_match_type | Rename (duplicate of query_match_type_with_variant) |
| external_customer_id | Fivetran Google Ads | customer_id | Duplicate of customer_id |
| query_match_type_with_variant | Fivetran Google Ads | search_term_match_type | Rename |
| keyword_id | — | — | Not inserted (commented out) |
| account_currency_code | Fivetran Google Ads | customer_currency_code | Rename |
| campaign_id | Fivetran Google Ads | campaign_id | Passthrough |
| ad_group_id | Fivetran Google Ads | ad_group_id | Passthrough |
| final_url | Fivetran Google Ads | ad_final_urls | Rename |
| search_key | — | — | Not inserted (commented out) |
| Registration..MultipleDeposit | Fivetran Google Ads | conversion_action_name + all_conversions + view_through_conversions | CASE WHEN pivot + SUM |
| FTDA | Fivetran Google Ads | conversion_action_name + all_conversions_value | CASE WHEN pivot + SUM (FTD value) |
| MTDA | Fivetran Google Ads | conversion_action_name + all_conversions_value | CASE WHEN pivot + SUM (Multiple Deposit value) |
| android_*/ios_* | Fivetran Google Ads | conversion_action_name (1st-gen app actions) | CASE WHEN pivot + SUM |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API (search query conversion report)
  |-- Fivetran connector (adwords_search_conv_new_api schema) ---|
  v
Bronze Data Lake (adwords/search_conv/new_api/conv/)
  |-- External Table (ADLS Gen2 Parquet) ---|
  v
BI_DB_dbo.External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #10, P99, SB_FinanceReportSPS) ---|
  |   DELETE old (>1yr) + DELETE 4-month overlap + INSERT with CASE WHEN pivot
  |   10 conversion_action_name values filtered
  |   GROUP BY month, customer_id, search_term, device, search_term_match_type (x2),
  |           customer_currency_code, campaign_id, ad_group_id, ad_final_urls
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
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata lookup (name, bidding strategy, status) |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata lookup (name, status) |

### 6.2 Referenced By (other objects point to this)

No known consumers. Terminal reporting table typically joined with Search_Perf for complete search query analysis (conversions + performance).

---

## 7. Sample Queries

### 7.1 Top Converting Search Terms by FTD

```sql
SELECT TOP 20 query, query_match_type_with_variant,
       SUM(Registration) AS regs, SUM(V2) AS v2s, SUM(FTD) AS ftds,
       SUM(FTDA) AS ftd_value
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Conv]
GROUP BY query, query_match_type_with_variant
HAVING SUM(FTD) > 0
ORDER BY ftds DESC
```

### 7.2 Search Query Conversions + Performance Combined

```sql
SELECT c.month, c.query,
       SUM(c.FTD) AS ftds, SUM(c.Registration) AS regs,
       SUM(p.clicks) AS clicks, SUM(p.cost) / 1000000.0 AS cost_usd
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Conv] c
JOIN [BI_DB_dbo].[BI_DB_Adwords_Search_Perf] p
  ON c.month = p.month AND c.customer_id = p.customer_id
     AND c.query = p.query AND c.device = p.device
     AND c.query_match_type_with_variant = p.query_match_type_with_variant
GROUP BY c.month, c.query
HAVING SUM(c.FTD) > 0
ORDER BY cost_usd DESC
```

### 7.3 Match Type Conversion Effectiveness

```sql
SELECT query_match_type_with_variant,
       COUNT(*) AS rows,
       SUM(Registration) AS total_regs,
       SUM(FTD) AS total_ftds,
       SUM(FTDA) AS total_ftd_value
FROM [BI_DB_dbo].[BI_DB_Adwords_Search_Conv]
GROUP BY query_match_type_with_variant
ORDER BY total_ftds DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. SP authored by Amir G (2021-02-22), with search query tables added by Chen (2021-11-18) and app conversion columns added by Jan Iablunovskey (2022-05-10).

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 22 T2, 0 T3, 2 T4, 1 T5 | Elements: 25/25, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Search_Conv | Type: Table | Production Source: Fivetran Google Ads → SP_Adwords_Pref_Conv*
