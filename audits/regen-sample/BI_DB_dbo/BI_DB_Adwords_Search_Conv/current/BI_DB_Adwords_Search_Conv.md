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
