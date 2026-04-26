# BI_DB_dbo.BI_DB_Bing_PBI_Daily_Perf

> 9,455,353-row incremental Bing Ads keyword-level daily performance dataset spanning 2022-01-01 to 2025-10-16, tracking impressions, clicks, spend, conversions, and assists per keyword × campaign × ad group × device × language × network × date combination. Populated daily from Fivetran's bingads `keyword_performance_daily_report` via SP_Bing_PBI. Used for paid search (SEM) Power BI reporting. One of four Bing PBI tables populated by the same SP run.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Microsoft Advertising (Bing Ads) API — via Fivetran `keyword_performance_daily_report` |
| **Refresh** | Daily DELETE+INSERT per @date — SP_Bing_PBI @date (Priority 20, SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only Power BI reporting table |
| **Row Count** | 9,455,353 (2022-01-01 to 2025-10-16) |
| **Author** | Jan Iablunovskey (2022-05-01) |

---

## 1. Business Meaning

This table stores Bing Ads (Microsoft Advertising) keyword-level daily performance data for eToro's paid search campaigns. It is one of four Bing PBI tables populated by the `SP_Bing_PBI` stored procedure in a single daily run:

1. **BI_DB_Bing_PBI_Daily_Perf** (this table) — keyword-level daily performance metrics
2. **BI_DB_Bing_PBI_Goals_Funnels** — goal and funnel conversion tracking per keyword
3. **BI_DB_Bing_PBI_Campaign_Dict** — campaign dimension (documented in Batch 14)
4. **BI_DB_Bing_PBI_Group_Dict** — ad group dimension

Each row represents a unique combination of: `campaign_id × ad_group_id × keyword_id × date × delivered_match_type × device_type × device_os × language × network × top_vs_other`. The table is **incremental**: SP deletes and reinserts data for the run date, preserving all prior dates.

The data spans 2022-01-01 to 2025-10-16 — the Fivetran bingads connector appears to have stopped feeding new data after October 2025, based on the max UpdateDate of 2025-10-17.

Device split (2025 data): Computer dominates (~84%), Smartphone (~16%), Tablet (~1.7%). Search network: Microsoft sites and select traffic (~55%), Audience network (~25%), Syndicated search partners (~7%), AOL search (~1%). Match type (2025): Exact (~41%), Broad (~34%), Phrase (~25%).

**Important note on numeric(18,0) truncation**: `current_max_cpc`, `spend`, and `average_position` are stored as `numeric(18,0)` — all decimal places are truncated. Microsoft Advertising API returns spend in the account currency (e.g., USD); values of 4–16 for `current_max_cpc` likely represent dollar amounts.

---

## 2. Business Logic

### 2.1 Incremental Load Pattern (DELETE + INSERT per date)

**What**: Unlike the dictionary tables in the same SP, Daily_Perf uses incremental loading.  
**Columns Involved**: date  
**Rules**:
- `DELETE FROM BI_DB_Bing_PBI_Daily_Perf WHERE date = @date` — removes any existing rows for that date
- `INSERT ... WHERE date = @date` — inserts fresh Fivetran data for that date
- Historical rows for all other dates are preserved
- This allows backfilling by re-running SP with any past date

### 2.2 Fivetran Data Feed

**What**: Data originates from Bing Ads API via Fivetran's bingads connector keyword_performance_daily_report.  
**Columns Involved**: All performance metrics, _fivetran_synced  
**Rules**:
- `_fivetran_synced`: Timestamp when Fivetran synced this row (UTC); differs from UpdateDate (Synapse SP run time)
- Fivetran incrementally syncs from Bing Ads API; SP then loads into Synapse
- SP also updates Campaign Dict and Group Dict (TRUNCATE+INSERT) and Goals_Funnels (DELETE+INSERT) in the same execution

### 2.3 Match Type Dimension

**What**: `delivered_match_type` indicates how the keyword was matched to the search query.  
**Columns Involved**: delivered_match_type  
**Rules**:
- Exact: Ad shown only when search query exactly matches the keyword
- Broad: Ad shown for broader related searches
- Phrase: Ad shown when search query contains the keyword phrase
- Distribution (2025): Exact (~41%), Broad (~34%), Phrase (~25%)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no hash advantage for any particular filter. CLUSTERED INDEX (date ASC) — efficient for date-range queries and time-series aggregations, which is the primary access pattern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily spend by campaign | `GROUP BY campaign_id, date ORDER BY date DESC` |
| CTR by keyword and match type | `SUM(Clicks)/SUM(impressions)` grouped by `keyword_id, delivered_match_type` |
| Performance by device type over time | `GROUP BY device_type, date` |
| Top-performing keywords by conversions | `GROUP BY keyword_id ORDER BY SUM(conversions) DESC` |
| Spend trend by network | `GROUP BY network, date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Bing_PBI_Campaign_Dict | `campaign_id = id` | Enrich with campaign name, status, budget, bid strategy |
| BI_DB_Bing_PBI_Group_Dict | `ad_group_id = id` | Enrich with ad group name and settings |
| BI_DB_Bing_PBI_Goals_Funnels | `campaign_id = campaign_id AND ad_group_id = ad_group_id AND keyword_id = keyword_id AND date = date` | Add conversion goal breakdown |

### 3.4 Gotchas

- **numeric(18,0) truncates decimal values** — `current_max_cpc`, `spend`, and `average_position` lose all decimal places. For accurate financial analysis, the raw Fivetran source (external table) should be consulted if decimal precision is needed.
- **keyword_id is varchar(max)** despite holding bigint-like values in the DDL. Do not assume numeric operations will work — always treat as string.
- **Clicks column is PascalCase** — uniquely capitalized unlike all other lowercase columns. Queries must use `[Clicks]` or `Clicks` (case-insensitive in Synapse but naming is inconsistent vs. the external source which uses lowercase `clicks`).
- **Fivetran feed appears to have stopped at 2025-10-16** — max date and UpdateDate both around October 2025. Verify whether the Fivetran connector is active before relying on recency of data.
- **No deduplication guard** — rows for a given date are deleted and reinserted daily; if SP_Bing_PBI fails mid-run, only partial data for that date may remain (delete happened but insert was incomplete).
- **_fivetran_synced ≠ UpdateDate** — `_fivetran_synced` is the Fivetran API sync time (earlier); `UpdateDate` is the Synapse SP insertion time (later, by hours).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis or external source documentation. All columns in this table are passthroughs from the Fivetran Bing Ads external table (no upstream production wiki). |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | delivered_match_type | varchar(max) | YES | Bing Ads keyword match type used when the ad was served. Values: Exact (keyword matched search query exactly), Broad (matched broader related searches), Phrase (query contained the keyword phrase). Distribution (2025): Exact~41%, Broad~34%, Phrase~25%. (Tier 2 — SP_Bing_PBI) |
| 2 | ad_group_id | bigint | YES | Bing Ads ad group identifier. FK to BI_DB_Bing_PBI_Group_Dict.id. (Tier 2 — SP_Bing_PBI) |
| 3 | campaign_id | bigint | YES | Bing Ads campaign identifier. FK to BI_DB_Bing_PBI_Campaign_Dict.id. (Tier 2 — SP_Bing_PBI) |
| 4 | device_os | varchar(100) | YES | Operating system of the device that served the ad (e.g., Windows, iOS, Android, Unknown). Subdivides device_type. (Tier 2 — SP_Bing_PBI) |
| 5 | device_type | varchar(100) | YES | Device category: Computer (dominates ~84% in 2025), Smartphone (~16%), Tablet (~2%). (Tier 2 — SP_Bing_PBI) |
| 6 | keyword_id | varchar(max) | YES | Bing Ads keyword identifier. Stored as varchar(max) despite holding numeric-looking IDs. Do not cast to bigint without validation. (Tier 2 — SP_Bing_PBI) |
| 7 | language | varchar(100) | YES | Language setting of the ad campaign for this impression (e.g., German, English, Italian, Chinese, French). (Tier 2 — SP_Bing_PBI) |
| 8 | network | varchar(max) | YES | Search network where the ad was displayed. Values: Microsoft sites and select traffic (~55%), Audience (~25%), Syndicated search partners (~7%), AOL search (~1%). (Tier 2 — SP_Bing_PBI) |
| 9 | top_vs_other | varchar(max) | YES | Placement on search results page: indicates whether the ad appeared in a top position (e.g., 'Bing and Yahoo! search - Top') or in another position ('...other'). Also includes 'Audience network'. (Tier 2 — SP_Bing_PBI) |
| 10 | date | date | YES | Reporting date for this row (the date the ad performance occurred). CLUSTERED INDEX key. Range: 2022-01-01 to 2025-10-16. (Tier 2 — SP_Bing_PBI) |
| 11 | current_max_cpc | numeric(18,0) | YES | Maximum cost-per-click bid for this keyword on this date, in account currency (USD). Truncated to whole number by numeric(18,0) — decimal bid values are lost. (Tier 2 — SP_Bing_PBI) |
| 12 | impressions | bigint | YES | Number of times the ad was shown (served) for this row's dimension combination. (Tier 2 — SP_Bing_PBI) |
| 13 | Clicks | bigint | YES | Number of clicks on the ad for this dimension combination. NOTE: PascalCase column name (unlike all other lowercase columns). (Tier 2 — SP_Bing_PBI) |
| 14 | spend | numeric(18,0) | YES | Total advertising spend in account currency (USD) for this dimension combination. Truncated to whole number — fractional cents are lost. (Tier 2 — SP_Bing_PBI) |
| 15 | average_position | numeric(18,0) | YES | Average position of the ad in search results (1=top). Truncated to whole number — fractional positions are lost. Deprecated in some Bing Ads reporting contexts. (Tier 2 — SP_Bing_PBI) |
| 16 | conversions | bigint | YES | Number of last-click conversions attributed to this keyword. Does not include view-through conversions. (Tier 2 — SP_Bing_PBI) |
| 17 | quality_score | bigint | YES | Bing Ads keyword quality score (typically 1–10). Higher scores indicate better expected ad relevance and landing page quality. (Tier 2 — SP_Bing_PBI) |
| 18 | keyword_status | varchar(max) | YES | Current status of the keyword in Bing Ads (e.g., Active, Paused, Deleted). Reflects the status at the time Fivetran synced this row, not necessarily the current status. (Tier 2 — SP_Bing_PBI) |
| 19 | assists | bigint | YES | Number of conversions where this keyword contributed a click before the final converting click (assist attribution, not last-click). (Tier 2 — SP_Bing_PBI) |
| 20 | all_conversions | bigint | YES | Total conversions including all attribution types (last-click + view-through). Broader than `conversions` which counts only last-click. (Tier 2 — SP_Bing_PBI) |
| 21 | _fivetran_synced | datetime | YES | Fivetran metadata: timestamp when Fivetran synced this row from the Bing Ads API. Predates UpdateDate by hours (API sync → lake → SP load delay). (Tier 2 — SP_Bing_PBI) |
| 22 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at SP_Bing_PBI execution time. Reflects Synapse insertion time, not Bing Ads event time. (Tier 2 — SP_Bing_PBI) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| All (1–21) | Microsoft Advertising API → Fivetran → Data Lake → External_Fivetran_bingads_keyword_performance_daily_report | Same names (except clicks→Clicks) | Passthrough; numeric(18,0) truncates CPC/spend/position |
| UpdateDate | Hardcoded | — | GETDATE() at SP execution |

### 5.2 ETL Pipeline

```
Microsoft Advertising (Bing Ads) API
  |-- Fivetran bingads connector (keyword_performance_daily_report) --|
  v
Azure Data Lake Storage (Bronze layer)
  |-- Synapse External Table: External_Fivetran_bingads_keyword_performance_daily_report --|
  v
[SP_Bing_PBI @date: DELETE WHERE date=@date + INSERT WHERE date=@date]
  v
BI_DB_dbo.BI_DB_Bing_PBI_Daily_Perf
(9,455,353 rows, 2022-01-01 to 2025-10-16, ROUND_ROBIN CLUSTERED(date))
  |-- _Not_Migrated (no UC target) --|

SAME SP RUN ALSO LOADS:
  BI_DB_Bing_PBI_Group_Dict    (TRUNCATE+INSERT from External_Fivetran_bingads_ad_group_history)
  BI_DB_Bing_PBI_Campaign_Dict (TRUNCATE+INSERT from External_Fivetran_bingads_campaign_history)
  BI_DB_Bing_PBI_Goals_Funnels (DELETE+INSERT from External_Fivetran_bingads_goals_and_funnels_daily_report)
```

---

## 6. Relationships

### 6.1 References To (this table reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| All performance metrics | BI_DB_dbo.External_Fivetran_bingads_keyword_performance_daily_report | Fivetran Bing Ads external table — direct passthrough source |
| campaign_id | BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict | Campaign dimension (same SP run) |
| ad_group_id | BI_DB_dbo.BI_DB_Bing_PBI_Group_Dict | Ad group dimension (same SP run) |

### 6.2 Referenced By (other objects read from this table)

No stored procedures or views in the SSDT repo read from this table. It is a terminal Power BI source table consumed directly by BI reporting tools.

---

## 7. Sample Queries

### Daily Campaign Performance Summary

```sql
-- Aggregate keyword-level data to campaign level for Power BI
SELECT
    campaign_id,
    date,
    delivered_match_type,
    device_type,
    SUM(impressions) AS TotalImpressions,
    SUM(Clicks) AS TotalClicks,
    SUM(spend) AS TotalSpend,
    SUM(conversions) AS TotalConversions,
    SUM(all_conversions) AS TotalAllConversions,
    CASE WHEN SUM(impressions) > 0 THEN CAST(SUM(Clicks) AS FLOAT) / SUM(impressions) ELSE 0 END AS CTR
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Daily_Perf]
WHERE date >= '2025-01-01'
GROUP BY campaign_id, date, delivered_match_type, device_type
ORDER BY date DESC, TotalSpend DESC;
```

### Keyword Performance with Campaign Name

```sql
-- Enrich performance data with campaign name from Campaign Dict
SELECT
    dp.date,
    dp.keyword_id,
    cd.name AS CampaignName,
    dp.delivered_match_type,
    dp.language,
    dp.impressions,
    dp.Clicks,
    dp.spend,
    dp.conversions,
    dp.quality_score
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Daily_Perf] dp
LEFT JOIN [BI_DB_dbo].[BI_DB_Bing_PBI_Campaign_Dict] cd ON dp.campaign_id = cd.id
WHERE dp.date >= '2025-01-01'
ORDER BY dp.spend DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources queried. Table was created by Jan Iablunovskey (2022-05-01) as part of the Bing Ads Power BI reporting suite. Business context is fully derivable from SP code and Fivetran connector documentation.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14*  
*Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 0 T5 | Elements: 22/22, Logic: 8/10, Sources: 9/10*  
*Object: BI_DB_dbo.BI_DB_Bing_PBI_Daily_Perf | Type: Table | Production Source: Fivetran bingads keyword_performance_daily_report (via SP_Bing_PBI)*
