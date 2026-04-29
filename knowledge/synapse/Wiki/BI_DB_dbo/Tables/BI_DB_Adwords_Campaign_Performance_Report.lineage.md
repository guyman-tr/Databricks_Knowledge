# Column Lineage: BI_DB_dbo.BI_DB_Adwords_Campaign_Performance_Report

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| External_Bronze_Fivetran_adwords_new_api_campaign_performance_report | Fivetran External Table | BI_DB_dbo | Google Ads campaign-level performance report via Fivetran |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | date | Fivetran source | date | Passthrough | Tier 2 |
| 2 | DateID | Fivetran source | date | DateToDateID(date) | Tier 2 |
| 3 | impressions | Fivetran source | impressions | Passthrough | Tier 2 |
| 4 | campaign_status | Fivetran source | status | Rename: status → campaign_status | Tier 2 |
| 5 | campaign_id | Fivetran source | id | Rename: id → campaign_id | Tier 2 |
| 6 | average_position | — | — | Deprecated (always NULL per SP — column commented out) | Tier 2 |
| 7 | campaign_name | Fivetran source | name | Rename: name → campaign_name | Tier 2 |
| 8-17 | (remaining) | Fivetran source | Various | Passthrough | Tier 2 |

## Lineage Notes

- All data from Fivetran Google Ads connector (campaign performance report).
- Direct passthrough with column renames.
- average_position column is deprecated (commented out in SP INSERT).
- Data is STALE: last update 2023-09-18, date range 2023-06-19 to 2023-09-17.
