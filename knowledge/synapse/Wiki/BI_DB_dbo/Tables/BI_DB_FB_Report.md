# BI_DB_dbo.BI_DB_FB_Report

> 102,444-row daily Facebook Ads attribution report combining FB API metrics (Smartly account only: spend, impressions, clicks, FB-attributed conversions) with actual platform registration/FTD counts from BI_DB_CIDFirstDates. Covers December 2020 to present (1,935 days). 7-day rolling DELETE+INSERT. **Partially inactive since January 2026**: FB source tables (BI_DB_FB_Performance, BI_DB_FB_Conversion) stopped loading 2026-01-07; only DB-side metrics (DB_Reg, DB_FTD) continue populating from CIDFirstDates.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_FB_Performance + BI_DB_FB_Conversion + BI_DB_CIDFirstDates via SP_FB_Report |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE WHERE Date >= @last7days + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_FB_Report is a daily marketing attribution report that combines Facebook Ads performance data (from the Smartly ad management platform) with actual eToro platform conversion data. Each row represents one campaign on one day, showing both FB-reported metrics and eToro database-verified metrics side by side, enabling the marketing team to compare Facebook's attribution claims against actual platform registrations and first-time deposits.

The table contains 102,444 rows spanning December 2020 to April 2026 (1,935 days). It uses a 7-day rolling refresh: each daily run deletes the last 7 days and re-inserts fresh data, ensuring late-arriving FB data and CIDFirstDates updates are captured.

**CRITICAL**: The FB source tables (BI_DB_FB_Performance and BI_DB_FB_Conversion) have been INACTIVE since 2026-01-07. Since that date, only DB-side metrics (DB_Reg, DB_FTD from CIDFirstDates) populate. All FB-side columns (Cost, Impressions, Clicks, FB_Reg, FB_V2, FB_FTD) are 0 for dates after January 2026. The table is effectively operating as a DB-only FB-attributed conversion tracker.

Country and Funnel are parsed from the campaign_name field using underscore delimiters. Region is derived from Country via a hardcoded CASE mapping (22 entries). Campaigns not matching any region map to 'Not valid region' (65% of recent rows).

The SP was authored by Jan Iablunovskey (2021-11-29) with a Region column addition (2022-02-09), Smartly-only filter (2022-03-07), and Synapse migration (Chen Largman, 2023-06-04).

---

## 2. Business Logic

### 2.1 FB vs DB Attribution Comparison

**What**: Compares Facebook's self-reported conversions against actual platform data.

**Columns Involved**: `FB_Reg` vs `DB_Reg`, `FB_FTD` vs `DB_FTD`

**Rules**:
- FB_Reg/FB_V2/FB_FTD: Facebook's 7-day click attribution model (from BI_DB_FB_Conversion, PIVOT of action_type '_7_d_click')
- DB_Reg: COUNT of actual registrations in CIDFirstDates WHERE SubChannel='FB'
- DB_FTD: COUNT of actual first-time deposits in CIDFirstDates WHERE SubChannel='FB'
- Matching is done by CampaignName = SubAffiliateID with COLLATE Latin1_General_100_BIN (case-sensitive)

### 2.2 Campaign Name Parsing

**What**: Extracts Country and Funnel from campaign_name using underscore delimiters.

**Columns Involved**: `Country`, `Funnel`, `CampaignName`

**Rules**:
- Country = everything before the first underscore (e.g., 'DE_HF_Purchase...' → 'DE')
- Funnel = segment between first and second underscore (e.g., 'DE_HF_Purchase...' → 'HF')
- For DB-only rows (no FB data): Country and Funnel are NULL

### 2.3 Region Mapping

**What**: Maps Country codes to marketing region names.

**Columns Involved**: `Region`, `Country`

**Rules**:
- DE→German, FR→French, IT→Italian, US→USA, AU→Australia, GB/IE→UK, DK→Denmark, ES→Spain, NL→Netherlands, PL→Poland, CZ→Czech Republic, RO→Romania, MX/LATAM→Latam, ARAB/GCC→Arabic, SEA→SEA, FI/ROE/NO/SE→Other EU
- Unmapped countries → 'Not valid region'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. Filter on Date for efficient range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Compare FB vs DB FTDs by region | `GROUP BY Region, Date WHERE Date >= @start` |
| Active data only (before FB inactivity) | `WHERE Date < '2026-01-07'` |
| Total spend by campaign | `WHERE Cost > 0 GROUP BY CampaignName` |

### 3.3 Common JOINs

No direct FK JOINs. CampaignName matches SubAffiliateID in CIDFirstDates.

### 3.4 Gotchas

- **FB source INACTIVE since 2026-01-07**: All FB columns (Cost, Impressions, Clicks, FB_Reg, FB_V2, FB_FTD) are 0 for dates after this. Only DB_Reg and DB_FTD continue.
- **'Not valid region'**: 65% of recent rows map to this — DB-only rows have NULL Country (not in the CASE mapping).
- **Case-sensitive JOIN**: CampaignName matched to SubAffiliateID with COLLATE Latin1_General_100_BIN.
- **Smartly account only**: Only FB account 'eToro ALL 2 (Smartly)' is included. The secondary 'eToro Account' ($3.9M) is excluded.
- **7-day rolling**: Historical data beyond 7 days is NOT re-processed. Late corrections older than 7 days will not appear.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 5 | ETL metadata | Standard — system-generated ETL column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date for FB performance and DB conversions. ISNULL(FB date, DB date). 7-day rolling refresh. (Tier 2 — SP_FB_Report) |
| 2 | CampaignID | bigint | YES | Facebook campaign ID from FB_Performance. 0 for DB-only rows (no FB match). (Tier 2 — SP_FB_Report) |
| 3 | CampaignName | varchar(500) | YES | Campaign name from FB_Performance or SubAffiliateID from CIDFirstDates. ISNULL(FB, DB). Parsed for Country/Funnel via underscore delimiters. (Tier 2 — SP_FB_Report) |
| 4 | Funnel | varchar(100) | YES | Marketing funnel stage extracted from CampaignName. Second underscore-delimited segment (e.g., 'HF' from 'DE_HF_Purchase...'). NULL for DB-only rows. (Tier 2 — SP_FB_Report) |
| 5 | Country | varchar(100) | YES | Country code extracted from CampaignName. First underscore-delimited segment (e.g., 'DE'). NULL for DB-only rows. Maps to Region via CASE. (Tier 2 — SP_FB_Report) |
| 6 | AccountName | varchar(500) | YES | FB Ads account name. Always 'eToro ALL 2 (Smartly)' for FB-matched rows. NULL for DB-only rows. (Tier 2 — SP_FB_Report) |
| 7 | Cost | int | YES | Facebook advertising spend in whole dollars. SUM(spend) from FB_Performance. 0 for DB-only rows or post-2026-01-07. (Tier 2 — SP_FB_Report) |
| 8 | Impressions | bigint | YES | Facebook ad impressions count. SUM(impressions) from FB_Performance. 0 for DB-only rows or post-2026-01-07. (Tier 2 — SP_FB_Report) |
| 9 | Clicks | bigint | YES | Facebook ad clicks count. SUM(clicks) from FB_Performance. 0 for DB-only rows or post-2026-01-07. (Tier 2 — SP_FB_Report) |
| 10 | FB_Reg | int | YES | Facebook-attributed registrations via 7-day click attribution. From FB_Conversion Registration PIVOT. 0 for DB-only rows or post-2026-01-07. (Tier 2 — SP_FB_Report) |
| 11 | FB_V2 | int | YES | Facebook-attributed V2 (L2 KYC) completions via 7-day click attribution. Custom event ID 384730099048186. 0 for DB-only rows or post-2026-01-07. (Tier 2 — SP_FB_Report) |
| 12 | FB_FTD | int | YES | Facebook-attributed first-time deposits via 7-day click attribution. From FB_Conversion FTD PIVOT. 0 for DB-only rows or post-2026-01-07. (Tier 2 — SP_FB_Report) |
| 13 | DB_Reg | int | YES | Actual platform registrations from BI_DB_CIDFirstDates WHERE SubChannel='FB'. COUNT(CID) per (registered date, SubAffiliateID). 0 if no DB registrations matched. (Tier 2 — SP_FB_Report) |
| 14 | DB_FTD | int | YES | Actual platform first-time deposits from BI_DB_CIDFirstDates WHERE SubChannel='FB'. COUNT(CID) per (FirstDepositDate, SubAffiliateID). 0 if no DB FTDs matched. (Tier 2 — SP_FB_Report) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |
| 16 | Region | varchar(100) | YES | Marketing region mapped from Country code. 22-entry CASE: DE→German, FR→French, IT→Italian, US→USA, AU→Australia, GB/IE→UK, etc. Unmapped→'Not valid region' (65% of recent rows). (Tier 2 — SP_FB_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date–AccountName | BI_DB_FB_Performance / CIDFirstDates | Various | ISNULL + campaign name parsing |
| Cost–FB_FTD | BI_DB_FB_Performance + FB_Conversion | spend, clicks, impressions, Registration, V2, FTD | SUM aggregation |
| DB_Reg, DB_FTD | BI_DB_CIDFirstDates | CID COUNT | COUNT per campaign per date |
| Region | Derived from Country | — | CASE mapping |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_FB_Performance (Smartly only, INACTIVE since 2026-01-07)
  FULL JOIN BI_DB_dbo.BI_DB_FB_Conversion (on date + ad_id)
  |-- SUM spend/clicks/impressions/Registration/V2/FTD, parse CampaignName ---|
  v
#FB (aggregated FB metrics per campaign per day)
  FULL JOIN
BI_DB_dbo.BI_DB_CIDFirstDates (SubChannel='FB', still active)
  |-- COUNT CID per (date, SubAffiliateID) for Reg + FTD ---|
  v
#DB_RegFTD
  |-- FULL JOIN #FB × #DB_RegFTD on date + CampaignName (COLLATE BIN) ---|
  |-- CASE mapping Country → Region ---|
  v
BI_DB_dbo.BI_DB_FB_Report (102K rows)
  DELETE WHERE Date >= @last7days + INSERT
  Daily via SP_FB_Report (SB_Daily, Priority 0)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CampaignName | BI_DB_dbo.BI_DB_CIDFirstDates.SubAffiliateID | JOIN key for DB-side conversion matching |

### 6.2 Referenced By (other objects point to this)

No downstream consumers found in SSDT.

---

## 7. Sample Queries

### 7.1 Compare FB vs DB FTDs by Region (Active Period)

```sql
SELECT Region,
       SUM(FB_FTD) AS fb_ftd,
       SUM(DB_FTD) AS db_ftd,
       SUM(DB_FTD) - SUM(FB_FTD) AS attribution_gap
FROM BI_DB_dbo.BI_DB_FB_Report
WHERE Date BETWEEN '2025-01-01' AND '2025-12-31'
  AND Region <> 'Not valid region'
GROUP BY Region
ORDER BY attribution_gap DESC
```

### 7.2 Daily Spend and CPA for Active Period

```sql
SELECT Date, SUM(Cost) AS total_spend,
       NULLIF(SUM(DB_FTD), 0) AS ftds,
       SUM(Cost) * 1.0 / NULLIF(SUM(DB_FTD), 0) AS cpa
FROM BI_DB_dbo.BI_DB_FB_Report
WHERE Date BETWEEN '2025-06-01' AND '2025-12-31'
GROUP BY Date
ORDER BY Date
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 1 T5 | Elements: 16/16, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_FB_Report | Type: Table | Production Source: FB_Performance + FB_Conversion + CIDFirstDates via SP_FB_Report*
