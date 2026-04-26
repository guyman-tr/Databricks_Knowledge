# BI_DB_dbo.BI_DB_FB_Performance

> 595K-row Facebook Ads performance table capturing daily spend, impressions, and click metrics per ad per date, covering Oct 2020–Jan 2026. Each row is a unique (date × ad_id × adset_id × campaign_id × account_id × ad_name) combination aggregated from the Fivetran `facebook_preformance_new` external feed. **Feed is inactive** — last data date is 2026-01-07 (last ETL run: 2026-01-15). Written by the first block of `SP_FB_Perf_Conv` via an 8-day rolling DELETE+INSERT; device_platform is aggregated over (not preserved). Two Facebook ad accounts: "eToro ALL 2 (Smartly)" ($70.9M spend, 409K rows) and "eToro Account" ($3.9M, 186K rows). Total: $74.9M spend, 121.6M clicks, 14.6B impressions across 5+ years.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Facebook Ads API via Fivetran (`External_Fivetran_facebook_facebook_preformance_new`, Bronze lake: `Bronze/Fivetran/facebook/facebook_preformance_new`) |
| **Refresh** | Daily (inactive since 2026-01-15) — DELETE 8-day rolling window + INSERT via `SP_FB_Perf_Conv` |
| **OpsDB Priority** | 20 (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_FB_Performance` tracks **Facebook Ads media performance metrics** — how many times ads were shown (impressions), clicked, and how much was spent — at the ad × date grain. One row per unique combination of (date, ad_id, adset_id, campaign_id, account_id, ad_name, adset_name, campaign_name, account_name), with clicks/impressions/spend aggregated across device platforms (device breakdown is available in the source external table but collapsed at this layer).

The table is consumed by `SP_FB_Report` — filtered to `account_name = 'eToro ALL 2 (Smartly)'` only — and FULL OUTER JOINed with `BI_DB_FB_Conversion` to produce the combined Facebook Ads report in `BI_DB_FB_Report`. The report also parses `campaign_name` to extract Country (prefix before first `_`) and Funnel (segment between first and second `_`), and cross-references internal FTD/Reg data from `BI_DB_CIDFirstDates` for attribution comparison.

**Feed status**: The Fivetran Facebook Ads performance feed stopped providing new data after 2026-01-07 (last UpdateDate: 2026-01-15). This is the same cutoff date as `BI_DB_FB_Conversion` — both tables share the same SP and Fivetran connector lifecycle.

**Two Facebook accounts**:
- `eToro ALL 2 (Smartly)`: 409,193 rows (~69%), $70.9M spend — eToro's primary account managed via Smartly.io automation platform. This is the account used by `SP_FB_Report`.
- `eToro Account`: 186,423 rows (~31%), $3.9M spend — secondary direct account; not used in the current report SP.

**Grain**: One row per unique (date × ad × adset × campaign × account × all name fields) after aggregating over `device_platform`. 21,949 distinct Facebook ad IDs observed. No all-zero rows — every row represents at least some ad activity.

Total across all time: $74.9M spend, 121.6M clicks, 14.6B impressions.

---

## 2. Business Logic

### 2.1 8-Day Rolling Refresh Window

**What**: Same rolling DELETE+INSERT pattern used for `BI_DB_FB_Conversion` in the same SP execution. Facebook may retroactively adjust spend, impression, and click data for the attribution window.

**Columns Involved**: date, (all columns via rolling delete)

**Rules**:
- `@FromDate = @date - 7 days`; `@Today = @date + 1 day`
- `DELETE WHERE date >= @FromDate AND date < @Today` — erases 8 days of data
- Both `BI_DB_FB_Performance` (block 1) and `BI_DB_FB_Conversion` (block 2) share the same date window variables within the same SP call

### 2.2 device_platform Aggregation

**What**: The source external table `External_Fivetran_facebook_facebook_preformance_new` contains a `device_platform` column (e.g., mobile_app, desktop), but `SP_FB_Perf_Conv` does NOT include `device_platform` in the GROUP BY. This means all device-level rows for the same (date, ad_id, adset_id, ...) are collapsed into a single row in this table.

**Columns Involved**: clicks, impressions, spend

**Rules**:
- `SUM(ISNULL(clicks, 0))`, `SUM(ISNULL(impressions, 0))`, `SUM(ISNULL(spend, 0))` — summed across all device platforms
- No device-level breakdown is available in this table; query the external table directly for device splits
- ISNULL(..., 0) ensures zero rather than NULL when no activity for a metric on a given device

### 2.3 date_id Computation

**What**: date_id is a computed integer encoding of the date column.

**Columns Involved**: date_id, date

**Rules**:
- `date_id = BI_DB_dbo.DateToDateID([date])` — converts DATE to int in YYYYMMDD format
- date_id bigint (not int) — consistent with the schema's date key type for this family of tables
- date (DATE type) and date_id (bigint) carry redundant information; date_id is provided for JOIN compatibility

### 2.4 Campaign Name Parsing in Downstream Report

**What**: `SP_FB_Report` (downstream consumer) parses `campaign_name` to extract Country and Funnel dimensions used in reporting.

**Columns Involved**: campaign_name (via SP_FB_Report)

**Rules**:
- `Country = LEFT(campaign_name, CHARINDEX('_', campaign_name) - 1)` — country code prefix before first underscore (e.g., "GB", "DE", "US")
- `Funnel = SUBSTRING(campaign_name, CHARINDEX('_',campaign_name)+1, CHARINDEX('_',campaign_name,CHARINDEX('_',campaign_name)+1) - CHARINDEX('_',campaign_name) - 1)` — segment between first and second underscores
- Campaign naming convention: `{Country}_{Funnel}_...`
- Known Country codes: GB, DE, US, FR, AU, IT, ES, NL, PL, RO, CZ, DK, SE, NO, FI, ROE, ARAB, GCC, SEA, LATAM, MX, IE
- Only `account_name = 'eToro ALL 2 (Smartly)'` rows are processed in SP_FB_Report

---

## 3. Query Advisory

### 3.1 Distribution and Index

- **ROUND_ROBIN + HEAP**: No clustered index; full scan is acceptable for this medium table (595K rows). The 8-day rolling window queries are efficient via date predicate.
- No distribution key needed — ad_id cardinality is high; campaign_id would be a better candidate but the table is not partitioned.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total spend by campaign in a period | `WHERE date BETWEEN @start AND @end GROUP BY campaign_id, campaign_name SUM(spend)` |
| Top ads by clicks | `WHERE date BETWEEN @start AND @end GROUP BY ad_id, ad_name ORDER BY SUM(clicks) DESC` |
| Daily CPM (cost per 1000 impressions) | `WHERE date=@d; spend/impressions*1000` |
| Smartly account data only | `WHERE account_name = 'eToro ALL 2 (Smartly)'` |
| Performance + conversion combined | JOIN BI_DB_FB_Conversion ON date=date AND ad_id=ad_id (mirror of SP_FB_Report logic) |
| Feed freshness check | `SELECT MAX(date), MAX(UpdateDate) FROM BI_DB_FB_Performance` (last: 2026-01-07 / 2026-01-15) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_FB_Conversion | date=date AND ad_id=ad_id | Combine spend/impressions/clicks with conversion funnel metrics |
| BI_DB_FB_Report | campaign_id=CampaignID AND date=Date | Downstream report output |
| BI_DB_CIDFirstDates | SubAffiliateID=campaign_name (via SP_FB_Report) | Internal attribution cross-reference |

### 3.4 Gotchas

- **Feed is inactive** — last data date 2026-01-07; do not expect new rows after Jan 2026
- **device_platform aggregated out** — this table does NOT preserve device-level breakdown; all device rows from the external source are summed. Use `External_Fivetran_facebook_facebook_preformance_new` directly for device splits
- **SP_FB_Report only uses Smartly account** — `eToro Account` (186K rows) data is present in this table but not used in the downstream report SP (filter: `account_name = 'eToro ALL 2 (Smartly)'`)
- **ad_id is nvarchar(256)** — source external table has nvarchar(4000); values > 256 chars would be truncated (no truncation observed in practice: ad IDs are numeric strings)
- **ad_name, campaign_name, adset_name, account_name truncation risk** — same nvarchar(4000) → nvarchar(256) narrowing; long campaign names could be truncated
- **Campaign name convention required for Country/Funnel** — if campaign names don't follow the `{Country}_{Funnel}_...` pattern, `SP_FB_Report` will extract incorrect or empty Country/Funnel values (ABS of negative CHARINDEX produces 0-length LEFT)
- **No all-zero rows** — unlike FB_Conversion, every row has at least some metric activity (SUM > 0 for at least one of clicks/impressions/spend)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream production wiki verbatim |
| Tier 2 | From SP code (`SP_FB_Perf_Conv`) and external table structure |
| Tier 3 | Inferred from column name and Facebook Ads data model context |
| Tier 4 | Best available — unverified |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NOT NULL | Ad performance date (calendar date type). Range: 2020-10-20 to 2026-01-07. 1,907 distinct dates. (Tier 2 — SP_FB_Perf_Conv) |
| 2 | date_id | bigint | NOT NULL | Integer date key (YYYYMMDD) computed from `date` via `BI_DB_dbo.DateToDateID([date])`. Provided for JOIN compatibility with BI_DB_dbo date-keyed tables. (Tier 2 — SP_FB_Perf_Conv) |
| 3 | ad_id | nvarchar(256) | NOT NULL | Facebook Ads ad identifier (Facebook's unique numeric ID for individual ad creatives). High cardinality — 21,949 distinct values. Source external table has nvarchar(4000); potential truncation for very long IDs (not observed in practice). (Tier 2 — SP_FB_Perf_Conv) |
| 4 | adset_id | bigint | NULL | Facebook Ads ad set identifier. An ad set groups multiple ads under a shared budget, schedule, and targeting. 2,104 distinct values. No NULLs observed in practice despite nullable DDL. (Tier 2 — SP_FB_Perf_Conv) |
| 5 | campaign_id | bigint | NULL | Facebook Ads campaign identifier. A campaign is the top-level container for ad sets and ads, defining the overall objective. 1,000 distinct campaign IDs. No NULLs observed. (Tier 2 — SP_FB_Perf_Conv) |
| 6 | account_id | bigint | NULL | Facebook Ads account identifier. Only 2 distinct values: 447625602399415 (`eToro ALL 2 (Smartly)`) and 106616956125095 (`eToro Account`). No NULLs observed. (Tier 2 — SP_FB_Perf_Conv) |
| 7 | ad_name | nvarchar(256) | NULL | Human-readable name of the individual ad creative as set in Facebook Ads Manager. No NULLs observed. Source nvarchar(4000) → dest nvarchar(256). (Tier 2 — SP_FB_Perf_Conv) |
| 8 | adset_name | nvarchar(256) | NULL | Human-readable name of the ad set. No NULLs observed. Source nvarchar(4000) → dest nvarchar(256). (Tier 2 — SP_FB_Perf_Conv) |
| 9 | campaign_name | nvarchar(256) | NULL | Human-readable name of the campaign. Follows convention `{Country}_{Funnel}_...` (e.g., `GB_REG_...`, `DE_FTD_...`). Parsed by SP_FB_Report to extract Country and Funnel dimensions. No NULLs observed. (Tier 2 — SP_FB_Perf_Conv) |
| 10 | account_name | nvarchar(256) | NULL | Human-readable name of the Facebook Ads account. Two values: 'eToro ALL 2 (Smartly)' (primary, used in SP_FB_Report) and 'eToro Account' (secondary, excluded from SP_FB_Report). No NULLs observed. (Tier 2 — SP_FB_Perf_Conv) |
| 11 | clicks | bigint | NOT NULL | Total link clicks on the ad on this date, aggregated across all device platforms. Facebook metric: link_clicks. Total across all time: 121,615,461. (Tier 2 — SP_FB_Perf_Conv) |
| 12 | impressions | bigint | NOT NULL | Total number of times the ad was shown (served), aggregated across all device platforms. Total across all time: 14,595,040,968. (Tier 2 — SP_FB_Perf_Conv) |
| 13 | spend | float | NOT NULL | Total ad spend (USD) for this ad on this date, aggregated across all device platforms. Total across all time: $74,937,081. Two accounts: Smartly ($70.9M) and direct ($3.9M). (Tier 2 — SP_FB_Perf_Conv) |
| 14 | UpdateDate | datetime | NOT NULL | ETL timestamp set to GETDATE() at INSERT time. Range: 2021-12-20 to 2026-01-15 (last ETL run). (Tier 2 — SP_FB_Perf_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| date | External_Fivetran_facebook_facebook_preformance_new | date | Direct passthrough (GROUP BY key) |
| date_id | Computed | [date] | DateToDateID() function |
| ad_id | External_Fivetran_facebook_facebook_preformance_new | ad_id | GROUP BY key; nvarchar(4000) → nvarchar(256) |
| adset_id | External_Fivetran_facebook_facebook_preformance_new | adset_id | GROUP BY key |
| campaign_id | External_Fivetran_facebook_facebook_preformance_new | campaign_id | GROUP BY key |
| account_id | External_Fivetran_facebook_facebook_preformance_new | account_id | GROUP BY key |
| ad_name | External_Fivetran_facebook_facebook_preformance_new | ad_name | GROUP BY key; nvarchar(4000) → nvarchar(256) |
| adset_name | External_Fivetran_facebook_facebook_preformance_new | adset_name | GROUP BY key; nvarchar(4000) → nvarchar(256) |
| campaign_name | External_Fivetran_facebook_facebook_preformance_new | campaign_name | GROUP BY key; nvarchar(4000) → nvarchar(256) |
| account_name | External_Fivetran_facebook_facebook_preformance_new | account_name | GROUP BY key; nvarchar(4000) → nvarchar(256) |
| clicks | External_Fivetran_facebook_facebook_preformance_new | clicks | SUM(ISNULL(clicks, 0)) across device_platform |
| impressions | External_Fivetran_facebook_facebook_preformance_new | impressions | SUM(ISNULL(impressions, 0)) across device_platform |
| spend | External_Fivetran_facebook_facebook_preformance_new | spend | SUM(ISNULL(spend, 0)) across device_platform |
| UpdateDate | ETL | GETDATE() | Set at INSERT |

### 5.2 ETL Pipeline

```
Facebook Ads API (Meta Business Manager)
  |-- Fivetran connector (facebook dataset) ----|
  v
Bronze/Fivetran/facebook/facebook_preformance_new  (lake, Parquet)
  |-- BI_DB_dbo.External_Fivetran_facebook_facebook_preformance_new  (Synapse External Table)
  |-- SP_FB_Perf_Conv @date  (P20, SB_Daily)
  |   GROUP BY: date, DateToDateID(date), ad_id, adset_id, campaign_id, account_id,
  |             ad_name, adset_name, campaign_name, account_name
  |   AGGREGATE: SUM(ISNULL(clicks,0)), SUM(ISNULL(impressions,0)), SUM(ISNULL(spend,0))
  |   device_platform NOT in GROUP BY → collapsed
  |-- DELETE (8-day rolling window) + INSERT
  v
BI_DB_dbo.BI_DB_FB_Performance
  (595,616 rows | Oct 2020 – Jan 2026 | ROUND_ROBIN, HEAP)
  Feed INACTIVE since 2026-01-15
  UC: _Not_Migrated

Also written in same SP call (block 2):
  BI_DB_dbo.BI_DB_FB_Conversion

Downstream consumer:
  BI_DB_dbo.SP_FB_Report
    Filter: account_name = 'eToro ALL 2 (Smartly)'
    FULL OUTER JOIN BI_DB_FB_Conversion ON date + ad_id
    Parses campaign_name → Country + Funnel
    Joins BI_DB_CIDFirstDates for internal attribution (DB_Reg, DB_FTD)
    → BI_DB_FB_Report
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| date | (implicit) Dim_Date | Calendar date dimension |
| ad_id | Facebook Ads Platform | External ad identifier — no Synapse Dim for ads |
| campaign_id | Facebook Ads Platform | External campaign identifier |
| (source) | External_Fivetran_facebook_facebook_preformance_new | External table reading Fivetran Bronze lake data |

### 6.2 Referenced By

| Object | Reference | Usage |
|--------|-----------|-------|
| SP_FB_Report | FULL OUTER JOIN on date + ad_id (Smartly only) | Primary data source for Facebook Ads cost + performance in the combined FB report |
| BI_DB_FB_Report | (via SP_FB_Report) | Output destination of the FB report combining performance + conversions |

---

## 7. Sample Queries

### Daily spend and performance summary (Smartly account)

```sql
SELECT [date],
       SUM([spend])       AS TotalSpend,
       SUM([impressions]) AS TotalImpressions,
       SUM([clicks])      AS TotalClicks,
       SUM([spend]) / NULLIF(SUM([impressions]), 0) * 1000 AS CPM
FROM [BI_DB_dbo].[BI_DB_FB_Performance]
WHERE [date] BETWEEN '2025-01-01' AND '2026-01-07'
  AND [account_name] = 'eToro ALL 2 (Smartly)'
GROUP BY [date]
ORDER BY [date]
```

### Top 10 campaigns by spend in Q4 2025

```sql
SELECT TOP 10
       [campaign_id],
       [campaign_name],
       SUM([spend])       AS TotalSpend,
       SUM([impressions]) AS TotalImpressions,
       SUM([clicks])      AS TotalClicks
FROM [BI_DB_dbo].[BI_DB_FB_Performance]
WHERE [date] BETWEEN '2025-10-01' AND '2025-12-31'
GROUP BY [campaign_id], [campaign_name]
ORDER BY SUM([spend]) DESC
```

### Combined performance + conversion report (mirrors SP_FB_Report logic)

```sql
SELECT ISNULL(p.[date], c.[date])         AS [Date],
       p.[campaign_id]                    AS CampaignId,
       p.[campaign_name]                  AS CampaignName,
       SUM(ISNULL(p.[spend], 0))          AS Cost,
       SUM(ISNULL(p.[impressions], 0))    AS Impressions,
       SUM(ISNULL(p.[clicks], 0))         AS Clicks,
       SUM(ISNULL(c.[Registration], 0))   AS FB_Reg,
       SUM(ISNULL(c.[V2], 0))             AS FB_V2,
       SUM(ISNULL(c.[FTD], 0))            AS FB_FTD
FROM [BI_DB_dbo].[BI_DB_FB_Performance] p
FULL OUTER JOIN [BI_DB_dbo].[BI_DB_FB_Conversion] c
    ON p.[date] = c.[date] AND p.[ad_id] = c.[ad_id]
WHERE p.[date] BETWEEN '2025-10-01' AND '2026-01-07'
  AND p.[account_name] = 'eToro ALL 2 (Smartly)'
GROUP BY ISNULL(p.[date], c.[date]), p.[campaign_id], p.[campaign_name]
ORDER BY [Date]
```

### Check data freshness

```sql
SELECT MAX([date]) AS LastDataDate, MAX([UpdateDate]) AS LastETLRun
FROM [BI_DB_dbo].[BI_DB_FB_Performance]
-- Returns: 2026-01-07 / 2026-01-15 — feed inactive since Jan 2026
```

---

## 8. Atlassian Knowledge Sources

No dedicated Confluence or Jira pages found for this table. See `SP_FB_Report` for the downstream reporting context and `BI_DB_FB_Conversion` for the paired conversion tracking table.

---

*Generated: 2026-04-22 | Quality: 9.0/10 | Phases: 14/14*
*Tiers: 0 T1, 14 T2, 0 T3, 0 T4, 0 T5 | Elements: 14/14, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_FB_Performance | Type: Table | Production Source: Facebook Ads API via Fivetran (INACTIVE since Jan 2026)*
