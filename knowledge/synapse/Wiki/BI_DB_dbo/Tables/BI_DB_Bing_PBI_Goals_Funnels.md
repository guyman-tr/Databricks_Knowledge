# BI_DB_dbo.BI_DB_Bing_PBI_Goals_Funnels

> 139,237-row Bing Ads goal conversion tracking table (2022-01-01 to 2025-10-16) pivoting goal-type rows from the Fivetran daily report into 9 sparse conversion columns. Each row represents one source goal event at keyword×ad-group×campaign×account×date×device granularity, with exactly one goal column non-NULL per row. The Fivetran feed appears stopped as of 2025-10-16. Loaded daily via SP_Bing_PBI using DELETE-by-date + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Microsoft Advertising (Bing Ads) via Fivetran bingads connector → SP_Bing_PBI |
| **Refresh** | Daily (SB_Daily, Priority 20) — DELETE by date + INSERT from external table |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not exported to Unity Catalog |

---

## 1. Business Meaning

`BI_DB_Bing_PBI_Goals_Funnels` is the Bing Ads goal conversion tracking table, holding 139,237 rows from 2022-01-01 to 2025-10-16 across 5 accounts, 171 campaigns, and 7,310 keywords. Each row in the source Fivetran table (`External_Fivetran_bingads_goals_and_funnels_daily_report`) corresponds to a single goal conversion event for a specific keyword×date×device combination. The ETL SP (`SP_Bing_PBI`) pivots these goal-type rows into 9 dedicated columns using `CASE WHEN goal = '...' THEN all_conversions - view_through_conversions END`, resulting in a sparse table where each row has exactly one goal column non-NULL.

The 9 tracked goals span the eToro customer acquisition funnel: Bing_Registration and Registration_General/Brand capture registrations; Bing_FTD and FTD_General/Brand capture first-time deposits; Bing_Multiple_Deposit/Tag tracks repeat depositors; Bing_V2_Complete tracks onboarding completion events. All goal values represent **click-through conversions only** (`all_conversions - view_through_conversions`) — view-through conversions are deliberately excluded. Rows where the source `goal` value does not match any of the 9 mapped goal names (36,100 rows = 26%) will have all 9 conversion columns NULL and represent unrecognized or deprecated goal types.

The Fivetran feed appears stopped as of 2025-10-16, consistent with `BI_DB_Bing_PBI_Daily_Perf`. This table is consumed directly by Power BI for paid search conversion funnel reporting.

---

## 2. Business Logic

### 2.1 Goal Pivot Pattern (Sparse Column Encoding)

**What**: The source table has a `goal` text column identifying which conversion goal a row represents. The SP pivots this into 9 separate columns, each receiving a value only when the row's goal matches.

**Columns Involved**: Registration_General, Bing_Multiple_Deposit_Tag, Bing_Multiple_Deposit, FTD_General, Registration_Brand, FTD_Brand, Bing_V2_Complete, Bing_Registration, Bing_FTD

**Rules**:
- Each row has **at most one** non-NULL goal conversion column
- `all_conversions - view_through_conversions` = click-through conversions only. View-through conversions (impressions without click that led to conversion) are excluded from all 9 columns
- Source goal name vs DWH column name mapping: 'Registration_General'→Registration_General, 'Bing Multiple Deposit Tag'→Bing_Multiple_Deposit_Tag, 'Bing Multiple Deposit'→Bing_Multiple_Deposit, 'FTD_General'→FTD_General, 'Registration_Brand'→Registration_Brand, 'FTD_Brand'→FTD_Brand, 'Bing V2 Complete'→Bing_V2_Complete, 'Bing Registration'→Bing_Registration, 'Bing FTD'→Bing_FTD (note: source uses spaces, DWH uses underscores with PascalCase)
- Rows with source `goal` not matching any of the 9 mapped values: all 9 conversion columns are NULL. These rows still exist in the table with valid grain identifiers (26% of total rows)

### 2.2 Goal Distribution

**What**: Goal prevalence varies significantly across the 9 conversion types.

**Columns Involved**: All 9 goal columns

**Rules**:
- Bing_Registration: 30,057 rows (21.6%) — most frequent goal type
- Registration_General: 24,428 rows (17.5%)
- Bing_V2_Complete: 22,250 rows (16.0%) — onboarding completion
- Bing_Multiple_Deposit: 12,053 rows (8.7%)
- Bing_FTD: 6,622 rows (4.8%)
- Bing_Multiple_Deposit_Tag: 2,666 rows (1.9%) — tag variant of Multiple Deposit
- FTD_General: 2,083 rows (1.5%)
- Registration_Brand: 2,023 rows (1.5%)
- FTD_Brand: 955 rows (0.7%)
- All 9 columns NULL (unrecognized goal): 36,100 rows (25.9%)

### 2.3 Device Dimension

**What**: Traffic is classified by device type; device_os provides OS granularity.

**Columns Involved**: device_type, device_os

**Rules**:
- device_type values: Computer (95.3%), Smartphone (4.2%), Tablet (0.5%)
- device_os is sourced as-is from Bing Ads — typically Windows, iOS, Android, Other
- Bing Ads reports conversions predominantly on Computer for eToro's audience

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on `date`. Queries filtering by date will benefit from the clustered index scan. No distribution skew concerns. For goal funnel aggregations, summing across all rows for a date range with SUM(ISNULL(Registration_General, 0)) is the correct pattern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total registrations from Bing for a date range | `SELECT SUM(ISNULL(Registration_General,0)) + SUM(ISNULL(Registration_Brand,0)) + SUM(ISNULL(Bing_Registration,0)) FROM ... WHERE date BETWEEN @start AND @end` |
| FTD conversion rate by campaign | JOIN with BI_DB_Bing_PBI_Daily_Perf on campaign_id+date, divide SUM(FTD_General+FTD_Brand+Bing_FTD) by SUM(clicks) |
| Goal performance by device | GROUP BY device_type with SUM(ISNULL(each_goal,0)) |
| Multiple deposit funnel depth | Compare Bing_Multiple_Deposit vs Bing_FTD vs Bing_Multiple_Deposit_Tag to understand user re-engagement |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Bing_PBI_Daily_Perf | campaign_id + ad_group_id + keyword_id + date + device_type + device_os | Combine spend/impressions/clicks with goal conversions for full performance picture |
| BI_DB_Bing_PBI_Campaign_Dict | campaign_id | Resolve campaign_id to campaign name and bid strategy |
| BI_DB_Bing_PBI_Group_Dict | ad_group_id (via campaign_id) | Resolve ad_group_id to ad group name |

### 3.4 Gotchas

- **Sparse NULL rows**: 26% of rows have ALL 9 goal columns NULL. Do NOT use COUNT(*) to count conversions — use SUM(ISNULL(column, 0)) or count non-NULL values
- **No view-through conversions**: Goal counts deliberately exclude view-through conversions (impressions that led to conversions without a click). This differs from total `all_conversions` in the source
- **Goal overlap vs distinct counts**: The Registration column trio (Registration_General + Registration_Brand + Bing_Registration) and FTD trio (FTD_General + FTD_Brand + Bing_FTD) may double-count the same customer — they are different Bing goal tags, not mutually exclusive at the customer level
- **Feed stopped 2025-10-16**: No new data since 2025-10-16. Consistent with BI_DB_Bing_PBI_Daily_Perf. Confirm with Marketing/BI team before using for current reporting
- **Grain key not enforced**: Same as Daily_Perf — no unique constraint on account_id+campaign_id+ad_group_id+keyword_id+date+device_type+device_os+goal. Multiple rows for same grain are possible if Fivetran delivers duplicates

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
| 1 | date | date | YES | Report date for the goal conversion event. Bing Ads reports at the keyword×date grain. DELETE+INSERT pattern: all rows for this date are replaced daily. Last loaded date: 2025-10-16 (Fivetran feed may be stopped). (Tier 2 — SP_Bing_PBI) |
| 2 | account_id | bigint | YES | Bing Ads account identifier. 5 distinct accounts in the dataset, corresponding to eToro's Bing Ads account portfolio. (Tier 2 — External_Fivetran_bingads_goals_and_funnels_daily_report) |
| 3 | campaign_id | bigint | YES | Bing Ads campaign identifier. 171 distinct campaigns. FK to BI_DB_Bing_PBI_Campaign_Dict.id for campaign name and bid strategy details. (Tier 2 — External_Fivetran_bingads_goals_and_funnels_daily_report) |
| 4 | ad_group_id | bigint | YES | Bing Ads ad group identifier. FK to BI_DB_Bing_PBI_Group_Dict.id (stored as varchar in Group_Dict — implicit type coercion) for ad group name and bid settings. (Tier 2 — External_Fivetran_bingads_goals_and_funnels_daily_report) |
| 5 | keyword_id | bigint | YES | Bing Ads keyword identifier. 7,310 distinct keywords tracked. (Tier 2 — External_Fivetran_bingads_goals_and_funnels_daily_report) |
| 6 | device_type | varchar(100) | YES | Device category for the ad impression and conversion. Values: Computer (95.3%), Smartphone (4.2%), Tablet (0.5%). (Tier 2 — External_Fivetran_bingads_goals_and_funnels_daily_report) |
| 7 | device_os | varchar(100) | YES | Operating system of the device. Values from Bing Ads: Windows, iOS, Android, Other. NULL for some Computer rows where OS is not specified. (Tier 2 — External_Fivetran_bingads_goals_and_funnels_daily_report) |
| 8 | Registration_General | bigint | YES | Click-through conversion count for the 'Registration_General' Bing goal. Populated only when the source row's `goal`='Registration_General', NULL otherwise (sparse). Formula: all_conversions - view_through_conversions. Non-NULL in 24,428 rows (17.5%). (Tier 2 — SP_Bing_PBI) |
| 9 | Bing_Multiple_Deposit_Tag | bigint | YES | Click-through conversion count for the 'Bing Multiple Deposit Tag' Bing goal (tag-based variant of multiple deposit tracking). Sparse — non-NULL in 2,666 rows (1.9%). Formula: all_conversions - view_through_conversions. (Tier 2 — SP_Bing_PBI) |
| 10 | Bing_Multiple_Deposit | bigint | YES | Click-through conversion count for the 'Bing Multiple Deposit' Bing goal (repeat deposit tracking for existing customers). Sparse — non-NULL in 12,053 rows (8.7%). Formula: all_conversions - view_through_conversions. (Tier 2 — SP_Bing_PBI) |
| 11 | FTD_General | bigint | YES | Click-through conversion count for the 'FTD_General' Bing goal (general first-time deposit tracking, not brand-specific). Sparse — non-NULL in 2,083 rows (1.5%). Formula: all_conversions - view_through_conversions. (Tier 2 — SP_Bing_PBI) |
| 12 | Registration_Brand | bigint | YES | Click-through conversion count for the 'Registration_Brand' Bing goal (brand-keyword registration tracking). Sparse — non-NULL in 2,023 rows (1.5%). Formula: all_conversions - view_through_conversions. (Tier 2 — SP_Bing_PBI) |
| 13 | FTD_Brand | bigint | YES | Click-through conversion count for the 'FTD_Brand' Bing goal (brand-keyword first-time deposit tracking). Sparse — non-NULL in 955 rows (0.7%). Formula: all_conversions - view_through_conversions. (Tier 2 — SP_Bing_PBI) |
| 14 | Bing_V2_Complete | bigint | YES | Click-through conversion count for the 'Bing V2 Complete' Bing goal (V2 onboarding completion tracking). Sparse — non-NULL in 22,250 rows (16.0%). Formula: all_conversions - view_through_conversions. (Tier 2 — SP_Bing_PBI) |
| 15 | Bing_Registration | bigint | YES | Click-through conversion count for the 'Bing Registration' Bing goal (Bing-specific registration tag, most frequent goal type). Sparse — non-NULL in 30,057 rows (21.6%). Formula: all_conversions - view_through_conversions. (Tier 2 — SP_Bing_PBI) |
| 16 | Bing_FTD | bigint | YES | Click-through conversion count for the 'Bing FTD' Bing goal (Bing-specific first-time deposit tag). Sparse — non-NULL in 6,622 rows (4.8%). Formula: all_conversions - view_through_conversions. (Tier 2 — SP_Bing_PBI) |
| 17 | _fivetran_synced | datetime | YES | Fivetran metadata: timestamp when this row was last synced by Fivetran. (Tier 2 — External_Fivetran_bingads_goals_and_funnels_daily_report) |
| 18 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Bing_PBI (GETDATE() at SP execution time). (Tier 2 — SP_Bing_PBI) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| date | Bing Ads API → goals_and_funnels_daily_report | date | Passthrough |
| account_id | Bing Ads API → goals_and_funnels_daily_report | account_id | Passthrough |
| campaign_id | Bing Ads API → goals_and_funnels_daily_report | campaign_id | Passthrough |
| ad_group_id | Bing Ads API → goals_and_funnels_daily_report | ad_group_id | Passthrough |
| keyword_id | Bing Ads API → goals_and_funnels_daily_report | keyword_id | Passthrough |
| device_type | Bing Ads API → goals_and_funnels_daily_report | device_type | Passthrough |
| device_os | Bing Ads API → goals_and_funnels_daily_report | device_os | Passthrough |
| Registration_General..Bing_FTD (9 cols) | Bing Ads API → goals_and_funnels_daily_report | goal + all_conversions + view_through_conversions | CASE pivot: each col = all_conversions-view_through_conversions when goal matches |
| _fivetran_synced | Bing Ads API → goals_and_funnels_daily_report | _fivetran_synced | Passthrough |
| UpdateDate | SP_Bing_PBI | — | GETDATE() |

### 5.2 ETL Pipeline

```
Microsoft Advertising (Bing Ads) — goals_and_funnels_daily_report endpoint
  |-- Fivetran bingads connector (synced daily) ---|
  v
Azure Data Lake: Bronze/Fivetran/bingads/goals_and_funnels_daily_report (Parquet)
  |-- External_Fivetran_bingads_goals_and_funnels_daily_report ---|
  v
SP_Bing_PBI @date
  |-- DELETE FROM BI_DB_Bing_PBI_Goals_Funnels WHERE date=@date ---|
  |-- INSERT: CASE WHEN goal='...' THEN all_conversions-view_through_conversions END ---|
  v
BI_DB_dbo.BI_DB_Bing_PBI_Goals_Funnels (139,237 rows, 2022-01-01 to 2025-10-16)
  |-- NOT exported to Unity Catalog (_Not_Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict.id | Resolve campaign name, bid strategy, status |
| ad_group_id | BI_DB_dbo.BI_DB_Bing_PBI_Group_Dict.id | Resolve ad group name and bid settings (note: id is varchar in Group_Dict, bigint here) |

### 6.2 Referenced By

No known tables join to BI_DB_Bing_PBI_Goals_Funnels. Power BI reports consume it directly.

---

## 7. Sample Queries

### Total Click-Through Registrations by Month (2024)

```sql
SELECT 
    YEAR(date) AS yr,
    MONTH(date) AS mo,
    SUM(ISNULL(Registration_General, 0)) AS reg_general,
    SUM(ISNULL(Registration_Brand, 0)) AS reg_brand,
    SUM(ISNULL(Bing_Registration, 0)) AS bing_registration,
    SUM(ISNULL(Registration_General, 0) + ISNULL(Registration_Brand, 0) + ISNULL(Bing_Registration, 0)) AS total_registrations
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Goals_Funnels]
WHERE date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY YEAR(date), MONTH(date)
ORDER BY yr, mo
```

### Goal Performance by Campaign (All-Time)

```sql
SELECT 
    g.campaign_id,
    c.name AS campaign_name,
    SUM(ISNULL(g.Bing_Registration, 0) + ISNULL(g.Registration_General, 0) + ISNULL(g.Registration_Brand, 0)) AS total_registrations,
    SUM(ISNULL(g.Bing_FTD, 0) + ISNULL(g.FTD_General, 0) + ISNULL(g.FTD_Brand, 0)) AS total_ftd,
    SUM(ISNULL(g.Bing_V2_Complete, 0)) AS total_v2_complete
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Goals_Funnels] g
LEFT JOIN [BI_DB_dbo].[BI_DB_Bing_PBI_Campaign_Dict] c ON g.campaign_id = c.id
GROUP BY g.campaign_id, c.name
ORDER BY total_registrations DESC
```

### Rows with No Matching Goal (Unrecognized Goal Types)

```sql
-- These rows have all 9 goal columns NULL — represents unrecognized/deprecated goal names in Bing
SELECT COUNT(*) AS unrecognized_goal_rows
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Goals_Funnels]
WHERE Registration_General IS NULL
  AND Bing_Multiple_Deposit_Tag IS NULL
  AND Bing_Multiple_Deposit IS NULL
  AND FTD_General IS NULL
  AND Registration_Brand IS NULL
  AND FTD_Brand IS NULL
  AND Bing_V2_Complete IS NULL
  AND Bing_Registration IS NULL
  AND Bing_FTD IS NULL
-- Returns ~36,100 rows
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. It is a Bing Ads Fivetran feed companion to `BI_DB_Bing_PBI_Daily_Perf` (same SP, same source, deferred one batch).

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 0 T1, 18 T2, 0 T3, 0 T4 | Elements: 18/18, Logic: 8/10, ETL: confirmed, Data Evidence: live*
*Object: BI_DB_dbo.BI_DB_Bing_PBI_Goals_Funnels | Type: Table | Production Source: Fivetran bingads goals_and_funnels_daily_report*
