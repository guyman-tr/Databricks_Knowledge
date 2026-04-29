# BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup

> **STALE DATA — last refreshed 2023-09-18.** 31,322-row Google Ads ad group dictionary/lookup table. Maps ad_group_id to ad_group_name, campaign_id, and status. TRUNCATE+INSERT DISTINCT from Fivetran ad group performance report. Part of the SP_Adwords_Pref_Conv cluster (Table #12 of 12). Ad group statuses: ENABLED, PAUSED, REMOVED.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. TRUNCATE+INSERT DISTINCT (full refresh). |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 31,322 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Dictionary_AdGroup` is a **lookup/dictionary table** for Google Ads ad groups. Each row represents one distinct ad group with its campaign association and operational status. Used to resolve ad_group_id references in other Adwords tables (Geo_Conv, Geo_Pref, Keywords_Conv, Keywords_Pref, Ad_Conv, Ad_Pref, Search_Conv) to human-readable ad group names and statuses.

The SP (`SP_Adwords_Pref_Conv`) performs a TRUNCATE+INSERT DISTINCT from the Fivetran ad group performance report, extracting unique ad group records. This is Table #12 (last) in the SP. The ad_group_name column typically contains targeting metadata (language, keyword theme, match type) like 'EN_KW_ETF-LowIntent', 'FR_Investir Actions (Stocks Invest)_BMM'.

**DATA IS STALE**: Last updated 2023-09-18. The Fivetran connector has not synced since the Synapse migration.

---

## 2. Business Logic

### 2.1 Full Refresh Pattern

**What**: Entire table is rebuilt every run — no incremental logic.
**Columns Involved**: All columns
**Rules**:
- TRUNCATE TABLE removes all existing rows
- INSERT DISTINCT from Fivetran source (filtered WHERE name IS NOT NULL)
- Each ad group appears once with its most recent metadata

### 2.2 Ad Group Status Classification

**What**: Ad groups have one of three operational statuses.
**Columns Involved**: ad_group_status
**Rules**:
- ENABLED = actively serving ads
- PAUSED = temporarily stopped (can be resumed)
- REMOVED = permanently deleted from Google Ads

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution is ROUND_ROBIN with HEAP storage. Small table (31K rows) — full scan is fast. No index needed for typical lookup patterns.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve ad group name from ID | JOIN on ad_group_id |
| Count active vs paused ad groups | GROUP BY ad_group_status |
| Find ad groups for a campaign | WHERE campaign_id = @id |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Geo_Conv | ad_group_id | Resolve ad group name for geo conversion data |
| BI_DB_Adwords_Geo_Pref | ad_group_id | Resolve ad group name for geo performance data |
| BI_DB_Adwords_Keywords_Conv | ad_group_id | Resolve ad group name for keyword conversion data |
| BI_DB_Adwords_Keywords_Pref | ad_group_id | Resolve ad group name for keyword performance data |
| BI_DB_Adwords_Ad_Conv | ad_group_id | Resolve ad group name for ad conversion data |
| BI_DB_Adwords_Ad_Pref | ad_group_id | Resolve ad group name for ad performance data |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Chain to campaign metadata |

### 3.4 Gotchas

- **Data is STALE** — reflects ad group state as of 2023-09-18.
- **target_cpa is always NULL** — column exists in DDL but the SP does not populate it.
- **ad_group_id is NOT unique alone** — uniqueness requires (campaign_id, ad_group_id) pair, though in practice Google Ads ad_group_ids are globally unique.

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
| 1 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. Associates this ad group with its parent campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | ad_group_id | bigint | YES | Google Ads ad group identifier. Mapped from Fivetran `id` column. Primary lookup key for joining other Adwords tables. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | ad_group_name | nvarchar(256) | YES | Google Ads ad group display name. Mapped from Fivetran `name` column. Encodes targeting metadata: language, keyword theme, match type (e.g., 'EN_KW_ETF-LowIntent', 'AR_Stocks_Intent_Phrase'). (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | target_cpa | float | YES | Target cost-per-acquisition setting for the ad group. NOT populated by SP_Adwords_Pref_Conv — always NULL. Column exists in DDL but omitted from INSERT. (Tier 4 — inferred from DDL) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) |
| 6 | ad_group_status | nvarchar(256) | YES | Google Ads ad group operational status. ENABLED=actively serving, PAUSED=temporarily stopped, REMOVED=permanently deleted. Mapped from Fivetran `status` column. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| campaign_id | Fivetran Google Ads | campaign_id | Passthrough |
| ad_group_id | Fivetran Google Ads | id | Rename |
| ad_group_name | Fivetran Google Ads | name | Rename |
| target_cpa | N/A | N/A | Not populated |
| UpdateDate | SP | N/A | GETDATE() |
| ad_group_status | Fivetran Google Ads | status | Rename |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_adgroup_perf_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #12, P99) ---|
  |   TRUNCATE + INSERT DISTINCT WHERE name IS NOT NULL
  v
BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup (31,322 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Parent campaign metadata |

### 6.2 Referenced By (other objects point to this)

| Element | Referencing Object | Description |
|---------|-------------------|-------------|
| ad_group_id | BI_DB_Adwords_Geo_Conv | Ad group lookup for geo conversion data |
| ad_group_id | BI_DB_Adwords_Geo_Pref | Ad group lookup for geo performance data |
| ad_group_id | BI_DB_Adwords_Keywords_Conv | Ad group lookup for keyword conversion data |
| ad_group_id | BI_DB_Adwords_Keywords_Pref | Ad group lookup for keyword performance data |
| ad_group_id | BI_DB_Adwords_Ad_Conv | Ad group lookup for ad conversion data |
| ad_group_id | BI_DB_Adwords_Ad_Pref | Ad group lookup for ad performance data |

---

## 7. Sample Queries

### 7.1 Active Ad Groups per Campaign

```sql
SELECT c.campaign_name, COUNT(*) AS active_ad_groups
FROM [BI_DB_dbo].[BI_DB_Adwords_Dictionary_AdGroup] ag
JOIN [BI_DB_dbo].[BI_DB_Adwords_Dictionary_Campaign] c ON ag.campaign_id = c.campaign_id
WHERE ag.ad_group_status = 'ENABLED'
GROUP BY c.campaign_name
ORDER BY active_ad_groups DESC
```

### 7.2 Ad Group Status Distribution

```sql
SELECT ad_group_status, COUNT(*) AS cnt
FROM [BI_DB_dbo].[BI_DB_Adwords_Dictionary_AdGroup]
GROUP BY ad_group_status
ORDER BY cnt DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 4 T2, 0 T3, 1 T4, 1 T5 | Elements: 6/6, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | Type: Table | Production Source: Fivetran Google Ads*
