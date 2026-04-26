# Lineage: BI_DB_dbo.BI_DB_Bing_PBI_Group_Dict

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object** | BI_DB_Bing_PBI_Group_Dict |
| **Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_Bing_PBI |
| **Primary Source** | External_Fivetran_bingads_ad_group_history |
| **Source Lake Path** | Bronze/Fivetran/bingads/ad_group_history |
| **Source Type** | Fivetran connector (Microsoft Advertising / Bing Ads API) |
| **Upstream Wiki** | None — external third-party source |
| **UC Target** | _Not_Migrated |

## ETL Chain

```
Microsoft Advertising (Bing Ads) — ad_group_history endpoint
  |-- Fivetran bingads connector ---|
  v
Azure Data Lake Bronze/Fivetran/bingads/ad_group_history (Parquet)
  |-- External_Fivetran_bingads_ad_group_history ---|
  v
SP_Bing_PBI @date (TRUNCATE TABLE + INSERT with GROUP BY dedup)
  v
BI_DB_dbo.BI_DB_Bing_PBI_Group_Dict
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | id | External_Fivetran_bingads_ad_group_history | id (bigint) | Passthrough — implicit type conversion bigint→varchar(max) in target | Tier 2 |
| 2 | status | External_Fivetran_bingads_ad_group_history | status | Passthrough | Tier 2 |
| 3 | campaign_id | External_Fivetran_bingads_ad_group_history | campaign_id | Passthrough | Tier 2 |
| 4 | name | External_Fivetran_bingads_ad_group_history | name | Passthrough | Tier 2 |
| 5 | bid_strategy_type | External_Fivetran_bingads_ad_group_history | bid_strategy_type | Passthrough | Tier 2 |
| 6 | cpc_bid | External_Fivetran_bingads_ad_group_history | cpc_bid (float) | Passthrough — implicit conversion float→numeric(18,0) truncates decimal precision | Tier 2 |
| 7 | inherited_bid_strategy_type | External_Fivetran_bingads_ad_group_history | inherited_bid_strategy_type | Passthrough | Tier 2 |
| 8 | maximum_bid | External_Fivetran_bingads_ad_group_history | maximum_bid (float) | ISNULL(maximum_bid, 0) — NULL replaced with 0.0 | Tier 2 |
| 9 | network_distribution | External_Fivetran_bingads_ad_group_history | network_distribution | Passthrough | Tier 2 |
| 10 | _fivetran_synced | External_Fivetran_bingads_ad_group_history | _fivetran_synced | Passthrough | Tier 2 |
| 11 | UpdateDate | — | — | GETDATE() at SP execution time | Tier 2 |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No upstream production wiki (external Fivetran source) |
| Tier 2 | 11 | All columns — SP code and external table DDL |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Source Tables Referenced

| Source Object | Type | Lake Path |
|---------------|------|-----------|
| External_Fivetran_bingads_ad_group_history | External Table | Bronze/Fivetran/bingads/ad_group_history |
