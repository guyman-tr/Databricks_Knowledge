# BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign

> **STALE DATA — last refreshed 2023-09-18.** 1,740-row Google Ads campaign dictionary/lookup table. Maps campaign_id to campaign_name, bidding_strategy_type, daily budget amount, and status. TRUNCATE+INSERT DISTINCT from Fivetran campaign performance report. Part of the SP_Adwords_Pref_Conv cluster (Table #11 of 12). Campaign statuses: enabled (398), paused (1,328), removed (14). Bidding strategies: Target CPA (75%), Maximize Conversions (19%), cpc (3%).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_campaign_perf_perf_campaign_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. TRUNCATE+INSERT DISTINCT (full refresh). |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 1,740 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Dictionary_Campaign` is a **lookup/dictionary table** for Google Ads campaigns. Each row represents one distinct campaign with its bidding strategy, daily budget, and operational status. Used to resolve campaign_id references across all other Adwords tables in the cluster.

The SP (`SP_Adwords_Pref_Conv`) performs a TRUNCATE+INSERT DISTINCT from the Fivetran campaign performance report. This is Table #11 in the SP. Campaign names encode rich targeting metadata including region, product vertical, channel, language, and affiliate ID (e.g., 'UK_NB_SocialTrading_______EN_38638', 'DE_YTR_Alter-Mix_Registrations_Alter_____EN_67638').

**DATA IS STALE**: Last updated 2023-09-18. The Fivetran connector has not synced since the Synapse migration.

---

## 2. Business Logic

### 2.1 Full Refresh Pattern

**What**: Entire table is rebuilt every run.
**Columns Involved**: All columns
**Rules**:
- TRUNCATE TABLE removes all existing rows
- INSERT DISTINCT from Fivetran source (filtered WHERE campaign_name IS NOT NULL)
- Each campaign appears once with its current metadata

### 2.2 Bidding Strategy Classification

**What**: Campaigns use different Google Ads bidding strategies that affect spend optimization.
**Columns Involved**: bidding_strategy_type
**Rules**:
- Target CPA = automated bidding targeting a specific cost-per-acquisition (dominant: 75%)
- Maximize Conversions = automated bidding to maximize total conversions within budget (19%)
- cpc = manual cost-per-click bidding (3%)
- cpv = cost-per-view for video campaigns (<1%)
- Maximize clicks = automated bidding for click volume (<1%)
- Empty string = no strategy assigned (2%)

### 2.3 Campaign Status

**What**: Operational status of each campaign.
**Columns Involved**: campaign_status
**Rules**:
- enabled = actively serving ads
- paused = temporarily stopped
- removed = permanently deleted
- Note: status values are lowercase (unlike ad_group_status which is uppercase)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution is ROUND_ROBIN with HEAP storage. Small table (1,740 rows) — full scan is near-instant.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve campaign name from ID | JOIN on campaign_id |
| Campaigns by bidding strategy | GROUP BY bidding_strategy_type |
| Active campaign count | WHERE campaign_status = 'enabled' |
| Campaign budget distribution | SELECT amount, COUNT(*) GROUP BY amount |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Conversion_Performance_Report | campaign_id | Campaign name for conversion data |
| BI_DB_Adwords_Campaign_Performance_Report | campaign_id | Campaign metadata for performance data |
| BI_DB_Adwords_Geo_Conv / Geo_Pref | campaign_id | Campaign name for geographic data |
| BI_DB_Adwords_Keywords_Conv / Keywords_Pref | campaign_id | Campaign name for keyword data |
| BI_DB_Adwords_Ad_Conv / Ad_Pref | campaign_id | Campaign name for ad-level data |
| BI_DB_Adwords_Search_Conv | campaign_id | Campaign name for search query data |
| BI_DB_Adwords_Dictionary_AdGroup | campaign_id | Ad groups belonging to this campaign |

### 3.4 Gotchas

- **Data is STALE** — reflects campaign state as of 2023-09-18.
- **campaign_status is lowercase** ('enabled', 'paused', 'removed') while ad_group_status in Dictionary_AdGroup is UPPERCASE ('ENABLED', 'PAUSED', 'REMOVED'). Case-sensitive comparisons will break.
- **amount is daily budget** — in the account's currency (typically USD). Values like 600.0, 750.0 observed.
- **bidding_strategy_type has empty strings** — 40 campaigns with no strategy assigned.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | campaign_id | bigint | YES | Google Ads campaign identifier. Primary lookup key for joining all other Adwords tables. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | campaign_name | nvarchar(256) | YES | Google Ads campaign display name. Encodes targeting metadata: region, product vertical, channel, language, affiliate ID (e.g., 'UK_NB_SocialTrading_______EN_38638'). Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | bidding_strategy_type | nvarchar(256) | YES | Google Ads automated bidding strategy. Target CPA, Maximize Conversions, cpc, cpv, Maximize clicks, or empty. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | amount | float | YES | Campaign daily budget in account currency (typically USD). Values like 600.0, 750.0 observed. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) |
| 6 | campaign_status | varchar(256) | YES | Google Ads campaign operational status. enabled=actively serving, paused=temporarily stopped, removed=permanently deleted. Note: lowercase values (unlike Dictionary_AdGroup which uses UPPERCASE). (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| campaign_id | Fivetran Google Ads | campaign_id | Passthrough |
| campaign_name | Fivetran Google Ads | campaign_name | Passthrough |
| bidding_strategy_type | Fivetran Google Ads | bidding_strategy_type | Passthrough |
| amount | Fivetran Google Ads | amount | Passthrough |
| UpdateDate | SP | N/A | GETDATE() |
| campaign_status | Fivetran Google Ads | campaign_status | Passthrough |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_campaign_perf schema) ---|
  v
External_Bronze_Fivetran_adwords_campaign_perf_perf_campaign_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #11, P99) ---|
  |   TRUNCATE + INSERT DISTINCT WHERE campaign_name IS NOT NULL
  v
BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign (1,740 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

No outbound references — this is a root lookup table.

### 6.2 Referenced By (other objects point to this)

| Element | Referencing Object | Description |
|---------|-------------------|-------------|
| campaign_id | BI_DB_Adwords_Conversion_Performance_Report | Campaign metadata for conversion report |
| campaign_id | BI_DB_Adwords_Campaign_Performance_Report | Campaign metadata for performance report |
| campaign_id | BI_DB_Adwords_Geo_Conv | Campaign metadata for geo conversions |
| campaign_id | BI_DB_Adwords_Geo_Pref | Campaign metadata for geo performance |
| campaign_id | BI_DB_Adwords_Keywords_Conv | Campaign metadata for keyword conversions |
| campaign_id | BI_DB_Adwords_Keywords_Pref | Campaign metadata for keyword performance |
| campaign_id | BI_DB_Adwords_Ad_Conv | Campaign metadata for ad conversions |
| campaign_id | BI_DB_Adwords_Ad_Pref | Campaign metadata for ad performance |
| campaign_id | BI_DB_Adwords_Search_Conv | Campaign metadata for search query conversions |
| campaign_id | BI_DB_Adwords_Dictionary_AdGroup | Campaign-to-ad-group hierarchy |

---

## 7. Sample Queries

### 7.1 Campaigns by Bidding Strategy

```sql
SELECT bidding_strategy_type, campaign_status,
       COUNT(*) AS campaigns, AVG(amount) AS avg_budget
FROM [BI_DB_dbo].[BI_DB_Adwords_Dictionary_Campaign]
GROUP BY bidding_strategy_type, campaign_status
ORDER BY campaigns DESC
```

### 7.2 Active Campaigns with Highest Budget

```sql
SELECT campaign_id, campaign_name, bidding_strategy_type, amount
FROM [BI_DB_dbo].[BI_DB_Adwords_Dictionary_Campaign]
WHERE campaign_status = 'enabled'
ORDER BY amount DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 6/6, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | Type: Table | Production Source: Fivetran Google Ads*
