# BI_DB_dbo.BI_DB_Adwords_Geo_Pref

> **STALE DATA — last refreshed 2023-09-18.** 239,828-row Google Ads geographic-level performance metrics table. Contains impressions, clicks, cost (in micros), video views, interactions, and total conversions by country, campaign, ad group, device, and date. Performance counterpart to BI_DB_Adwords_Geo_Conv (which has the funnel breakdown). Part of SP_Adwords_Pref_Conv cluster (Table #1 of 12). Date range: 2023-06-19 to 2023-09-17. Devices: DESKTOP, MOBILE, TABLET, CONNECTED_TV, OTHER.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Ads connector → External_Bronze_Fivetran_adwords_geo_perf_new_api_perf_geo_performance_report |
| **Refresh** | **STALE** — SP_Adwords_Pref_Conv (P99, SB_FinanceReportSPS). Last ran 2023-09-18. Rolling 90-day DELETE+INSERT + year-ago floor. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Row Count** | 239,828 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Adwords_Geo_Pref` stores **Google Ads geographic-level performance metrics** — the "how much was spent and what engagement was achieved" counterpart to `BI_DB_Adwords_Geo_Conv` (which tracks "what conversions resulted"). Together they provide a complete geographic view of Google Ads campaign effectiveness.

Each row represents one combination of date, device, campaign, ad group, country, and Google Ads account. Columns are mostly **passthrough from Fivetran** (no conversion pivot), containing standard Google Ads performance metrics: impressions, clicks, cost (in micros), video views, interactions, and total conversions.

This is Table #1 in SP_Adwords_Pref_Conv (the first table processed). The SP denormalizes campaign/ad group names and statuses directly into the performance row, making JOINs to dictionary tables optional for basic analysis.

**DATA IS STALE**: Last updated 2023-09-18. Largest table in this batch by row count (240K).

---

## 2. Business Logic

### 2.1 Passthrough Performance Metrics

**What**: Standard Google Ads performance metrics passed through from Fivetran with minimal transformation.
**Columns Involved**: impressions, clicks, cost, video_views, interactions, Conversions
**Rules**:
- All metrics are direct passthrough from Fivetran source
- cost is renamed from cost_micros (value in Google Ads micros — divide by 1,000,000 for actual currency)
- No aggregation or pivot — grain matches the Fivetran source

### 2.2 Denormalized Campaign/Ad Group Metadata

**What**: Campaign and ad group names/statuses embedded directly in the performance row.
**Columns Involved**: campaign_name, campaign_status, ad_group_name, ad_group_status
**Rules**:
- Passthrough from Fivetran source, avoiding need for dictionary JOINs
- Status values from Fivetran (may differ in casing from dictionary tables)

### 2.3 Geographic Grain

**What**: Country-level geographic attribution.
**Columns Involved**: country_criteria_id, region_criteria_id
**Rules**:
- country_criteria_id maps to Google Ads geocriteria codes
- region_criteria_id is hardcoded to NULL (removed 2021-08-23)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID ASC. With 240K rows, scans are fast but date-range predicates benefit from the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Campaign spend by country | SUM(cost) / 1000000.0 GROUP BY country_criteria_id |
| Click-through rate by device | SUM(clicks) * 1.0 / NULLIF(SUM(impressions), 0) GROUP BY device |
| Cost per conversion by country | SUM(cost) / NULLIF(SUM(Conversions), 0) GROUP BY country_criteria_id |
| Top campaigns by impressions | GROUP BY campaign_name ORDER BY SUM(impressions) DESC |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Adwords_Geo_Conv | date, customer_id, device, campaign_id, ad_group_id, country_criteria_id | Combine performance + funnel conversion metrics |
| BI_DB_Adwords_Dictionary_Campaign | campaign_id | Canonical campaign metadata (bidding strategy, budget) |
| BI_DB_Adwords_Dictionary_AdGroup | ad_group_id | Canonical ad group metadata |

### 3.4 Gotchas

- **Data is STALE** — covers only 2023-06-19 to 2023-09-17.
- **cost is in micros** — divide by 1,000,000 to get actual currency amount. The column is renamed from cost_micros in Fivetran but the value is NOT converted.
- **region_criteria_id is always NULL** — column retained in DDL but unused.
- **external_customer_id = customer_id** — redundant duplicate.
- **Campaign/ad group names are denormalized** — may differ from dictionary table values if they were renamed between the performance report and the dictionary snapshot.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code and Fivetran schema analysis | SP_Adwords_Pref_Conv |
| Tier 5 | ETL infrastructure column | Standard pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NO | Google Ads report date. Calendar day for performance metrics. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer. Computed by DateToDateID(date). Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) |
| 3 | customer_id | bigint | NO | Google Ads customer account ID. Identifies the Google Ads account. (Tier 2 — SP_Adwords_Pref_Conv) |
| 4 | impressions | bigint | YES | Number of times ads were shown. Standard Google Ads metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 5 | ad_group_status | nvarchar(256) | YES | Ad group operational status. Denormalized from Fivetran source (e.g., ENABLED, PAUSED). (Tier 2 — SP_Adwords_Pref_Conv) |
| 6 | campaign_status | nvarchar(256) | YES | Campaign operational status. Denormalized from Fivetran source (e.g., ENABLED, PAUSED). (Tier 2 — SP_Adwords_Pref_Conv) |
| 7 | device | nvarchar(256) | YES | Google Ads device type. DESKTOP, MOBILE, TABLET, CONNECTED_TV, OTHER. Part of row grain. (Tier 2 — SP_Adwords_Pref_Conv) |
| 8 | campaign_name | nvarchar(256) | YES | Google Ads campaign name. Denormalized from Fivetran source. Encodes region, product, channel metadata. (Tier 2 — SP_Adwords_Pref_Conv) |
| 9 | ad_group_name | nvarchar(256) | YES | Google Ads ad group name. Denormalized from Fivetran source. Encodes keyword theme and targeting. (Tier 2 — SP_Adwords_Pref_Conv) |
| 10 | video_views | bigint | YES | Number of video ad views. Standard Google Ads video metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 11 | cost | float | YES | Advertising cost in Google Ads micros. Renamed from Fivetran cost_micros. Divide by 1,000,000 for actual currency (e.g., 270485.0 micros = $0.27 USD). (Tier 2 — SP_Adwords_Pref_Conv) |
| 12 | external_customer_id | bigint | YES | Always equals customer_id — redundant duplicate. Set to customer_id in SP. (Tier 2 — SP_Adwords_Pref_Conv) |
| 13 | region_criteria_id | int | YES | Google Ads region criteria ID. Hardcoded to NULL since 2021-08-23. (Tier 2 — SP_Adwords_Pref_Conv) |
| 14 | campaign_id | bigint | YES | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. (Tier 2 — SP_Adwords_Pref_Conv) |
| 15 | interactions | bigint | YES | Total interactions (clicks, video views, calls). Standard Google Ads engagement metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 16 | ad_group_id | bigint | YES | Google Ads ad group identifier. FK to BI_DB_Adwords_Dictionary_AdGroup. (Tier 2 — SP_Adwords_Pref_Conv) |
| 17 | clicks | bigint | YES | Number of ad clicks. Standard Google Ads metric. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| 18 | country_criteria_id | int | YES | Google Ads geographic country criteria ID. Maps to geocriteria codes (e.g., 2840=US, 2826=UK, 2100=Italy). Mapped from Fivetran country_criterion_id. (Tier 2 — SP_Adwords_Pref_Conv) |
| 19 | week | nvarchar(256) | YES | ISO week start date from Fivetran (e.g., '2023-09-11'). Used for weekly aggregation. (Tier 2 — SP_Adwords_Pref_Conv) |
| 20 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) |
| 21 | Conversions | bigint | YES | Total conversions (all types combined). Standard Google Ads metric. Passthrough from Fivetran. Unlike Geo_Conv which breaks down by funnel stage, this is the aggregate total. (Tier 2 — SP_Adwords_Pref_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Most columns | Fivetran Google Ads | Same names | Passthrough |
| DateID | Fivetran Google Ads | date | DateToDateID() |
| cost | Fivetran Google Ads | cost_micros | Rename (value unchanged — still in micros) |
| external_customer_id | Fivetran Google Ads | customer_id | Duplicate |
| region_criteria_id | N/A | N/A | Hardcoded NULL |
| country_criteria_id | Fivetran Google Ads | country_criterion_id | Rename |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Google Ads API
  |-- Fivetran connector (adwords_geo_perf_new_api schema) ---|
  v
External_Bronze_Fivetran_adwords_geo_perf_new_api_perf_geo_performance_report
  |-- SP_Adwords_Pref_Conv @date (Table #1, P99) ---|
  |   DELETE old (>1yr) + DELETE 90-day overlap + INSERT passthrough
  v
BI_DB_dbo.BI_DB_Adwords_Geo_Pref (239,828 rows, STALE since 2023-09-18)
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

No known consumers. Join with Geo_Conv for complete geographic analysis.

---

## 7. Sample Queries

### 7.1 Campaign Cost and CTR by Country

```sql
SELECT country_criteria_id,
       SUM(cost) / 1000000.0 AS cost_usd,
       SUM(clicks) AS total_clicks,
       SUM(impressions) AS total_impressions,
       CAST(SUM(clicks) AS FLOAT) / NULLIF(SUM(impressions), 0) AS ctr
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Pref]
WHERE DateID BETWEEN 20230801 AND 20230901
GROUP BY country_criteria_id
ORDER BY cost_usd DESC
```

### 7.2 Device Performance Breakdown

```sql
SELECT device,
       SUM(impressions) AS impressions, SUM(clicks) AS clicks,
       SUM(cost) / 1000000.0 AS cost_usd, SUM(Conversions) AS conversions
FROM [BI_DB_dbo].[BI_DB_Adwords_Geo_Pref]
GROUP BY device
ORDER BY cost_usd DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 20 T2, 0 T3, 0 T4, 1 T5 | Elements: 21/21, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Adwords_Geo_Pref | Type: Table | Production Source: Fivetran Google Ads*
