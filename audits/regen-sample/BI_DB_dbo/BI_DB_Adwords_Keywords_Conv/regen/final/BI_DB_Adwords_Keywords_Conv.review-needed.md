# Review Needed — BI_DB_dbo.BI_DB_Adwords_Keywords_Conv

## Tier 4 Items

| Column | Current Tier | Issue | Suggested Resolution |
|--------|-------------|-------|---------------------|
| id | Tier 4 — inferred from DDL | Column exists in DDL but SP comments out the INSERT mapping (`--,ad_id`). Always NULL across all 3,540 rows. | Confirm whether this column should be dropped from DDL or if the SP should be updated to populate it. |

## Questions for Reviewer

1. **OpenTrade_iOS2 naming inconsistency**: The column name suggests it maps to the iOS 2nd-gen app ("eToro: Crypto. Stocks. Social."), but the SP actually maps it to `'eToro: Investing made social (iOS) Open Trade'`. The "Investing made social" app is the Android 2nd-gen app — the (iOS) variant may be a third distinct listing or a naming error in the conversion_action_name. Should the column be renamed or documented differently?

2. **STALE data**: The SP has not run since 2023-09-18 (Synapse migration date). The date range (2023-06-19 to 2023-08-09) is shorter than the expected 90-day window. Is this table still in active use, or should it be marked for decommission?

3. **NULL vs 0 inconsistency in app columns**: 1st-gen app columns (android_reg, ios_reg, etc.) use `ELSE 0` in the CASE WHEN, while 2nd-gen and OpenTrade columns omit ELSE. This causes NULL vs 0.0 inconsistency. Is this intentional or a bug in the SP?

4. **LTV columns unique to this table**: LTV_Count and LTV_Value only appear in BI_DB_Adwords_Keywords_Conv — not in Ad_Conv, Geo_Conv, or other conversion tables. Should LTV tracking be extended to other grain levels?

## No Upstream Wiki for Tier 1

The production source is the Fivetran Google Ads external table, which has no documented wiki. All passthrough columns are classified as Tier 2 (SP code analysis). No Tier 1 inheritance is possible for this object — this is expected and correct given the Fivetran external table source.
