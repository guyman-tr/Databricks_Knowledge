# BI_DB_dbo.BI_DB_Adwords_Keywords_Conv

> **STALE DATA — last refreshed 2023-09-18.** 3,540-row Google Ads keyword-level conversion tracking table. Pivots Fivetran conversion_action_name into funnel columns (Registration, V2, FTD, MultipleDeposit, FTDA, MTDA) plus Android/iOS 1st-gen and 2nd-gen app conversions, LTV tracking, and Open Trade events per keyword. Conversion counterpart to BI_DB_Adwords_Keywords_Pref (which has performance metrics). Part of SP_Adwords_Pref_Conv cluster (Table #6 of 12). Date range: 2023-06-19 to 2023-08-09. Devices: DESKTOP, MOBILE, TABLET. 8 Google Ads accounts, 676 distinct keywords.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report → SP_Adwords_Pref_Conv |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 3,540 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Keywords_Conv` tracks **Google Ads keyword-level conversion performance** for eToro's marketing acquisition funnel. Each row represents one keyword's conversion metrics for a given date, device, campaign, ad group, and Google Ads account. The table pivots Fivetran's raw conversion action rows into columnar funnel metrics at the keyword level — enabling keyword-by-keyword attribution analysis.

This is Table #6 in SP_Adwords_Pref_Conv (authored by Amir G 2021-02-22, migrated to Synapse by Chen 2023-09-12). It is the **most feature-rich conversion table** in the Adwords cluster — uniquely containing LTV (Lifetime Value) tracking columns, Open Trade conversion events, and the full complement of 2nd-gen app columns. Other conversion tables (Ad_Conv, Geo_Conv, Search_Conv) have subsets of these columns.

The table pairs with `BI_DB_Adwords_Keywords_Pref` (224K rows of performance/spend data) — the much lower row count here (3,540 vs 224K) reflects that only a small fraction of keyword impressions generate tracked conversions.

Conversion formula: `all_conversions - view_through_conversions` (click-through conversions only, excluding view-through). Value columns (FTDA, MTDA, LTV_Value) use `all_conversions_value`. The 2nd-gen app and OpenTrade columns use `CASE WHEN ... THEN ... END` without ELSE 0, producing NULL instead of 0 when no matching conversion action exists.

**DATA IS STALE**: Last updated 2023-09-18. Date range covers only 2023-06-19 to 2023-08-09.

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot

**What**: Raw Fivetran rows with conversion_action_name are pivoted into one column per funnel stage at keyword level.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit, FTDA, MTDA
**Rules**:
- Registration = SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'
- V2 = same formula WHERE 'V2 Status'
- FTD = same WHERE 'FTD'
- MultipleDeposit = same WHERE 'Multiple Deposit'
- FTDA = SUM(all_conversions_value) WHERE 'FTD' — FTD conversion monetary value
- MTDA = SUM(all_conversions_value) WHERE 'Multiple Deposit' — multi-deposit monetary value

### 2.2 App-Specific Conversion Tracking (1st-Gen)

**What**: Device-specific conversion tracking for Android and iOS 1st-gen eToro apps.
**Columns Involved**: android_reg, android_v2, android_ftd, ios_reg, ios_v2, ios_ftd
**Rules**:
- Android tracks "eToro - Invest in stocks, crypto & trade CFDs (Android)" conversion actions
- iOS tracks "eToro Cryptocurrency Trading (iOS)" conversion actions
- Uses ELSE 0 — produces 0.0 (not NULL) when no matching action

### 2.3 App-Specific Conversion Tracking (2nd-Gen)

**What**: Conversion tracking for newer eToro app store listings (added 2022-05-10 by Jan Iablunovskey).
**Columns Involved**: Regs_IOS2, V2_IOS2, FTD_IOS2, Regs_Android2, V2_android2, FTD_Android2
**Rules**:
- IOS2 = "eToro: Crypto. Stocks. Social. (iOS)" app
- Android2 = "eToro: Investing made social (Android)" app
- Uses CASE WHEN without ELSE 0 — produces NULL when no matching action (3530/3540 rows NULL for Regs_IOS2)

### 2.4 Open Trade Conversion Events

**What**: Open Trade conversion tracking per app platform and overall (unique to this table and Conversion_Performance_Report).
**Columns Involved**: OpenTrade_And, OpenTrade_iOS, OpenTrade_iOS2, OpenTrade
**Rules**:
- OpenTrade_And = "eToro: Investing made social (Android) Open Trade"
- OpenTrade_iOS = "eToro: Crypto. Stocks. Social. (iOS) Open Trade"
- OpenTrade_iOS2 = "eToro: Investing made social (iOS) Open Trade" (note: iOS, not iOS2 app — naming inconsistency)
- OpenTrade = "Open Trade" (platform-agnostic)
- Uses CASE WHEN without ELSE 0 — produces NULL when no matching action

### 2.5 LTV (Lifetime Value) Tracking

**What**: 30-day lifetime value conversion tracking (unique to this table in the Adwords cluster, added 2022-07-14 by Eti).
**Columns Involved**: LTV_Count, LTV_Value
**Rules**:
- LTV_Count = SUM(all_conversions - view_through_conversions) WHERE 'LTV-30Day' — conversion count
- LTV_Value = SUM(all_conversions_value) WHERE 'LTV-30Day' — monetary value

### 2.6 Rolling Window Retention

**What**: Data retention follows a rolling window with year-ago floor.
**Columns Involved**: date, DateID
**Rules**:
- DELETE dates older than DATEADD(year, -1, first-of-month)
- DELETE dates within the 90-day refresh window
- INSERT fresh data from Fivetran for the 90-day window

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID ASC. With only 3,540 rows, full scans are trivial. Date-range predicates still benefit from the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top converting keywords | GROUP BY criteria ORDER BY SUM(FTD) DESC |
| Keyword funnel by match type | GROUP BY KeywordMatchType, SUM Registration/V2/FTD |
| Web vs Android vs iOS conversions | Compare SUM(Registration) vs SUM(android_reg) vs SUM(ios_reg) |
| LTV attribution by keyword | WHERE LTV_Count > 0 GROUP BY criteria |
| Open Trade events by platform | SUM(OpenTrade_And), SUM(OpenTrade_iOS), SUM(OpenTrade) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Keywords_Pref | date, customer_id, device, criteria, campaign_id, ad_group_id, week, KeywordMatchType | Combine conversion + performance (impressions, clicks, cost) for CPA/CPC analysis |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign name and bidding strategy |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group name |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-08-09. Do not use for current analysis.
- **id column is always NULL** — the SP comments out the `ad_id` mapping. Do not filter on it.
- **external_customer_id = customer_id** — always identical, redundant column.
- **2nd-gen app columns are mostly NULL** — Regs_IOS2 etc. are NULL in 3530/3540 rows. The newer app listings had low conversion volume.
- **OpenTrade_iOS2 maps to "Investing made social (iOS)"** — not the iOS2 app ("Crypto. Stocks. Social."). The column name is misleading.
- **NULL vs 0 inconsistency** — 1st-gen app columns use ELSE 0 (never NULL), while 2nd-gen and OpenTrade columns omit ELSE (NULL when no match). Use ISNULL() for aggregation.
- **FTDA/MTDA are conversion VALUES, not counts** — monetary amounts, not conversion counts.
- **float vs int types** — 1st-gen app columns (android_reg, ios_reg) are float, while 2nd-gen (Regs_IOS2, Regs_Android2) and funnel (Registration, FTD) are int.

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
| 1 | date | date | NO | Google Ads report date. Calendar day for conversion metrics. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer. Computed by DateToDateID(date). Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer account ID. Identifies the Google Ads account. 8 distinct accounts. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | status | nvarchar(256) | YES | Keyword criterion status. Mapped from Fivetran ad_group_criterion_status. All sampled values are 'ENABLED'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | criteria | nvarchar(256) | YES | Search keyword text. Mapped from Fivetran keyword_text. Multi-language terms (e.g., 'etoro', 'investir bitcoin', 'Kryptowährung Kaufen', 'achat action'). 676 distinct keywords. (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. SP inserts customer_id into both columns. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | account_currency_code | nvarchar(256) | YES | Google Ads account currency. Mapped from Fivetran customer_currency_code. Typically 'USD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. 68 distinct campaigns. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | id | bigint | YES | Keyword/criterion ID placeholder. NOT populated — SP comments out this column (--,ad_id). Always NULL across all 3,540 rows. (Tier 4 — inferred from DDL) |
| 11 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. 307 distinct ad groups. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | week | nvarchar(256) | YES | ISO week start date from Fivetran (e.g., '2023-06-19'). Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | Registration | int | YES | Click-through registration conversions. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'. Excludes view-through. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | V2 | int | YES | Click-through V2 (Level 2 verification) conversions. SUM WHERE conversion_action_name = 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | FTD | int | YES | Click-through first-time deposit conversions. SUM WHERE conversion_action_name = 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | MultipleDeposit | int | YES | Click-through multiple deposit conversions. SUM WHERE conversion_action_name = 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | FTDA | int | YES | FTD conversion monetary value. SUM(all_conversions_value) WHERE conversion_action_name = 'FTD'. Not a count — monetary amount. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | MTDA | int | YES | Multiple deposit conversion monetary value. SUM(all_conversions_value) WHERE conversion_action_name = 'Multiple Deposit'. Not a count — monetary amount. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). All rows show 2023-09-18. (Tier 5 — ETL infrastructure) |
| 20 | android_reg | float | YES | 1st-gen Android app ("eToro - Invest in stocks, crypto & trade CFDs") registration conversions. SUM(all_conversions - view_through_conversions). Float due to Google's fractional attribution. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | android_v2 | float | YES | 1st-gen Android app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | android_ftd | float | YES | 1st-gen Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | ios_reg | float | YES | 1st-gen iOS app ("eToro Cryptocurrency Trading") registration conversions. Float due to Google's fractional attribution. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | ios_v2 | float | YES | 1st-gen iOS app Level 2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | ios_ftd | float | YES | 1st-gen iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | LTV_Count | int | YES | 30-day lifetime value conversion count. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'LTV-30Day'. Unique to this table in the Adwords cluster. Added 2022-07-14 by Eti. (Tier 2 — SP_Adwords_Pref_Conv) |
| 27 | LTV_Value | int | YES | 30-day lifetime value monetary amount. SUM(all_conversions_value) WHERE conversion_action_name = 'LTV-30Day'. Unique to this table in the Adwords cluster. Added 2022-07-14 by Eti. (Tier 2 — SP_Adwords_Pref_Conv) |
| 28 | KeywordMatchType | nvarchar(50) | YES | Google Ads keyword match type. BROAD, EXACT, PHRASE. Mapped from keyword_match_type. Part of GROUP BY grain. Added 2022-07-19 by Eti. (Tier 2 — SP_Adwords_Pref_Conv) |
| 29 | Regs_IOS2 | int | YES | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social.") registration conversions. Added 2022-05-10. Mostly NULL (3530/3540 rows). No ELSE 0 — NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |
| 30 | V2_IOS2 | int | YES | 2nd-gen iOS app Level 2 verification conversions. Mostly NULL. (Tier 2 — SP_Adwords_Pref_Conv) |
| 31 | FTD_IOS2 | int | YES | 2nd-gen iOS app first-time deposit conversions. Mostly NULL. (Tier 2 — SP_Adwords_Pref_Conv) |
| 32 | Regs_Android2 | int | YES | 2nd-gen Android app ("eToro: Investing made social") registration conversions. Added 2022-05-10. Mostly NULL. (Tier 2 — SP_Adwords_Pref_Conv) |
| 33 | V2_android2 | int | YES | 2nd-gen Android app Level 2 verification conversions. Mostly NULL. (Tier 2 — SP_Adwords_Pref_Conv) |
| 34 | FTD_Android2 | int | YES | 2nd-gen Android app first-time deposit conversions. Mostly NULL. (Tier 2 — SP_Adwords_Pref_Conv) |
| 35 | OpenTrade_And | int | YES | 2nd-gen Android app ("eToro: Investing made social") Open Trade conversions. No ELSE 0 — NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |
| 36 | OpenTrade_iOS | int | YES | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social.") Open Trade conversions. NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |
| 37 | OpenTrade_iOS2 | int | YES | iOS app ("eToro: Investing made social (iOS)") Open Trade conversions. Note: maps to "Investing made social" NOT "Crypto. Stocks. Social." despite the iOS2 column name. NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |
| 38 | OpenTrade | int | YES | Platform-agnostic Open Trade conversions. SUM WHERE conversion_action_name = 'Open Trade'. NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| date, customer_id, device, campaign_id, ad_group_id, week | Fivetran Google Ads | Same names | Passthrough |
| DateID | Fivetran Google Ads | date | DateToDateID() |
| status | Fivetran Google Ads | ad_group_criterion_status | Rename |
| criteria | Fivetran Google Ads | keyword_text | Rename |
| account_currency_code | Fivetran Google Ads | customer_currency_code | Rename |
| KeywordMatchType | Fivetran Google Ads | keyword_match_type | Rename |
| external_customer_id | Fivetran Google Ads | customer_id | Duplicate |
| id | — | — | Not populated (commented out) |
| Registration..OpenTrade | Fivetran Google Ads | conversion_action_name pivot | CASE WHEN + SUM |
| FTDA, MTDA, LTV_Value | Fivetran Google Ads | all_conversions_value | CASE WHEN + SUM |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API (keyword-level conversion report)
  |-- Fivetran connector (adwords_keywords_conv_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report (Parquet/Bronze)
  |-- SP_Adwords_Pref_Conv @date (Table #6, P99, SB_FinanceReportSPS) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT with CASE WHEN pivot
  |   GROUP BY date, customer_id, ad_group_criterion_status, device, keyword_text,
  |           customer_currency_code, campaign_id, ad_group_id, week, keyword_match_type
  |   21 conversion_action_name values filtered
  v
BI_DB_dbo.BI_DB_Adwords_Keywords_Conv (3,540 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata (name, bidding strategy, budget, status) |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata (name, status) |

### 6.2 Referenced By (other objects point to this)

No known consumers. Terminal reporting table paired with Keywords_Pref for complete keyword analysis.

---

## 7. Sample Queries

### 7.1 Top Keywords by FTD Conversions

```sql
SELECT criteria AS keyword, KeywordMatchType,
       SUM(FTD) AS ftds, SUM(FTDA) AS ftd_value,
       SUM(Registration) AS regs, SUM(V2) AS v2s
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Conv]
GROUP BY criteria, KeywordMatchType
HAVING SUM(FTD) > 0
ORDER BY ftds DESC
```

### 7.2 Keyword Conversions + Performance (CPA Analysis)

```sql
SELECT c.criteria, c.KeywordMatchType,
       SUM(c.FTD) AS ftds, SUM(c.Registration) AS regs,
       SUM(p.clicks) AS clicks, SUM(p.cost) / 1000000.0 AS cost_usd,
       SUM(p.cost) / 1000000.0 / NULLIF(SUM(c.FTD), 0) AS cost_per_ftd
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Conv] c
JOIN [BI_DB_dbo].[BI_DB_Adwords_Keywords_Pref] p
  ON c.date = p.date AND c.customer_id = p.customer_id
     AND c.device = p.device AND c.criteria = p.criteria
     AND c.campaign_id = p.campaign_id AND c.ad_group_id = p.ad_group_id
     AND c.week = p.week AND c.KeywordMatchType = p.KeywordMatchType
GROUP BY c.criteria, c.KeywordMatchType
HAVING SUM(c.FTD) > 0
ORDER BY cost_per_ftd ASC
```

### 7.3 Web vs App Conversion Comparison

```sql
SELECT SUM(Registration) AS web_reg, SUM(V2) AS web_v2, SUM(FTD) AS web_ftd,
       SUM(android_reg) AS and_reg, SUM(android_v2) AS and_v2, SUM(android_ftd) AS and_ftd,
       SUM(ios_reg) AS ios_reg, SUM(ios_v2) AS ios_v2, SUM(ios_ftd) AS ios_ftd,
       SUM(ISNULL(Regs_Android2, 0)) AS and2_reg, SUM(ISNULL(Regs_IOS2, 0)) AS ios2_reg
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Conv]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. SP change history: Amir G (2021 original), Jan Iablunovskey (2022-05-10 added 2nd-gen app columns), Eti (2022-07-14 added LTV, 2022-07-19 added KeywordMatchType + conversion_action_name filter), Chen (2023-09-12 Synapse migration).

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 36 T2, 0 T3, 1 T4, 1 T5 | Elements: 38/38, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Keywords_Conv | Type: Table | Production Source: Fivetran Google Ads (keyword conversion report)*
