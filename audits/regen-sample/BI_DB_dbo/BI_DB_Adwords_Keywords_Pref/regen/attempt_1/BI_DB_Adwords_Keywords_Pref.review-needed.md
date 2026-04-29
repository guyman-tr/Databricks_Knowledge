# Review Needed — BI_DB_dbo.BI_DB_Adwords_Keywords_Pref

## Tier 4 Items

| Column | Current Tier | Issue | Suggested Resolution |
|--------|-------------|-------|---------------------|
| id | Tier 4 — inferred from DDL | Column exists in DDL but SP comments out the INSERT (`--,id`). Always NULL across all 223,519 rows. | Confirm if this column should be removed from the DDL or if it was intentionally retained for future use. |

## Data Staleness

- **Last refresh**: 2023-09-18 (all rows have identical UpdateDate)
- **Date range**: 2023-06-19 to 2023-09-17 (91 days)
- **SP Status**: SP_Adwords_Pref_Conv has not run since Synapse migration (2023-09-12)
- **Recommendation**: Confirm whether this Fivetran pipeline has been decommissioned or if it should be restarted. If decommissioned, consider marking the table as deprecated.

## Search Impression Share Column Types

- `search_impression_share`, `search_budget_lost_top_impression_share`, and `search_rank_lost_impression_share` are stored as nvarchar(256) rather than float/decimal. This may cause confusion for analysts expecting numeric types. Consider whether a DDL change is warranted if the table is reactivated.

## No Upstream Wiki

- The production source is a Fivetran external table (Google Ads API) with no wiki documentation. All columns are Tier 2 (SP code analysis) rather than Tier 1 (upstream wiki). This is expected for Fivetran-sourced tables where the external table has no wiki coverage.
