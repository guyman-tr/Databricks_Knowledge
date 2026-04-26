# BI_DB_dbo.BI_DB_Bing_PBI_Daily_Perf — Column Lineage

**Generated**: 2026-04-21 | **Schema**: BI_DB_dbo | **Writer SP**: SP_Bing_PBI  
**Load pattern**: DELETE by date + INSERT (incremental daily) | **Row count**: 9,455,353  
**UC Target**: _Not_Migrated

---

## Source Objects

| Source Object | Type | Role |
|--------------|------|------|
| BI_DB_dbo.External_Fivetran_bingads_keyword_performance_daily_report | External Table | Primary source — Fivetran Bing Ads keyword-level daily performance data from data lake |

---

## ETL Pipeline

```
Microsoft Advertising (Bing Ads) API
  |-- Fivetran bingads connector (keyword_performance_daily_report) --|
  v
Data Lake (Azure Data Lake Storage)
  |-- External Table: External_Fivetran_bingads_keyword_performance_daily_report --|
  v
[SP_Bing_PBI @date: DELETE WHERE date=@date + INSERT WHERE date=@date]
  v
BI_DB_dbo.BI_DB_Bing_PBI_Daily_Perf (9,455,353 rows, 2022-01-01 to 2025-10-16)
  |-- _Not_Migrated (no UC target) --|

NOTE: SP_Bing_PBI also populates BI_DB_Bing_PBI_Group_Dict, BI_DB_Bing_PBI_Campaign_Dict,
      and BI_DB_Bing_PBI_Goals_Funnels in the same SP run.
```

---

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | delivered_match_type | External_Fivetran_bingads_keyword_performance_daily_report | delivered_match_type | Passthrough | Tier 2 |
| 2 | ad_group_id | External_Fivetran_bingads_keyword_performance_daily_report | ad_group_id | Passthrough | Tier 2 |
| 3 | campaign_id | External_Fivetran_bingads_keyword_performance_daily_report | campaign_id | Passthrough | Tier 2 |
| 4 | device_os | External_Fivetran_bingads_keyword_performance_daily_report | device_os | Passthrough | Tier 2 |
| 5 | device_type | External_Fivetran_bingads_keyword_performance_daily_report | device_type | Passthrough | Tier 2 |
| 6 | keyword_id | External_Fivetran_bingads_keyword_performance_daily_report | keyword_id | Passthrough | Tier 2 |
| 7 | language | External_Fivetran_bingads_keyword_performance_daily_report | language | Passthrough | Tier 2 |
| 8 | network | External_Fivetran_bingads_keyword_performance_daily_report | network | Passthrough | Tier 2 |
| 9 | top_vs_other | External_Fivetran_bingads_keyword_performance_daily_report | top_vs_other | Passthrough | Tier 2 |
| 10 | date | External_Fivetran_bingads_keyword_performance_daily_report | date | Passthrough (filter: date=@date) | Tier 2 |
| 11 | current_max_cpc | External_Fivetran_bingads_keyword_performance_daily_report | current_max_cpc | Passthrough (numeric(18,0) truncates decimals) | Tier 2 |
| 12 | impressions | External_Fivetran_bingads_keyword_performance_daily_report | impressions | Passthrough | Tier 2 |
| 13 | Clicks | External_Fivetran_bingads_keyword_performance_daily_report | clicks (lowercase) | Passthrough (case rename: clicks→Clicks) | Tier 2 |
| 14 | spend | External_Fivetran_bingads_keyword_performance_daily_report | spend | Passthrough (numeric(18,0) truncates decimals) | Tier 2 |
| 15 | average_position | External_Fivetran_bingads_keyword_performance_daily_report | average_position | Passthrough (numeric(18,0) truncates decimals) | Tier 2 |
| 16 | conversions | External_Fivetran_bingads_keyword_performance_daily_report | conversions | Passthrough | Tier 2 |
| 17 | quality_score | External_Fivetran_bingads_keyword_performance_daily_report | quality_score | Passthrough | Tier 2 |
| 18 | keyword_status | External_Fivetran_bingads_keyword_performance_daily_report | keyword_status | Passthrough | Tier 2 |
| 19 | assists | External_Fivetran_bingads_keyword_performance_daily_report | assists | Passthrough | Tier 2 |
| 20 | all_conversions | External_Fivetran_bingads_keyword_performance_daily_report | all_conversions | Passthrough | Tier 2 |
| 21 | _fivetran_synced | External_Fivetran_bingads_keyword_performance_daily_report | _fivetran_synced | Passthrough (Fivetran metadata) | Tier 2 |
| 22 | UpdateDate | Hardcoded | — | GETDATE() at SP execution | Tier 2 |

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 22 | All columns — Fivetran external source, no upstream wiki |
| **Total** | **22** | |
