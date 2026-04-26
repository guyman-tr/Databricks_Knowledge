# BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict — Column Lineage

> Generated: 2026-04-21 | Pipeline Phase: 10B | Writer SP: SP_Bing_PBI

## ETL Chain

```
Bing Ads API (campaign definitions, bid strategies, status changes)
  |
  |-- Fivetran connector (bingads) ---|
  |   Incremental sync on campaign change
  |   Each campaign state change appends a new row
  v
BI_DB_dbo.External_Fivetran_bingads_campaign_history (external table — history feed)
  |
  |-- SP_Bing_PBI(@date) — runs daily via SB_Daily, Priority 20 ---|
  |   TRUNCATE TABLE BI_DB_Bing_PBI_Campaign_Dict
  |   INSERT SELECT ... FROM External_Fivetran_bingads_campaign_history
  |   GROUP BY all non-aggregated columns (deduplicates exact duplicates)
  |   No date filter — pulls full history on every run
  v
BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict (4068 rows, 622 distinct campaigns, 12 accounts)
  |
  |-- UC Target: _Not_Migrated
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | id | External_Fivetran_bingads_campaign_history | id | Pass-through (Bing campaign ID) | Tier 2 — SP_Bing_PBI |
| 2 | budget | External_Fivetran_bingads_campaign_history | budget | Pass-through — numeric(18,0) truncates decimal | Tier 2 — SP_Bing_PBI |
| 3 | account_id | External_Fivetran_bingads_campaign_history | account_id | Pass-through (Bing Ads account ID) | Tier 2 — SP_Bing_PBI |
| 4 | status | External_Fivetran_bingads_campaign_history | status | Pass-through | Tier 2 — SP_Bing_PBI |
| 5 | name | External_Fivetran_bingads_campaign_history | name | Pass-through | Tier 2 — SP_Bing_PBI |
| 6 | bid_strategy_max_cpc | External_Fivetran_bingads_campaign_history | bid_strategy_max_cpc | Pass-through — numeric(18,0) truncates sub-unit values | Tier 2 — SP_Bing_PBI |
| 7 | bid_strategy_target_cpa | External_Fivetran_bingads_campaign_history | bid_strategy_target_cpa | Pass-through — numeric(18,0) truncates decimal | Tier 2 — SP_Bing_PBI |
| 8 | bid_strategy_type | External_Fivetran_bingads_campaign_history | bid_strategy_type | Pass-through | Tier 2 — SP_Bing_PBI |
| 9 | _fivetran_synced | External_Fivetran_bingads_campaign_history | _fivetran_synced | Pass-through (Fivetran metadata timestamp) | Tier 2 — SP_Bing_PBI |
| 10 | UpdateDate | ETL system | GETDATE() | ETL timestamp at INSERT | Tier 2 — SP_Bing_PBI |

## History Table Pattern

| Property | Detail |
|----------|--------|
| Source type | Fivetran history table — one new row per campaign state change |
| Deduplication | GROUP BY all columns — only exact duplicates removed |
| Full snapshot | TRUNCATE+INSERT on every daily SP run |
| Row fan-out | 4068 rows for 622 distinct campaign IDs (~6.5 rows per campaign on average) |

## UC External Lineage

| UC Target | `_Not_Migrated` (not in Generic Pipeline mapping) |
|-----------|---|
