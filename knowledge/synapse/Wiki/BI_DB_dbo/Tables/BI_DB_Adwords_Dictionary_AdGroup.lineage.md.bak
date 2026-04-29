# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads ad group performance report via Fivetran — used as dictionary source |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | campaign_id | Fivetran source | campaign_id | Passthrough | Tier 2 |
| 2 | ad_group_id | Fivetran source | id | Rename: id → ad_group_id | Tier 2 |
| 3 | ad_group_name | Fivetran source | name | Rename: name → ad_group_name | Tier 2 |
| 4 | target_cpa | N/A | N/A | NOT populated by SP — always NULL | Tier 4 |
| 5 | UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| 6 | ad_group_status | Fivetran source | status | Rename: status → ad_group_status | Tier 2 |

## Lineage Notes

- TRUNCATE+INSERT DISTINCT pattern — full refresh every run.
- target_cpa column exists in DDL but is NOT in the SP INSERT statement — always NULL.
- Added to SP by Amir on 2021-05-16.
- Source filtered by WHERE name IS NOT NULL.
