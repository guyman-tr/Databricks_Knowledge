# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_campaign_perf_perf_campaign_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads campaign performance report via Fivetran — used as dictionary source |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | campaign_id | Fivetran source | campaign_id | Passthrough | Tier 2 |
| 2 | campaign_name | Fivetran source | campaign_name | Passthrough | Tier 2 |
| 3 | bidding_strategy_type | Fivetran source | bidding_strategy_type | Passthrough | Tier 2 |
| 4 | amount | Fivetran source | amount | Passthrough — campaign daily budget | Tier 2 |
| 5 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 6 | campaign_status | Fivetran source | campaign_status | Passthrough | Tier 2 |

## Lineage Notes

- TRUNCATE+INSERT DISTINCT pattern — full refresh every run.
- Source filtered by WHERE campaign_name IS NOT NULL.
- Uses older Fivetran schema (adwords_campaign_perf — no _new_api suffix).
