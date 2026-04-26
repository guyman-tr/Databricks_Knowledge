# BI_DB_dbo.BI_DB_Bing_PBI_Group_Dict

> 110,185-row Bing Ads ad group history dictionary (110,185 rows; 83,503 distinct ad groups across 604 campaigns) containing ad group metadata including name, status, bid strategy, and network distribution. TRUNCATE+INSERT on each SP_Bing_PBI run — full snapshot replacement. Source is the Fivetran `ad_group_history` feed from Microsoft Advertising. Last updated 2026-04-13 (feed remains active for dictionary tables even though the date-based performance tables stopped in October 2025).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Microsoft Advertising (Bing Ads) via Fivetran bingads connector → SP_Bing_PBI |
| **Refresh** | Daily (SB_Daily, Priority 20) — TRUNCATE + INSERT (full snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not exported to Unity Catalog |

---

## 1. Business Meaning

`BI_DB_Bing_PBI_Group_Dict` is the Bing Ads ad group reference/dimension table, holding the full history of 83,503 distinct ad groups across eToro's 604 Bing Ads campaigns. It is loaded by `SP_Bing_PBI` via TRUNCATE + INSERT from the Fivetran `ad_group_history` source, which preserves historical state changes — hence 110,185 total rows vs 83,503 distinct `id` values. The extra rows represent the same ad group at different points in time (history table pattern).

The table serves as a JOIN target for `BI_DB_Bing_PBI_Goals_Funnels` and `BI_DB_Bing_PBI_Daily_Perf` to resolve `ad_group_id` to human-readable ad group names and bid settings. Notable data characteristics: `id` is stored as varchar(max) despite containing bigint-valued identifiers (implicit type conversion from source), `cpc_bid` is numeric(18,0) which truncates decimal precision from the float source, and `maximum_bid` has NULLs replaced with 0.0.

The SP includes a comment `--need to fix` on the source table reference, suggesting known technical debt in the ETL source selection. Status values: Active (74.5%), Paused (25.4%), Deleted (0.1%), Expired (<0.1%).

---

## 2. Business Logic

### 2.1 History Table Deduplication (Imperfect)

**What**: The source `ad_group_history` table preserves every state change of each ad group. SP_Bing_PBI attempts deduplication via GROUP BY, but since the GROUP BY includes `_fivetran_synced`, each sync event creates a separate row.

**Columns Involved**: id, _fivetran_synced

**Rules**:
- `id` is NOT unique in this table (110,185 rows vs 83,503 distinct IDs)
- Multiple rows per `id` = different history snapshots (different _fivetran_synced timestamps)
- To get the current state of an ad group, query for the row with MAX(_fivetran_synced) per id
- Direct JOIN to Goals_Funnels/Daily_Perf on `id` alone will cause row multiplication — add `QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) = 1`

### 2.2 Type Conversions and Precision Loss

**What**: Source column types differ from DWH types in two cases, causing silent data changes.

**Columns Involved**: id, cpc_bid

**Rules**:
- `id`: Source is bigint (in external table DDL), DWH is varchar(max). No data loss but type mismatch breaks direct JOIN with Goals_Funnels.ad_group_id (bigint). Must CAST: `CAST(g.ad_group_id AS varchar) = d.id`
- `cpc_bid`: Source is float, DWH is numeric(18,0). Decimal places are truncated — a source value of 0.52 becomes 0. For most rows this is fine (many bids are round numbers) but introduces error for fractional CPC bids

### 2.3 Bid Strategy Pattern

**What**: eToro's ad groups almost universally inherit their bid strategy from the parent campaign.

**Columns Involved**: bid_strategy_type, inherited_bid_strategy_type

**Rules**:
- bid_strategy_type: 'InheritFromParent' for 99.9% of rows; NULL for 111 Deleted rows
- When bid_strategy_type='InheritFromParent', the actual applied strategy is in `inherited_bid_strategy_type` (typically 'EnhancedCpc')
- maximum_bid: always 0.0 (either originally 0 or replaced by ISNULL transform) — bid caps are managed at campaign level for eToro

### 2.4 Network Distribution

**What**: Where Bing shows ads across the Microsoft/Yahoo search network.

**Columns Involved**: network_distribution

**Rules**:
- 'OwnedAndOperatedAndSyndicatedSearch' = ads shown on Bing.com, MSN, and syndicated partner sites
- NULL for Deleted ad groups

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with 110,185 rows. Small reference table — full scans are fast. No distribution key needed. No clustered index — sequential scan or broadcast JOIN.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get current ad group name for performance data | JOIN on CAST(ad_group_id AS varchar) = id, with dedup: QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC)=1 |
| List all active ad groups for a campaign | WHERE campaign_id = @campaign_id AND status = 'Active' AND ROW_NUMBER() dedup |
| Count ad groups per campaign | GROUP BY campaign_id, count DISTINCT id |
| Find ad groups with fractional CPC bids | Cannot determine — decimal precision lost to numeric(18,0) truncation |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Bing_PBI_Goals_Funnels | CAST(gf.ad_group_id AS varchar) = d.id | Resolve ad_group_id to ad group name in goal reports |
| BI_DB_Bing_PBI_Daily_Perf | CAST(p.ad_group_id AS varchar) = d.id | Resolve ad_group_id in performance reports |
| BI_DB_Bing_PBI_Campaign_Dict | d.campaign_id = c.id | Get campaign context for ad group |

### 3.4 Gotchas

- **id is NOT unique**: Always deduplicate before JOINing — multiple history rows per ad group. Use ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) = 1 to get latest
- **Type mismatch on JOIN**: `id` is varchar, `ad_group_id` in Goals_Funnels and Daily_Perf is bigint. Must CAST one side to match
- **cpc_bid truncation**: numeric(18,0) loses all decimal precision from source float — fractional CPC bids appear as 0
- **maximum_bid always 0**: Genuine 0 values are indistinguishable from NULL-replaced values. Do not interpret maximum_bid=0 as "no max bid set"
- **SP `--need to fix` comment**: The source table `External_Fivetran_bingads_ad_group_history` has a comment in SP_Bing_PBI suggesting a known issue with this source reference
- **Feed status divergence**: This dictionary is still refreshed (last 2026-04-13) even though the daily performance tables stopped in 2025-10-16. The TRUNCATE+INSERT pattern means dictionary is current but has no new performance data to link to

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code, DDL, or external table definition |
| Tier 3 | Inferred from column name, data patterns, or business context |
| Tier 4 | Best available — limited confidence, needs review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | id | varchar(max) | YES | Bing Ads ad group identifier. Stored as varchar(max) despite containing bigint values (type conversion from source bigint). NOT unique — multiple rows per id due to history table source. 83,503 distinct ad groups. JOIN to Goals_Funnels/Daily_Perf requires CAST(ad_group_id AS varchar). (Tier 2 — External_Fivetran_bingads_ad_group_history) |
| 2 | status | varchar(max) | YES | Ad group lifecycle status from Microsoft Advertising. Values: Active (74.5%), Paused (25.4%), Deleted (0.1%), Expired (<0.1%). Deleted and Expired ad groups still appear in the table due to history source retention. (Tier 2 — External_Fivetran_bingads_ad_group_history) |
| 3 | campaign_id | bigint | YES | Bing Ads campaign identifier. FK to BI_DB_Bing_PBI_Campaign_Dict.id. 604 distinct campaigns in this table. (Tier 2 — External_Fivetran_bingads_ad_group_history) |
| 4 | name | varchar(max) | YES | Human-readable ad group name as configured in Microsoft Advertising. Typically reflects the keyword theme and match type (e.g., 'Invest_in_Axiall_Corp_Share_Exact', 'P CopyTrader'). Used to interpret ad_group_id in performance reports. (Tier 2 — External_Fivetran_bingads_ad_group_history) |
| 5 | bid_strategy_type | varchar(max) | YES | Bid strategy type set directly on the ad group. Values: 'InheritFromParent' (99.9%) — meaning bid strategy is controlled at the campaign level; NULL for 111 Deleted rows. When 'InheritFromParent', see `inherited_bid_strategy_type` for the applied strategy. (Tier 2 — External_Fivetran_bingads_ad_group_history) |
| 6 | cpc_bid | numeric(18, 0) | YES | Maximum cost-per-click bid at the ad group level, in account currency (USD/GBP depending on account). Stored as numeric(18,0) — decimal precision truncated from float source. A source value of 0.52 becomes 0. Many values are round numbers (0, 2, 6, 10). (Tier 2 — SP_Bing_PBI) |
| 7 | inherited_bid_strategy_type | varchar(max) | YES | The bid strategy actually applied to the ad group (inherited from parent campaign). Typically 'EnhancedCpc' — Microsoft Advertising automatically adjusts bids based on conversion likelihood. NULL for some Deleted rows. (Tier 2 — External_Fivetran_bingads_ad_group_history) |
| 8 | maximum_bid | float | YES | Maximum bid cap for the ad group. ISNULL transform applied by SP: NULL replaced with 0.0. In practice all rows show 0.0 — either the source was NULL or 0. Cannot distinguish between "no cap" and "cap set to zero". (Tier 2 — SP_Bing_PBI) |
| 9 | network_distribution | varchar(max) | YES | Microsoft Advertising network(s) where ads are served. Values: 'OwnedAndOperatedAndSyndicatedSearch' (Bing.com + MSN + syndicated partner sites) for Active/Paused groups; NULL for Deleted/Expired. (Tier 2 — External_Fivetran_bingads_ad_group_history) |
| 10 | _fivetran_synced | datetime | YES | Fivetran metadata: timestamp when this row was last synced by Fivetran. Used as a history key — multiple rows per `id` have different _fivetran_synced values. Use MAX(_fivetran_synced) per id to get the most recent snapshot. (Tier 2 — External_Fivetran_bingads_ad_group_history) |
| 11 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Bing_PBI (GETDATE() at SP execution time). All rows in a given load share the same UpdateDate (TRUNCATE+INSERT replaces all rows at once). Last value: 2026-04-13 05:31:52. (Tier 2 — SP_Bing_PBI) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| id | Bing Ads → ad_group_history | id (bigint) | Passthrough — bigint→varchar(max) implicit conversion |
| status | Bing Ads → ad_group_history | status | Passthrough |
| campaign_id | Bing Ads → ad_group_history | campaign_id | Passthrough |
| name | Bing Ads → ad_group_history | name | Passthrough |
| bid_strategy_type | Bing Ads → ad_group_history | bid_strategy_type | Passthrough |
| cpc_bid | Bing Ads → ad_group_history | cpc_bid (float) | Passthrough — float→numeric(18,0) truncation |
| inherited_bid_strategy_type | Bing Ads → ad_group_history | inherited_bid_strategy_type | Passthrough |
| maximum_bid | Bing Ads → ad_group_history | maximum_bid | ISNULL(maximum_bid, 0) |
| network_distribution | Bing Ads → ad_group_history | network_distribution | Passthrough |
| _fivetran_synced | Bing Ads → ad_group_history | _fivetran_synced | Passthrough |
| UpdateDate | SP_Bing_PBI | — | GETDATE() |

### 5.2 ETL Pipeline

```
Microsoft Advertising (Bing Ads) — ad group history endpoint
  |-- Fivetran bingads connector (synced daily, feed active as of 2026-04-13) ---|
  v
Azure Data Lake: Bronze/Fivetran/bingads/ad_group_history (Parquet)
  |-- External_Fivetran_bingads_ad_group_history ---|
  v
SP_Bing_PBI @date
  |-- TRUNCATE TABLE BI_DB_Bing_PBI_Group_Dict ---|
  |-- INSERT: SELECT ... GROUP BY all cols (dedup) with ISNULL(maximum_bid,0) ---|
  v
BI_DB_dbo.BI_DB_Bing_PBI_Group_Dict (110,185 rows, 83,503 distinct ad groups)
  |-- NOT exported to Unity Catalog (_Not_Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict.id | Resolve campaign_id to campaign name and settings |

### 6.2 Referenced By

| Object | Join Column | Description |
|--------|------------|-------------|
| BI_DB_dbo.BI_DB_Bing_PBI_Goals_Funnels | ad_group_id CAST to varchar = id | Resolve ad group in goal funnel reports |
| BI_DB_dbo.BI_DB_Bing_PBI_Daily_Perf | ad_group_id CAST to varchar = id | Resolve ad group in keyword performance reports |

---

## 7. Sample Queries

### Get Current Ad Group Names for Goals Report (Deduped)

```sql
WITH LatestGroups AS (
    SELECT 
        id,
        name,
        status,
        campaign_id,
        bid_strategy_type,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
    FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Group_Dict]
)
SELECT 
    g.date,
    g.campaign_id,
    d.name AS ad_group_name,
    d.status AS ad_group_status,
    SUM(ISNULL(g.Bing_Registration, 0)) AS registrations,
    SUM(ISNULL(g.Bing_FTD, 0)) AS ftd
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Goals_Funnels] g
LEFT JOIN LatestGroups d ON CAST(g.ad_group_id AS varchar) = d.id AND d.rn = 1
WHERE g.date >= '2024-01-01'
GROUP BY g.date, g.campaign_id, d.name, d.status
ORDER BY registrations DESC
```

### Active Ad Groups by Campaign

```sql
SELECT 
    campaign_id,
    COUNT(DISTINCT id) AS active_ad_groups
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Group_Dict]
WHERE status = 'Active'
GROUP BY campaign_id
ORDER BY active_ad_groups DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. It is a companion dictionary to `BI_DB_Bing_PBI_Daily_Perf` and `BI_DB_Bing_PBI_Goals_Funnels`, loaded by the same SP_Bing_PBI.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4 | Elements: 11/11, Logic: 9/10, ETL: confirmed, Data Evidence: live*
*Object: BI_DB_dbo.BI_DB_Bing_PBI_Group_Dict | Type: Table | Production Source: Fivetran bingads ad_group_history*
