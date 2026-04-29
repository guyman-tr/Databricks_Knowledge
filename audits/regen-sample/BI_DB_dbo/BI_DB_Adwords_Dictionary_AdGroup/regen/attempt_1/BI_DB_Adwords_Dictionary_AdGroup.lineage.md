# Lineage — BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|-------------|
| 1 | External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report | External Table | BI_DB_dbo | Synapse | Direct source (Fivetran Google Ads ad group performance report) |
| 2 | SP_Adwords_Pref_Conv | Stored Procedure | BI_DB_dbo | Synapse | Writer SP (Table #12 of 12, TRUNCATE+INSERT) |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | campaign_id | External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report | campaign_id | Passthrough | Tier 2 |
| 2 | ad_group_id | External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report | id | Rename (id → ad_group_id) | Tier 2 |
| 3 | ad_group_name | External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report | name | Rename (name → ad_group_name). WHERE name IS NOT NULL filter applied. | Tier 2 |
| 4 | target_cpa | — | — | NOT populated by SP. Column exists in DDL but is not included in INSERT statement. Always NULL. | Tier 4 |
| 5 | UpdateDate | SP_Adwords_Pref_Conv | GETDATE() | ETL metadata timestamp | Tier 5 |
| 6 | ad_group_status | External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report | status | Rename (status → ad_group_status) | Tier 2 |
