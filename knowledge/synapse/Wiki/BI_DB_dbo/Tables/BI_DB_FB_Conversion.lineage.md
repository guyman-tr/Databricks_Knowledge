# Lineage: BI_DB_dbo.BI_DB_FB_Conversion

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Name** | BI_DB_FB_Conversion |
| **Object Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_FB_Perf_Conv (second INSERT block) |
| **Production Source** | Facebook Ads API via Fivetran — `External_Fivetran_facebook_cvr_facebook_conversion_actions` |
| **ETL Pattern** | Daily — DELETE WHERE date >= @date-7 AND date < @date+1 + INSERT (rolling 8-day window for 7-day attribution correction) |
| **UC Target** | _Not_Migrated |

## ETL Pipeline

```
Facebook Ads API (Meta Business Manager)
  |-- Fivetran connector (facebook_cvr dataset) ----|
  v
Bronze/Fivetran/facebook_cvr/facebook_conversion_actions  (lake, Parquet)
  |-- External_Fivetran_facebook_cvr_facebook_conversion_actions (Synapse External Table)
  |-- SP_FB_Perf_Conv @date (second block)
  |   Filter: action_type IN ('complete_registration', 'offsite_conversion.custom.384730099048186', 'purchase')
  |   PIVOT: SUM(_7_d_click) per action_type into Registration/V2/FTD columns
  |   DateToDateID([date]) for date_id
  |   DELETE 8-day rolling window (@date-7 to @date+1)
  v
BI_DB_dbo.BI_DB_FB_Conversion
  (238,486 rows | Oct 2020 – Jan 2026 | ROUND_ROBIN, HEAP)
  Feed status: INACTIVE since Jan 7, 2026 (last UpdateDate: 2026-01-15)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | date | External_Fivetran_facebook_cvr_facebook_conversion_actions | date | Direct passthrough | Tier 2 |
| 2 | date_id | Computed | [date] | BI_DB_dbo.DateToDateID([date]) function | Tier 2 |
| 3 | ad_id | External_Fivetran_facebook_cvr_facebook_conversion_actions | ad_id | Direct passthrough (GROUP BY key) | Tier 2 |
| 4 | Registration | External_Fivetran_facebook_cvr_facebook_conversion_actions | _7_d_click | SUM(CASE WHEN action_type='complete_registration' THEN _7_d_click ELSE 0 END) | Tier 2 |
| 5 | V2 | External_Fivetran_facebook_cvr_facebook_conversion_actions | _7_d_click | SUM(CASE WHEN action_type='offsite_conversion.custom.384730099048186' THEN _7_d_click ELSE 0 END) | Tier 2 |
| 6 | FTD | External_Fivetran_facebook_cvr_facebook_conversion_actions | _7_d_click | SUM(CASE WHEN action_type='purchase' THEN _7_d_click ELSE 0 END) | Tier 2 |
| 7 | UpdateDate | ETL | GETDATE() | SET at INSERT time | Tier 2 |

## Source Objects

| Source Object | Type | Role |
|--------------|------|------|
| BI_DB_dbo.External_Fivetran_facebook_cvr_facebook_conversion_actions | External Table | Fivetran Facebook Ads conversion actions from Bronze lake |

## UC External Lineage

UC Target: _Not_Migrated — no Unity Catalog lineage applicable.
