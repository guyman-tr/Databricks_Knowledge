# Lineage: BI_DB_dbo.BI_DB_FB_Performance

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Name** | BI_DB_FB_Performance |
| **Object Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_FB_Perf_Conv (first INSERT block) |
| **Production Source** | Facebook Ads API via Fivetran — `External_Fivetran_facebook_facebook_preformance_new` |
| **ETL Pattern** | Daily — DELETE WHERE date >= @date-7 AND date < @date+1 + INSERT (rolling 8-day window) |
| **UC Target** | _Not_Migrated |

## ETL Pipeline

```
Facebook Ads API (Meta Business Manager)
  |-- Fivetran connector (facebook dataset) ----|
  v
Bronze/Fivetran/facebook/facebook_preformance_new  (lake, Parquet)
  |-- External_Fivetran_facebook_facebook_preformance_new (Synapse External Table)
  |-- SP_FB_Perf_Conv @date (first block)
  |   GROUP BY: date, DateToDateID(date), ad_id, adset_id, campaign_id, account_id,
  |             ad_name, adset_name, campaign_name, account_name
  |   AGGREGATE: SUM(ISNULL(clicks,0)), SUM(ISNULL(impressions,0)), SUM(ISNULL(spend,0))
  |   NOTE: device_platform in external table is NOT in GROUP BY — aggregated over
  |   DELETE 8-day rolling window (@date-7 to @date+1)
  v
BI_DB_dbo.BI_DB_FB_Performance
  (595,616 rows | Oct 2020 – Jan 2026 | ROUND_ROBIN, HEAP)
  Feed status: INACTIVE since Jan 7, 2026 (last UpdateDate: 2026-01-15)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | date | External_Fivetran_facebook_facebook_preformance_new | date | Direct passthrough (GROUP BY key) | Tier 2 |
| 2 | date_id | Computed | [date] | BI_DB_dbo.DateToDateID([date]) function | Tier 2 |
| 3 | ad_id | External_Fivetran_facebook_facebook_preformance_new | ad_id | Direct passthrough (GROUP BY key); nvarchar(4000) in source → nvarchar(256) in dest | Tier 2 |
| 4 | adset_id | External_Fivetran_facebook_facebook_preformance_new | adset_id | Direct passthrough (GROUP BY key) | Tier 2 |
| 5 | campaign_id | External_Fivetran_facebook_facebook_preformance_new | campaign_id | Direct passthrough (GROUP BY key) | Tier 2 |
| 6 | account_id | External_Fivetran_facebook_facebook_preformance_new | account_id | Direct passthrough (GROUP BY key) | Tier 2 |
| 7 | ad_name | External_Fivetran_facebook_facebook_preformance_new | ad_name | Direct passthrough (GROUP BY key); nvarchar(4000) in source → nvarchar(256) in dest | Tier 2 |
| 8 | adset_name | External_Fivetran_facebook_facebook_preformance_new | adset_name | Direct passthrough (GROUP BY key); nvarchar(4000) in source → nvarchar(256) in dest | Tier 2 |
| 9 | campaign_name | External_Fivetran_facebook_facebook_preformance_new | campaign_name | Direct passthrough (GROUP BY key); nvarchar(4000) in source → nvarchar(256) in dest | Tier 2 |
| 10 | account_name | External_Fivetran_facebook_facebook_preformance_new | account_name | Direct passthrough (GROUP BY key); nvarchar(4000) in source → nvarchar(256) in dest | Tier 2 |
| 11 | clicks | External_Fivetran_facebook_facebook_preformance_new | clicks | SUM(ISNULL(clicks, 0)) — additive aggregate across device_platform | Tier 2 |
| 12 | impressions | External_Fivetran_facebook_facebook_preformance_new | impressions | SUM(ISNULL(impressions, 0)) — additive aggregate across device_platform | Tier 2 |
| 13 | spend | External_Fivetran_facebook_facebook_preformance_new | spend | SUM(ISNULL(spend, 0)) — additive aggregate across device_platform | Tier 2 |
| 14 | UpdateDate | ETL | GETDATE() | SET at INSERT time | Tier 2 |

## Source Objects

| Source Object | Type | Role |
|--------------|------|------|
| BI_DB_dbo.External_Fivetran_facebook_facebook_preformance_new | External Table | Fivetran Facebook Ads performance metrics from Bronze lake |

## UC External Lineage

UC Target: _Not_Migrated — no Unity Catalog lineage applicable.
