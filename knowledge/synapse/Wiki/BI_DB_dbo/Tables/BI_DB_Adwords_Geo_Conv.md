# BI_DB_dbo.BI_DB_Adwords_Geo_Conv

> **STALE DATA — last refreshed 2023-09-18.** 10,984-row Google Ads geographic-level conversion tracking table. Pivots conversion_action_name into funnel columns (Registration, V2, FTD, MultipleDeposit, FTDA, MTDA) plus Android/iOS 1st-gen app conversions, grouped by country_criteria_id for geographic attribution. Part of SP_Adwords_Pref_Conv cluster (Table #4 of 12). Date range: 2023-06-19 to 2023-09-16.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_geo_conv_new_api_conv_geo_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 10,984 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Geo_Conv` tracks **Google Ads geographic-level conversion performance** for eToro's marketing acquisition funnel. Each row represents conversions for a specific date, device, campaign, ad group, country, and Google Ads account combination. The geographic dimension (country_criteria_id) enables country-level attribution of marketing conversions.

The table is Table #4 in SP_Adwords_Pref_Conv and includes both funnel conversion counts (Registration, V2, FTD, MultipleDeposit) and conversion values (FTDA, MTDA) — unlike the campaign-level Conversion_Performance_Report which lacks value columns. The geographic grain enables answering "which countries generate the most FTDs from Google Ads?"

Conversion formula: `all_conversions - view_through_conversions` (click-through only). Value columns (FTDA, MTDA) use `all_conversions_value`.

**DATA IS STALE**: Last updated 2023-09-18.

---

## 2. Business Logic

### 2.1 Funnel Conversion Pivot with Values

**What**: Raw Fivetran rows pivoted into funnel columns, including monetary values.
**Columns Involved**: Registration, V2, FTD, MultipleDeposit, FTDA, MTDA
**Rules**:
- Registration/V2/FTD/MultipleDeposit = SUM(all_conversions - view_through_conversions) per action
- FTDA = SUM(all_conversions_value) WHERE 'FTD' — FTD conversion monetary value
- MTDA = SUM(all_conversions_value) WHERE 'Multiple Deposit' — multi-deposit monetary value

### 2.2 App Conversion Tracking (1st-Gen Only)

**What**: Device-specific conversion tracking for Android and iOS 1st-gen eToro apps.
**Columns Involved**: android_reg, android_v2, android_ftd, ios_reg, ios_v2, ios_ftd
**Rules**:
- Android tracks "eToro - Invest in stocks, crypto & trade CFDs (Android)" actions
- iOS tracks "eToro Cryptocurrency Trading (iOS)" actions
- No 2nd-gen app columns in this table (unlike Ad_Conv and Keywords_Conv)

### 2.3 Geographic Grain

**What**: Country-level attribution via Google Ads geographic criteria.
**Columns Involved**: country_criteria_id, region_criteria_id
**Rules**:
- country_criteria_id maps to Google Ads geographic criteria (e.g., 2840=US, 2826=UK, 2276=DE)
- region_criteria_id is hardcoded to NULL (removed 2021-08-23 by Amir)
- GROUP BY includes country_criterion_id for geographic disaggregation

### 2.4 Rolling Window Retention

**What**: Historical data management.
**Columns Involved**: date
**Rules**:
- DELETE old data (> 1 year from first-of-month)
- DELETE + INSERT 90-day rolling window
- Filtered by 10 specific conversion_action_name values

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID ASC for date-range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top countries by FTD conversions | GROUP BY country_criteria_id ORDER BY SUM(FTD) DESC |
| Campaign × country performance | GROUP BY campaign_id, country_criteria_id |
| FTD conversion value by country | SUM(FTDA) GROUP BY country_criteria_id |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Resolve campaign name and bidding strategy |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Resolve ad group name |
| BI_DB_Adwords_Geo_Pref | date, customer_id, device, campaign_id, ad_group_id, country_criteria_id | Combine geo conversion + performance metrics |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-09-16.
- **region_criteria_id is always NULL** — column kept in DDL but SP sets it to NULL.
- **external_customer_id = customer_id** — always identical, redundant column.
- **country_criteria_id is Google Ads geocriteria** — not an ISO country code. Requires Google Ads geocriteria mapping to resolve to country names (e.g., 2840=US, 2826=UK).
- **No 2nd-gen app columns** — unlike Ad_Conv and Keywords_Conv.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NO | Google Ads report date. Calendar day for conversion metrics. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer. Computed by DateToDateID(date). Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer account ID. Identifies the Google Ads account. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET, CONNECTED_TV, OTHER. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. Set to customer_id in SP. (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | region_criteria_id | int | YES | Google Ads region criteria ID. Hardcoded to NULL since 2021-08-23 (originally used for sub-country regions). (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | country_criteria_id | int | YES | Google Ads geographic country criteria ID. Maps to Google geocriteria codes (e.g., 2840=US, 2826=UK, 2276=DE, 2724=ES, 2414=LTM). Enables country-level attribution. Mapped from Fivetran country_criterion_id. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | week | nvarchar(256) | YES | ISO week start date from Fivetran (e.g., '2023-09-11'). Used for weekly aggregation. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | Registration | int | YES | Click-through registration conversions. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name = 'Registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | V2 | int | YES | Click-through V2 (Level 2 verification) conversions. SUM WHERE 'V2 Status'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | FTD | int | YES | Click-through first-time deposit conversions. SUM WHERE 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | MultipleDeposit | int | YES | Click-through multiple deposit conversions. SUM WHERE 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | FTDA | int | YES | FTD conversion monetary value. SUM(all_conversions_value) WHERE 'FTD'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | MTDA | int | YES | Multiple deposit conversion monetary value. SUM(all_conversions_value) WHERE 'Multiple Deposit'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) |
| 18 | android_reg | float | YES | 1st-gen Android app registration conversions. SUM WHERE 'eToro - Invest in stocks, crypto & trade CFDs (Android) registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | android_v2 | float | YES | 1st-gen Android app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | android_ftd | float | YES | 1st-gen Android app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 21 | ios_reg | float | YES | 1st-gen iOS app registration conversions. SUM WHERE 'eToro Cryptocurrency Trading (iOS) registration'. (Tier 2 — SP_Adwords_Pref_Conv) |
| 22 | ios_v2 | float | YES | 1st-gen iOS app V2 verification conversions. (Tier 2 — SP_Adwords_Pref_Conv) |
| 23 | ios_ftd | float | YES | 1st-gen iOS app first-time deposit conversions. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| date, customer_id, device, campaign_id, ad_group_id, week | Fivetran Google Ads | Same names | Passthrough |
| DateID | Fivetran Google Ads | date | DateToDateID() |
| external_customer_id | Fivetran Google Ads | customer_id | Duplicate |
| region_criteria_id | N/A | N/A | Hardcoded NULL |
| country_criteria_id | Fivetran Google Ads | country_criterion_id | Rename |
| Registration..MTDA | Fivetran Google Ads | conversion_action_name pivot | CASE WHEN + SUM |
| android_*/ios_* | Fivetran Google Ads | conversion_action_name (app actions) | CASE WHEN + SUM |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_geo_conv_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_geo_conv_new_api_conv_geo_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #4, P99) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT with CASE WHEN pivot
  |   GROUP BY date, customer_id, device, campaign_id, ad_group_id, country_criterion_id, week
  v
BI_DB_dbo.BI_DB_Adwords_Geo_Conv (10,984 rows, STALE since 2023-09-18)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| campaign_id | BI_DB_Adwords_Dictionary_Campaign | Campaign metadata lookup |
| ad_group_id | BI_DB_Adwords_Dictionary_AdGroup | Ad group metadata lookup |

### 6.2 Referenced By (other objects point to this)

No known consumers. Terminal reporting table typically joined with Geo_Pref for complete geo analysis.

---

## 7. Sample Queries

### 7.1 Top Countries by FTD Conversions

```sql
SELECT country_criteria_id,
       SUM(FTD) AS total_ftds, SUM(FTDA) AS total_ftd_value,
       SUM(Registration) AS total_regs
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Conv]
GROUP BY country_criteria_id
ORDER BY total_ftds DESC
```

### 7.2 Geo Conversions + Performance Combined

```sql
SELECT c.date, c.country_criteria_id,
       SUM(c.FTD) AS ftds, SUM(p.clicks) AS clicks, SUM(p.cost) AS cost_micros
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Conv] c
JOIN [BI_DB_dbo].[BI_DB_Adwords_Geo_Pref] p
  ON c.date = p.date AND c.customer_id = p.customer_id
     AND c.device = p.device AND c.campaign_id = p.campaign_id
     AND c.ad_group_id = p.ad_group_id AND c.country_criteria_id = p.country_criteria_id
GROUP BY c.date, c.country_criteria_id
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 1 T5 | Elements: 23/23, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Geo_Conv | Type: Table | Production Source: Fivetran Google Ads*
