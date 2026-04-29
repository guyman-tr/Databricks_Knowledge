# Review Needed — BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup

## Tier 4 Items

| Column | Current Tier | Issue | Suggested Resolution |
|--------|-------------|-------|---------------------|
| target_cpa | Tier 4 — inferred from DDL | Column exists in DDL but SP_Adwords_Pref_Conv does not include it in the INSERT statement. Always NULL across all 31,322 rows. | Confirm with BI team whether this column was planned for CPA bidding data and never implemented, or if it should be removed from the DDL. |

## Questions for Reviewer

1. **ad_group_id uniqueness**: 27,565 distinct ad_group_id values across 31,322 rows suggests some ad groups appear multiple times (possibly across different campaigns or due to SELECT DISTINCT not fully deduplicating). Is this expected behavior?
2. **Stale data**: SP_Adwords_Pref_Conv has not run since 2023-09-18. Is Google Ads data now sourced from a different pipeline (e.g., direct Databricks ingestion), or is this pipeline permanently decommissioned?
3. **target_cpa**: Was this column intended to store the Google Ads target CPA bidding value? If so, should the SP be updated to populate it from the Fivetran source, or should the column be dropped from the DDL?

## Notes

- This is a simple dictionary table (6 columns, TRUNCATE+INSERT pattern).
- Production source is Fivetran's Google Ads ad group performance report — no upstream wiki exists for the Fivetran external table.
- All upstream wikis in the bundle are sibling tables that JOIN TO this dictionary, not sources FOR it. Tier 1 inheritance does not apply since the production source (Google Ads API via Fivetran) has no documented wiki.
