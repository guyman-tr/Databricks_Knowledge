# BI_DB_dbo.BI_DB_Adwords_Keywords_Conv

> **STALE DATA — last refreshed 2023-09-18.** 3,540-row Google Ads keyword-level conversion tracking table. The most comprehensive conversion table in the Adwords cluster (38 columns): pivots funnel conversions (Registration/V2/FTD/MultipleDeposit), 1st/2nd-gen app conversions, LTV-30Day metrics, and Open Trade events by keyword. Part of SP_Adwords_Pref_Conv cluster (Table #6 of 12). Date range: 2023-06-19 to 2023-08-09. Keywords include multi-language search terms: 'auto trading robot', 'Kryptowährung Kaufen', 'how to buy stocks'.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report |
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

`BI_DB_Adwords_Keywords_Conv` tracks **Google Ads keyword-level conversion performance** — the most granular and feature-rich conversion table in the Adwords cluster. Each row represents conversions for a specific keyword, date, device, campaign, ad group, account, and match type combination. It answers "which exact search keywords drive registrations, verifications, deposits, and app engagement?"

This table is unique in the cluster for including:
- **LTV metrics** (LTV_Count, LTV_Value) for 30-day lifetime value attribution (added 2022-07-14)
- **Open Trade events** across all platforms (added later) for post-deposit engagement tracking
- **KeywordMatchType** (BROAD, EXACT, PHRASE) for match type analysis
- **2nd-gen app columns** for newer eToro app listings

The SP performs conversion_action_name pivot with the widest filter of any table (21 conversion action names) including LTV-30Day, Open Trade, and all app variants. Grain is very fine — the low row count (3,540) compared to Keywords_Pref (224K) indicates that only a small fraction of keyword impressions generate tracked conversions.

**DATA IS STALE**: Last updated 2023-09-18. Data only through 2023-08-09 (shorter range than other tables).

---

## 2. Business Logic

### 2.1 Full Funnel Conversion Pivot

**What**: Standard marketing funnel pivot from conversion_action_name rows.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit, FTDA, MTDA
**Rules**:
- Same SUM(all_conversions - view_through_conversions) formula as other conversion tables
- FTDA/MTDA = conversion monetary values (SUM of all_conversions_value)

### 2.2 LTV Attribution (Unique to This Table)

**What**: 30-day lifetime value tracking for keyword-attributed conversions.
**Columns Involved**: LTV_Count, LTV_Value
**Rules**:
- LTV_Count = SUM(all_conversions - view_through_conversions) WHERE 'LTV-30Day'
- LTV_Value = SUM(all_conversions_value) WHERE 'LTV-30Day'
- Added 2022-07-14 by Eti for marketing ROI analysis

### 2.3 Open Trade Tracking (Unique to This Table)

**What**: Post-deposit engagement — tracking whether keyword-attributed users opened trades.
**Columns Involved**: OpenTrade_And, OpenTrade_iOS, OpenTrade_iOS2, OpenTrade
**Rules**:
- OpenTrade = SUM WHERE 'Open Trade' (web/generic)
- OpenTrade_And = SUM WHERE 'eToro: Investing made social (Android) Open Trade'
- OpenTrade_iOS = SUM WHERE 'eToro: Crypto. Stocks. Social. (iOS) Open Trade'
- OpenTrade_iOS2 = SUM WHERE 'eToro: Investing made social (iOS) Open Trade'

### 2.4 Keyword Match Type

**What**: Google Ads keyword matching strategy classification.
**Columns Involved**: KeywordMatchType
**Rules**:
- BROAD = broad match (includes related searches)
- EXACT = exact match (keyword exactly as entered)
- PHRASE = phrase match (keyword contained in search query)
- Added 2022-07-19 by Eti as GROUP BY dimension

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID ASC.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Best keywords by FTD | GROUP BY criteria ORDER BY SUM(FTD) DESC |
| ROI by keyword (LTV vs spend) | JOIN with Keywords_Pref for cost, compare LTV_Value |
| Match type effectiveness | GROUP BY KeywordMatchType |
| Post-deposit engagement by keyword | SUM(OpenTrade) GROUP BY criteria |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Keywords_Pref | date, customer_id, device, criteria, campaign_id, ad_group_id, week, KeywordMatchType | Combine keyword conversions + performance (impressions, clicks, cost) |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Campaign metadata |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Ad group metadata |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-08-09 (shorter than other tables).
- **id column is always NULL** — in DDL but SP comments out the INSERT (--,id).
- **external_customer_id = customer_id** — redundant duplicate.
- **criteria is the keyword text** — renamed from Fivetran keyword_text. Contains multi-language terms.
- **account_currency_code** — renamed from customer_currency_code. Typically USD.
- **OpenTrade and LTV columns mostly empty** — these actions are rarer than funnel events.

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
| 1 | date | date | NO | Google Ads report date. Calendar day for conversion metrics. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer. Computed by DateToDateID(date). Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer account ID. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | status | nvarchar(256) | YES | Ad group criterion (keyword) status. Mapped from Fivetran ad_group_criterion_status. ENABLED=active. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET. Part of row grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | criteria | nvarchar(256) | YES | Search keyword text. Mapped from Fivetran keyword_text. Contains multi-language terms (e.g., 'Kryptowährung Kaufen', 'how to buy stocks'). (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | account_currency_code | nvarchar(256) | YES | Google Ads account currency. Mapped from Fivetran customer_currency_code. Typically USD. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | id | bigint | YES | Keyword/criterion ID placeholder. NOT populated — SP comments out this column. Always NULL. (Tier 4 — inferred from DDL) |
| 11 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | week | nvarchar(256) | YES | ISO week start date from Fivetran (e.g., '2023-08-07'). Part of row grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | Registration | int | YES | Click-through registration conversions for this keyword. SUM(all_conversions - view_through_conversions) WHERE 'Registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | V2 | int | YES | Click-through V2 verification conversions. SUM WHERE 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | FTD | int | YES | Click-through first-time deposit conversions. SUM WHERE 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | MultipleDeposit | int | YES | Click-through multiple deposit conversions. SUM WHERE 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | FTDA | int | YES | FTD conversion monetary value. SUM(all_conversions_value) WHERE 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | MTDA | int | YES | Multiple deposit conversion monetary value. SUM(all_conversions_value) WHERE 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted (GETDATE()). (Tier 5 — ETL infrastructure) |
| 20 | android_reg | float | YES | 1st-gen Android app registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | android_v2 | float | YES | 1st-gen Android app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | android_ftd | float | YES | 1st-gen Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | ios_reg | float | YES | 1st-gen iOS app registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 24 | ios_v2 | float | YES | 1st-gen iOS app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 25 | ios_ftd | float | YES | 1st-gen iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 26 | LTV_Count | int | YES | 30-day LTV conversion count. SUM(all_conversions - view_through_conversions) WHERE 'LTV-30Day'. Unique to this table. (Tier 2 — SP_Adwords_Pref_Conv) |
| 27 | LTV_Value | int | YES | 30-day LTV conversion monetary value. SUM(all_conversions_value) WHERE 'LTV-30Day'. Unique to this table. (Tier 2 — SP_Adwords_Pref_Conv) |
| 28 | KeywordMatchType | nvarchar(50) | YES | Google Ads keyword match type. BROAD, EXACT, PHRASE. Part of GROUP BY grain. Mapped from Fivetran keyword_match_type. (Tier 2 — SP_Adwords_Pref_Conv) |
| 29 | Regs_IOS2 | int | YES | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social.") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 30 | V2_IOS2 | int | YES | 2nd-gen iOS app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 31 | FTD_IOS2 | int | YES | 2nd-gen iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 32 | Regs_Android2 | int | YES | 2nd-gen Android app ("eToro: Investing made social") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 33 | V2_android2 | int | YES | 2nd-gen Android app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 34 | FTD_Android2 | int | YES | 2nd-gen Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 35 | OpenTrade_And | int | YES | Open Trade conversions from 2nd-gen Android app. SUM WHERE 'eToro: Investing made social (Android) Open Trade'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 36 | OpenTrade_iOS | int | YES | Open Trade conversions from 2nd-gen iOS app (Crypto.Stocks.Social). SUM WHERE 'eToro: Crypto. Stocks. Social. (iOS) Open Trade'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 37 | OpenTrade_iOS2 | int | YES | Open Trade conversions from alternate iOS app listing. SUM WHERE 'eToro: Investing made social (iOS) Open Trade'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 38 | OpenTrade | int | YES | Generic Open Trade conversions (web/unattributed). SUM WHERE 'Open Trade'. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Dimension columns | Fivetran Google Ads | Various (renamed) | Passthrough/Rename |
| Funnel columns | Fivetran Google Ads | conversion_action_name pivot | CASE WHEN + SUM |
| LTV columns | Fivetran Google Ads | conversion_action_name = 'LTV-30Day' | CASE WHEN + SUM |
| OpenTrade columns | Fivetran Google Ads | conversion_action_name = '*Open Trade' | CASE WHEN + SUM |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_keywords_conv_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #6, P99) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT with CASE WHEN pivot
  |   21 conversion_action_name values filtered
  |   GROUP BY date, customer_id, status, device, keyword_text, currency, campaign_id, ad_group_id, week, keyword_match_type
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
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata |

### 6.2 Referenced By (other objects point to this)

No known consumers. Terminal reporting table paired with Keywords_Pref.

---

## 7. Sample Queries

### 7.1 Top Keywords by FTD with LTV

```sql
SELECT criteria AS keyword, KeywordMatchType,
       SUM(FTD) AS ftds, SUM(LTV_Count) AS ltv_conversions, SUM(LTV_Value) AS ltv_value
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Conv]
GROUP BY criteria, KeywordMatchType
HAVING SUM(FTD) > 0
ORDER BY ltv_value DESC
```

### 7.2 Match Type Conversion Effectiveness

```sql
SELECT KeywordMatchType,
       COUNT(*) AS rows, SUM(Registration) AS regs, SUM(FTD) AS ftds,
       SUM(OpenTrade) AS open_trades
FROM [BI_DB_dbo].[BI_DB_Adwords_Keywords_Conv]
GROUP BY KeywordMatchType
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 36 T2, 0 T3, 1 T4, 1 T5 | Elements: 38/38, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Keywords_Conv | Type: Table | Production Source: Fivetran Google Ads*
