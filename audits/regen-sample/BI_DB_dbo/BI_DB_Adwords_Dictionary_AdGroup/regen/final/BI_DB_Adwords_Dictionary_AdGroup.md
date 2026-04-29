# BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup

> **STALE DATA — last refreshed 2023-09-18.** 31,322-row Google Ads ad group dictionary table mapping ad_group_id to ad group name, status, and parent campaign. Canonical lookup for all Adwords performance and conversion tables in the SP_Adwords_Pref_Conv cluster. Covers 2,192 campaigns and 27,565 distinct ad groups across 13 Google Ads accounts. Full-refresh TRUNCATE+INSERT from Fivetran ad group performance report.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report → SP_Adwords_Pref_Conv (Table #12) |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. TRUNCATE+INSERT (full refresh). |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 31,322 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Dictionary_AdGroup` is a **lookup/dictionary table** for Google Ads ad groups. It provides the canonical mapping from `ad_group_id` to human-readable ad group name, operational status, and parent campaign. All other Adwords tables in the SP_Adwords_Pref_Conv cluster (Geo_Pref, Ad_Pref, Keywords_Pref, Geo_Conv, Ad_Conv, Keywords_Conv, Search_Perf, Search_Conv, Campaign_Performance_Report, Conversion_Performance_Report) reference this table via `ad_group_id` for ad group name resolution.

The SP performs a TRUNCATE+INSERT of `SELECT DISTINCT` from the Fivetran ad group performance report, filtered by `WHERE name IS NOT NULL`. This means the table always reflects the latest snapshot of all ad groups that have ever appeared in the performance data — there is no rolling window or date-based retention. Column renames: `id` → `ad_group_id`, `name` → `ad_group_name`, `status` → `ad_group_status`.

The `target_cpa` column exists in the DDL but is NOT populated by the SP INSERT statement — it is always NULL across all 31,322 rows.

**DATA IS STALE**: All rows have UpdateDate = 2023-09-18 16:48:36. The SP has not run since the Synapse migration.

---

## 2. Business Logic

### 2.1 Full-Refresh Dictionary Pattern

**What**: Complete replacement of ad group metadata on each SP run.
**Columns Involved**: All columns
**Rules**:
- TRUNCATE TABLE followed by INSERT (not rolling DELETE+INSERT like the performance tables)
- SELECT DISTINCT eliminates duplicate ad group entries from the performance report
- WHERE name IS NOT NULL filters out ad groups with no name (rare edge case)

### 2.2 Ad Group Status Classification

**What**: Operational lifecycle status of each ad group in Google Ads.
**Columns Involved**: ad_group_status
**Rules**:
- ENABLED = actively serving ads (20,893 rows, 67%)
- PAUSED = temporarily stopped by advertiser (7,233 rows, 23%)
- REMOVED = permanently deleted from Google Ads account (3,196 rows, 10%)

### 2.3 Unpopulated Column

**What**: target_cpa exists in DDL but is not loaded.
**Columns Involved**: target_cpa
**Rules**:
- Column is defined as float NULL in DDL
- SP INSERT statement does not include target_cpa in the column list
- Always NULL across all 31,322 rows
- Likely intended for CPA bidding strategy target but never implemented in the SP

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP (no clustered index). With 31K rows the table is small enough for full scans. No distribution key — JOINs from performance tables will broadcast this dictionary.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve ad group name | `JOIN BI_DB_Adwords_Dictionary_AdGroup d ON t.ad_group_id = d.ad_group_id` |
| Active ad groups per campaign | `WHERE ad_group_status = 'ENABLED' GROUP BY campaign_id` |
| Ad group count by status | `GROUP BY ad_group_status` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Geo_Pref | ad_group_id | Resolve ad group name for geographic performance |
| BI_DB_Adwords_Ad_Pref | ad_group_id | Resolve ad group name for ad-level performance |
| BI_DB_Adwords_Keywords_Pref | ad_group_id | Resolve ad group name for keyword performance |
| BI_DB_Adwords_Geo_Conv | ad_group_id | Resolve ad group name for geographic conversions |
| BI_DB_Adwords_Ad_Conv | ad_group_id | Resolve ad group name for ad-level conversions |
| BI_DB_Adwords_Keywords_Conv | ad_group_id | Resolve ad group name for keyword conversions |
| BI_DB_Adwords_Search_Perf | ad_group_id | Resolve ad group name for search query performance |
| BI_DB_Adwords_Search_Conv | ad_group_id | Resolve ad group name for search query conversions |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Resolve parent campaign name and bidding strategy |

### 3.4 Gotchas

- **Data is STALE** — snapshot from 2023-09-18. Ad group names/statuses may have changed in Google Ads since then.
- **target_cpa is always NULL** — column exists in DDL but SP does not populate it. Do not filter or aggregate on it.
- **ad_group_id is not unique** — 27,565 distinct values across 31,322 rows. Some ad groups may appear with multiple campaign_id associations due to SELECT DISTINCT across the full performance report.
- **ad_group_name encodes targeting metadata** — naming convention includes region, keyword theme, match type (e.g., 'EN_KW_ETF-LowIntent', 'FR_Investir Actions (Stocks Invest)_BMM').
- **Performance tables denormalize names** — Geo_Pref and Ad_Pref embed ad_group_name directly. Dictionary values may differ from denormalized copies if names changed between snapshots.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 4 | Column not populated by SP — inferred from DDL | DDL only |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | campaign_id | bigint | YES | Google Ads campaign identifier. Links this ad group to its parent campaign. FK to BI_DB_Adwords_Dictionary_Campaign. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | ad_group_id | bigint | YES | Google Ads ad group identifier. Canonical ad group key used by all Adwords performance and conversion tables. Mapped from Fivetran `id` column. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | ad_group_name | nvarchar(256) | YES | Google Ads ad group name. Human-readable label from Google Ads UI. Encodes targeting metadata: region, keyword theme, match type (e.g., 'EN_KW_ETF-LowIntent', 'FR_Investir Actions (Stocks Invest)_BMM'). Mapped from Fivetran `name` column. Filtered by WHERE name IS NOT NULL. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | target_cpa | float | YES | **NOT POPULATED** — column exists in DDL but SP does not include it in the INSERT statement. Always NULL across all 31,322 rows. Intended for Google Ads target CPA bidding value but never implemented. (Tier 4 — inferred from DDL) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). All rows show 2023-09-18 due to TRUNCATE+INSERT pattern. (Tier 5 — ETL infrastructure) |
| 6 | ad_group_status | nvarchar(256) | YES | Google Ads ad group operational status. ENABLED=actively serving (67%), PAUSED=temporarily stopped (23%), REMOVED=permanently deleted (10%). Mapped from Fivetran `status` column. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| campaign_id | Fivetran Google Ads | campaign_id | Passthrough |
| ad_group_id | Fivetran Google Ads | id | Rename |
| ad_group_name | Fivetran Google Ads | name | Rename (filtered: WHERE name IS NOT NULL) |
| target_cpa | — | — | Not populated by SP (always NULL) |
| UpdateDate | SP | N/A | GETDATE() |
| ad_group_status | Fivetran Google Ads | status | Rename |

### 5.2 ETL Pipeline

```
Google Ads API (ad group performance report)
  |-- Fivetran connector (adwords_adgroup_perf_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report
  |-- SP_Adwords_Pref_Conv (Table #12, P99, SB_FinanceReportSPS) ---|
  |   TRUNCATE + INSERT SELECT DISTINCT (WHERE name IS NOT NULL)
  |   Column renames: id→ad_group_id, name→ad_group_name, status→ad_group_status
  v
BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup (31,322 rows — STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Parent campaign metadata (name, bidding strategy, budget) |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ad_group_id | BI_DB_Adwords_Geo_Pref | Ad group name lookup for geographic performance |
| ad_group_id | BI_DB_Adwords_Ad_Pref | Ad group name lookup for ad-level performance |
| ad_group_id | BI_DB_Adwords_Keywords_Pref | Ad group name lookup for keyword performance |
| ad_group_id | BI_DB_Adwords_Geo_Conv | Ad group name lookup for geographic conversions |
| ad_group_id | BI_DB_Adwords_Ad_Conv | Ad group name lookup for ad-level conversions |
| ad_group_id | BI_DB_Adwords_Keywords_Conv | Ad group name lookup for keyword conversions |
| ad_group_id | BI_DB_Adwords_Search_Perf | Ad group name lookup for search query performance |
| ad_group_id | BI_DB_Adwords_Search_Conv | Ad group name lookup for search query conversions |

---

## 7. Sample Queries

### 7.1 Ad Groups by Status

```sql
SELECT ad_group_status, COUNT(*) AS ad_group_count, COUNT(DISTINCT campaign_id) AS campaigns
FROM [BI_DB_dbo].[BI_DB_Adwords_Dictionary_AdGroup]
GROUP BY ad_group_status
ORDER BY ad_group_count DESC
```

### 7.2 Campaign Ad Group Breakdown with Names

```sql
SELECT d.campaign_id, c.campaign_name, d.ad_group_name, d.ad_group_status
FROM [BI_DB_dbo].[BI_DB_Adwords_Dictionary_AdGroup] d
JOIN [BI_DB_dbo].[BI_DB_Adwords_Dictionary_Campaign] c ON d.campaign_id = c.campaign_id
WHERE d.ad_group_status = 'ENABLED'
ORDER BY c.campaign_name, d.ad_group_name
```

### 7.3 Ad Group Performance with Name Resolution

```sql
SELECT d.ad_group_name, d.ad_group_status,
       SUM(p.impressions) AS impressions, SUM(p.clicks) AS clicks,
       SUM(p.cost) / 1000000.0 AS cost_usd
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Pref] p
JOIN [BI_DB_dbo].[BI_DB_Adwords_Dictionary_AdGroup] d ON p.ad_group_id = d.ad_group_id
GROUP BY d.ad_group_name, d.ad_group_status
ORDER BY cost_usd DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this dictionary table. SP authored by Amir G (2021-02-22), ad_group_status column added 2021-05-16.

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 4 T2, 0 T3, 1 T4, 1 T5 | Elements: 6/6, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | Type: Table | Production Source: Fivetran Google Ads (ad group performance report)*
