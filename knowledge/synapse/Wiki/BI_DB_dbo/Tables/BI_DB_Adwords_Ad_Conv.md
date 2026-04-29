# BI_DB_dbo.BI_DB_Adwords_Ad_Conv

> **STALE DATA — last refreshed 2023-09-18.** 10,201-row Google Ads ad-level conversion tracking table. Pivots Fivetran conversion_action_name rows into funnel columns (Registration, V2, FTD, MultipleDeposit) plus Android/iOS app-specific conversions. Covers ad-level attribution for Google Ads campaigns across DESKTOP, MOBILE, TABLET devices. Part of the SP_Adwords_Pref_Conv Fivetran cluster (Table #5 of 12). Date range: 2023-06-19 to 2023-09-16.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Fivetran_adwords_ad_conv_new_api_conv_ad_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 10,201 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Ad_Conv` tracks **Google Ads ad-level conversion performance** for eToro's marketing funnel. Each row represents one ad's conversion metrics for a given date, device, and Google Ads customer account. The table pivots Fivetran's raw conversion action rows into columnar funnel metrics: Registration, V2 (Level 2 verification), FTD (first-time deposit), and MultipleDeposit — the core marketing acquisition funnel.

The SP (`SP_Adwords_Pref_Conv`, authored by Amir G in 2021-02-22, migrated to Synapse by Chen in 2023-09-12) is a large batch SP that refreshes 12 Adwords-related tables from Fivetran external tables. This table is Table #5 in the SP. The conversion actions are filtered to specific eToro app store listings (Android: "eToro - Invest in stocks, crypto & trade CFDs", iOS: "eToro Cryptocurrency Trading", plus 2nd-gen apps) and platform funnel events.

**DATA IS STALE**: The last UpdateDate is 2023-09-18 and the date range covers only 2023-06-19 to 2023-09-16. The SP has not run since the Synapse migration. If current Google Ads data is needed, query the Fivetran external tables directly or check Databricks.

Conversion formula: `all_conversions - view_through_conversions` (click-through conversions only, excluding view-through).

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot

**What**: Raw Fivetran rows with conversion_action_name are pivoted into column per funnel stage.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit, FTDA, MTDA
**Rules**:
- Registration = SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'
- V2 = same formula WHERE 'V2 Status'
- FTD = same WHERE 'FTD'
- MultipleDeposit = same WHERE 'Multiple Deposit'
- FTDA = SUM(all_conversions_value) WHERE 'FTD' — FTD conversion value (in micros)
- MTDA = SUM(all_conversions_value) WHERE 'Multiple Deposit'

### 2.2 App-Specific Conversion Tracking

**What**: Separate conversion tracking for each mobile app store listing.
**Columns Involved**: android_reg/v2/ftd, ios_reg/v2/ftd, Regs_IOS2/V2_IOS2/FTD_IOS2, Regs_Android2/V2_android2/FTD_Android2
**Rules**:
- android_* = "eToro - Invest in stocks, crypto & trade CFDs (Android)" app conversions
- ios_* = "eToro Cryptocurrency Trading (iOS)" app conversions
- *_IOS2 = "eToro: Crypto. Stocks. Social. (iOS)" 2nd-gen app
- *_Android2 = "eToro: Investing made social (Android)" 2nd-gen app

### 2.3 Rolling Window Management

**What**: Data retention follows a rolling window with year-ago floor.
**Columns Involved**: date, DateID
**Rules**:
- DELETE dates older than DATEADD(year, -1, first-of-month)
- DELETE dates within the 90-day refresh window
- INSERT fresh data from Fivetran for the 90-day window

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CI(DateID). Filter on DateID for range queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily conversion funnel | `SELECT date, SUM(Registration), SUM(V2), SUM(FTD) FROM ... GROUP BY date` |
| Ad-level performance | `WHERE id = {ad_id} AND DateID BETWEEN ...` |
| Device breakdown | `GROUP BY device` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_Adwords_Ad_Pref | date, customer_id, id, ad_group_id, device | Join conversion data with performance data (impressions, clicks, cost) |
| BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign name, bidding strategy |
| BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group name |

### 3.4 Gotchas

- **DATA IS STALE**: Last update September 2023. Do not use for current analysis.
- **android_*/ios_* are float**: These conversion columns are float, not int — may contain fractional values from Google's attribution model.
- **Regs_IOS2/Android2 are int**: The 2nd-gen app columns use int type, unlike the float-typed 1st-gen columns.
- **external_customer_id = customer_id**: These are always the same value (SP duplicates customer_id).
- **FTDA/MTDA are conversion VALUES, not counts**: These are monetary amounts in micros, not conversion counts.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NO | Google Ads reporting date. Range: rolling 90-day window with year-ago floor. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Integer date key in YYYYMMDD format. Computed by DateToDateID(date) function. Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer/account ID. Identifies the Google Ads account running the campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | campaign_id | bigint | YES | Google Ads campaign ID. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | device | nvarchar(256) | YES | Device type: DESKTOP, MOBILE, TABLET. From Google Ads segmentation. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | id | bigint | YES | Google Ads ad ID (renamed from ad_id in Fivetran source). Unique creative identifier within an ad group. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | ad_group_id | bigint | YES | Google Ads ad group ID. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | week | nvarchar(256) | YES | ISO week start date (Monday) for the reporting period. From Google Ads API. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | external_customer_id | bigint | YES | Duplicate of customer_id. SP sets this = customer_id. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | Registration | int | YES | Click-through registration conversions (all_conversions - view_through_conversions) for conversion_action_name = 'Registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | V2 | int | YES | Click-through Level 2 verification conversions for conversion_action_name = 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | FTD | int | YES | Click-through first-time deposit conversions for conversion_action_name = 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | MultipleDeposit | int | YES | Click-through multiple deposit conversions for conversion_action_name = 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | FTDA | int | YES | FTD conversion value (all_conversions_value) — monetary amount attributed to FTD conversions. Not a count. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | MTDA | int | YES | Multiple Deposit conversion value (all_conversions_value). Not a count. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at SP execution time. (Tier 5 — SP_Adwords_Pref_Conv) |
| 17 | android_reg | float | YES | Android app ("eToro - Invest in stocks, crypto & trade CFDs") registration conversions. Float due to Google's fractional attribution. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | android_v2 | float | YES | Android app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | android_ftd | float | YES | Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | ios_reg | float | YES | iOS app ("eToro Cryptocurrency Trading") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | ios_v2 | float | YES | iOS app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | ios_ftd | float | YES | iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | Regs_IOS2 | int | YES | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social.") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | V2_IOS2 | int | YES | 2nd-gen iOS app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | FTD_IOS2 | int | YES | 2nd-gen iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | Regs_Android2 | int | YES | 2nd-gen Android app ("eToro: Investing made social") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 27 | V2_android2 | int | YES | 2nd-gen Android app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 28 | FTD_Android2 | int | YES | 2nd-gen Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| date-week, campaign_id, device, ad_group_id | Google Ads API via Fivetran | Direct fields | Passthrough |
| id | Google Ads API | ad_id | Rename |
| Registration-FTD_Android2 | Google Ads API | conversion_action_name + all_conversions | Pivot (CASE WHEN) |
| DateID | date | date | DateToDateID() function |

### 5.2 ETL Pipeline

```
Google Ads API (ad-level conversion report)
  |-- Fivetran connector (adwords_ad_conv schema) ---|
  v
External_Fivetran_adwords_ad_conv_new_api_conv_ad_performance_report (Parquet/Bronze)
  |-- SP_Adwords_Pref_Conv @date (Table #5) ---|
  |   DELETE old + INSERT (90-day window)
  |   PIVOT: conversion_action_name → funnel columns
  v
BI_DB_dbo.BI_DB_Adwords_Ad_Conv (10,201 rows — STALE since 2023-09-18)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign | Campaign name/config lookup |
| ad_group_id | BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup | Ad group name lookup |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in SSDT.

---

## 7. Sample Queries

### 7.1 Daily Funnel Summary

```sql
SELECT date, SUM(Registration) AS regs, SUM(V2) AS v2, SUM(FTD) AS ftd
FROM [BI_DB_dbo].[BI_DB_Adwords_Ad_Conv]
GROUP BY date
ORDER BY date DESC
```

### 7.2 Top Converting Ads

```sql
SELECT TOP 20 id AS ad_id, campaign_id, SUM(FTD) AS total_ftd, SUM(Registration) AS total_regs
FROM [BI_DB_dbo].[BI_DB_Adwords_Ad_Conv]
GROUP BY id, campaign_id
ORDER BY total_ftd DESC
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence or Jira sources found. SP comment references Fivetran Google Tables collection (Amir G, 2021).

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 27 T2, 0 T3, 0 T4, 1 T5 | Elements: 28/28, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Ad_Conv | Type: Table | Production Source: Fivetran Google Ads (ad conversion report)*
