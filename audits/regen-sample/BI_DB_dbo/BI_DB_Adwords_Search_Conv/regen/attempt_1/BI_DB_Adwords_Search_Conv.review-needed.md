# Review Needed — BI_DB_dbo.BI_DB_Adwords_Search_Conv

## Tier 4 Columns (2)

| Column | Reason | Suggested Action |
|--------|--------|-----------------|
| keyword_id | SP has this column commented out in the INSERT statement. Always NULL across all 12,992 rows. DDL retains the column. | Confirm if column should be dropped from DDL or if there is a plan to populate it. |
| search_key | SP has this column commented out in the INSERT statement. The SP comment shows a composite key formula with a syntax error. Always NULL. | Confirm if column should be dropped from DDL or if the composite key formula was abandoned. |

## Redundant Columns

| Column | Issue |
|--------|-------|
| query_targeting_status | Always identical to query_match_type_with_variant — both are mapped from Fivetran search_term_match_type. Unlike Search_Perf (where query_targeting_status is NOT populated), here both columns receive the same value. |
| external_customer_id | Always identical to customer_id — SP inserts customer_id into both columns. |

## Data Staleness

- **Last refresh**: 2023-09-18 (SP_Adwords_Pref_Conv has not run since Synapse migration)
- **Month range**: 2023-05-01 to 2023-08-01 (only 4 months)
- **Volume drop-off**: May (6,132) → Jun (5,863) → Jul (889) → Aug (108). Sharp decline in July/August suggests the conversion pipeline was already winding down before the SP stopped.
- **All UpdateDate identical**: 2023-09-18 16:48:00.327 — single bulk load, no incremental updates.

## Missing Features vs. Sibling Tables

| Feature | This Table | Keywords_Conv (Table #6) | Ad_Conv (Table #5) |
|---------|-----------|-------------------------|-------------------|
| 2nd-gen app columns (Regs_IOS2, etc.) | No | Yes | Yes |
| LTV metrics (LTV_Count, LTV_Value) | No | Yes (unique) | No |
| Open Trade events | No | Yes (unique) | No |
| FTDA/MTDA value columns | Yes | Yes | Yes |
| KeywordMatchType dimension | No | Yes | No |
| campaign_id | Yes | Yes | Yes |
| final_url | Yes | No | No |

## No Upstream Wiki Available

The upstream source is a Fivetran external table (`External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report`) which has no wiki documentation. All column descriptions are derived from SP code analysis (Tier 2) or DDL inference (Tier 4). The sibling tables in the bundle (Search_Perf, Keywords_Conv, Geo_Conv, etc.) are co-outputs from the same SP, not upstream sources.
