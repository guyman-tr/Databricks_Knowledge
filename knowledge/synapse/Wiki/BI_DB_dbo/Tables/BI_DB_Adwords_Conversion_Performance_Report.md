# BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report

> **STALE DATA — last refreshed 2023-09-18.** 4,678-row Google Ads campaign-level conversion tracking table. Pivots Fivetran conversion_action_name rows into funnel columns (Registration, V2, FTD, MultipleDeposit) plus full app lifecycle tracking (FirstOpen, Registration, V2, FTD, Redeposit) for Android and iOS 1st-gen and 2nd-gen eToro apps. Part of the SP_Adwords_Pref_Conv Fivetran cluster (Table #8 of 12). Date range: 2023-06-19 to 2023-09-16. Device breakdown: DESKTOP, MOBILE, TABLET, CONNECTED_TV.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_new_api_conversion_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 4,678 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Conversion_Performance_Report` tracks **Google Ads campaign-level conversion performance** for eToro's marketing acquisition funnel. Each row represents one campaign's conversion metrics for a given date, device type, and Google Ads customer account. The table pivots Fivetran's raw conversion action rows into columnar funnel metrics at the campaign level — the broadest conversion aggregation in the Adwords cluster.

The SP (`SP_Adwords_Pref_Conv`, authored by Amir G 2021-02-22, migrated to Synapse by Chen 2023-09-12) refreshes 12 Adwords-related tables from Fivetran external tables. This table is Table #8 in the SP. It differs from the ad-level (`BI_DB_Adwords_Ad_Conv`) and keyword-level (`BI_DB_Adwords_Keywords_Conv`) tables by providing a campaign-level view with **full app lifecycle tracking** — including FirstOpen and Redeposit events not tracked in other conversion tables.

**DATA IS STALE**: The last UpdateDate is 2023-09-18 and the date range covers only 2023-06-19 to 2023-09-16. The SP has not run since the Synapse migration. If current Google Ads data is needed, query the Fivetran external tables directly or check Databricks.

Conversion formula: `all_conversions - view_through_conversions` (click-through conversions only, excluding view-through).

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot

**What**: Raw Fivetran rows with conversion_action_name are pivoted into one column per funnel stage at campaign level.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit
**Rules**:
- Registration = SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'
- V2 = same formula WHERE 'V2 Status'
- FTD = same WHERE 'FTD'
- MultipleDeposit = same WHERE 'Multiple Deposit'
- Unlike Ad_Conv and Geo_Conv, this table does NOT have FTDA/MTDA value columns

### 2.2 App Lifecycle Tracking (1st-Gen)

**What**: Full app lifecycle conversion tracking for the original Android and iOS app store listings.
**Columns Involved**: Android_FirstOpen, Android_Registration, Android_V2, Android_FTD, Android_Redeposit, iOS_FirstOpen, iOS_Registration, iOS_V2, iOS_FTD, iOS_Redeposit
**Rules**:
- Android columns track "eToro - Invest in stocks, crypto & trade CFDs (Android)" conversion actions
- iOS columns track "eToro Cryptocurrency Trading (iOS)" conversion actions
- Includes FirstOpen and Redeposit events unique to this table (not in Ad_Conv or Keywords_Conv)
- Formula: SUM(all_conversions - view_through_conversions) per action

### 2.3 App Conversion Tracking (2nd-Gen)

**What**: Conversion tracking for newer eToro app store listings (added 2022-05-10).
**Columns Involved**: Regs_IOS2, V2_IOS2, FTD_IOS2, Regs_Android2, V2_android2, FTD_Android2
**Rules**:
- IOS2 columns track "eToro: Crypto. Stocks. Social. (iOS)" app
- Android2 columns track "eToro: Investing made social (Android)" app
- Only tracks Registration, V2, FTD events (no FirstOpen/Redeposit)
- These columns appear mostly NULL/empty in current data — likely the newer app listings had low adoption before data went stale

### 2.4 Rolling Window Retention

**What**: Historical data management to keep ~1 year of data.
**Columns Involved**: date, DateID
**Rules**:
- DELETE rows WHERE date < first day of month one year ago
- DELETE rows WHERE date >= @FromDate (90 days back) AND date < today (overlap window)
- INSERT new rows for the 90-day window from Fivetran source

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution is ROUND_ROBIN (no skew). Clustered index on DateID ASC optimizes date-range scans. No distribution key available for colocation — all JOINs to Dictionary tables will be broadcast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Campaign funnel performance for a date range | `WHERE DateID BETWEEN 20230701 AND 20230901` — uses clustered index |
| Compare web vs Android vs iOS conversions | SUM Registration vs Android_Registration vs iOS_Registration |
| Find top-converting campaigns | GROUP BY campaign_id, campaign_name ORDER BY SUM(FTD) DESC |
| Device breakdown | GROUP BY Device |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Dictionary_Campaign | campaign_id = campaign_id | Resolve campaign metadata, bidding strategy, status |
| BI_DB_Adwords_Conversion_Performance_Report self | Same campaign_id across dates | Time-series trend analysis |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-09-16. Do not use for current reporting.
- **No FTDA/MTDA columns** — unlike Ad_Conv and Geo_Conv, this table has no conversion value columns. Use Ad_Conv for FTD monetary values.
- **2nd-gen app columns mostly empty** — Regs_IOS2, V2_IOS2 etc. are largely NULL in the available data.
- **float vs int inconsistency** — web funnel columns (Registration, V2, FTD, MultipleDeposit) are float, while 2nd-gen columns (Regs_IOS2 etc.) are int. The float type on web columns is an artifact of the Fivetran schema.
- **labels is JSON** — contains Google Ads label arrays like `[customers/5486244699/labels/21683977523]`. Parse with JSON functions.
- **campaign_id comes from Fivetran `id`** — the SP maps `id` (campaign ID in Fivetran) to `campaign_id` in this table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | YES | Google Ads report date. The calendar day for which conversion metrics are aggregated. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | bigint | YES | Date as YYYYMMDD integer. Computed by DateToDateID(date) function. Clustered index key for date-range queries. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | campaign_id | bigint | YES | Google Ads campaign identifier. Mapped from Fivetran `id` column. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | campaign_name | nvarchar(max) | YES | Google Ads campaign name. Mapped from Fivetran `name` column. Encodes targeting metadata: region, product, channel, language, affiliate ID (e.g., 'UK_Discovery_Regular_General3_EN_117057_New'). (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | customer_id | bigint | YES | Google Ads customer account ID (MCC or sub-account). Identifies the Google Ads account running the campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | labels | nvarchar(max) | YES | Google Ads campaign labels as JSON array. Contains resource name paths like `[customers/{id}/labels/{label_id}]`. Used for campaign categorization in Google Ads. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | Registration | float | YES | Web funnel: click-through registration conversions. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'. Excludes view-through. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | V2 | float | YES | Web funnel: click-through V2 (Level 2 verification) conversions. SUM WHERE conversion_action_name = 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | FTD | float | YES | Web funnel: click-through first-time deposit conversions. SUM WHERE conversion_action_name = 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | MultipleDeposit | float | YES | Web funnel: click-through multiple deposit conversions. SUM WHERE conversion_action_name = 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | Android_FirstOpen | float | YES | 1st-gen Android app: first open events. SUM WHERE 'eToro - Invest in stocks, crypto & trade CFDs (Android) first_open'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | Android_FTD | float | YES | 1st-gen Android app: first-time deposit conversions. SUM WHERE '...(Android) FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | Android_Redeposit | float | YES | 1st-gen Android app: redeposit conversions. SUM WHERE '...(Android) Redeposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | Android_Registration | float | YES | 1st-gen Android app: registration conversions. SUM WHERE '...(Android) registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | Android_V2 | float | YES | 1st-gen Android app: Level 2 verification conversions. SUM WHERE '...(Android) Verification Level - 2'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | iOS_FirstOpen | float | YES | 1st-gen iOS app: first open events. SUM WHERE 'eToro Cryptocurrency Trading (iOS) first_open'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | iOS_FTD | float | YES | 1st-gen iOS app: first-time deposit conversions. SUM WHERE '...(iOS) FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | iOS_Redeposit | float | YES | 1st-gen iOS app: redeposit conversions. SUM WHERE '...(iOS) Redeposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | iOS_Registration | float | YES | 1st-gen iOS app: registration conversions. SUM WHERE '...(iOS) registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | iOS_V2 | float | YES | 1st-gen iOS app: Level 2 verification conversions. SUM WHERE '...(iOS) Verification Level - 2'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) |
| 22 | Regs_IOS2 | int | YES | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social."): registration conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | V2_IOS2 | int | YES | 2nd-gen iOS app: Level 2 verification conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | FTD_IOS2 | int | YES | 2nd-gen iOS app: first-time deposit conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | Regs_Android2 | int | YES | 2nd-gen Android app ("eToro: Investing made social"): registration conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | V2_android2 | int | YES | 2nd-gen Android app: Level 2 verification conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 27 | FTD_Android2 | int | YES | 2nd-gen Android app: first-time deposit conversions. Added 2022-05-10. Mostly NULL in current data. (Tier 2 — SP_Adwords_Pref_Conv) |
| 28 | Device | nvarchar(50) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET, CONNECTED_TV. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| date | Fivetran Google Ads | date | Passthrough |
| DateID | Fivetran Google Ads | date | DateToDateID() function |
| campaign_id | Fivetran Google Ads | id | Rename |
| campaign_name | Fivetran Google Ads | name | Rename |
| customer_id | Fivetran Google Ads | customer_id | Passthrough |
| labels | Fivetran Google Ads | labels | Passthrough |
| Registration..MultipleDeposit | Fivetran Google Ads | conversion_action_name + all_conversions + view_through_conversions | CASE WHEN pivot + SUM |
| Android_* | Fivetran Google Ads | conversion_action_name (1st-gen Android app actions) | CASE WHEN pivot + SUM |
| iOS_* | Fivetran Google Ads | conversion_action_name (1st-gen iOS app actions) | CASE WHEN pivot + SUM |
| *_IOS2, *_Android2 | Fivetran Google Ads | conversion_action_name (2nd-gen app actions) | CASE WHEN pivot + SUM |
| UpdateDate | SP | N/A | GETDATE() |
| Device | Fivetran Google Ads | device | Passthrough |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_new_api_conversion_performance_report (Fivetran external table)
  |-- SP_Adwords_Pref_Conv @date (Table #8, P99, SB_FinanceReportSPS) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT with CASE WHEN pivot
  v
BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report (4,678 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Resolves to campaign metadata (name, bidding strategy, budget, status) |

### 6.2 Referenced By (other objects point to this)

No known consumers. This is a terminal reporting table.

---

## 7. Sample Queries

### 7.1 Campaign Funnel Performance by Date

```sql
SELECT date, campaign_name,
       SUM(Registration) AS regs, SUM(V2) AS v2s, SUM(FTD) AS ftds,
       SUM(MultipleDeposit) AS multi_deps
FROM [BI_DB_dbo].[BI_DB_Adwords_Conversion_Performance_Report]
WHERE DateID BETWEEN 20230801 AND 20230901
GROUP BY date, campaign_name
ORDER BY SUM(FTD) DESC
```

### 7.2 Web vs Android vs iOS Conversion Comparison

```sql
SELECT campaign_name,
       SUM(Registration) AS web_reg,
       SUM(Android_Registration) AS android_reg,
       SUM(iOS_Registration) AS ios_reg,
       SUM(Regs_Android2) AS android2_reg,
       SUM(Regs_IOS2) AS ios2_reg
FROM [BI_DB_dbo].[BI_DB_Adwords_Conversion_Performance_Report]
GROUP BY campaign_name
HAVING SUM(Registration) + SUM(ISNULL(Android_Registration,0)) + SUM(ISNULL(iOS_Registration,0)) > 0
ORDER BY web_reg DESC
```

### 7.3 Device Type Breakdown

```sql
SELECT Device,
       COUNT(*) AS rows,
       SUM(Registration) AS total_regs,
       SUM(FTD) AS total_ftds
FROM [BI_DB_dbo].[BI_DB_Adwords_Conversion_Performance_Report]
GROUP BY Device
ORDER BY total_ftds DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. The Adwords Fivetran cluster is managed by the BI team (originally authored by Amir G, with contributions from Chen, Jan Iablunovskey, and Eti per SP change history).

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 1 T5 | Elements: 28/28, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Conversion_Performance_Report | Type: Table | Production Source: Fivetran Google Ads*
