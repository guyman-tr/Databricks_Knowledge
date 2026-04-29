# Review Needed: BI_DB_dbo.BI_DB_Adwords_Dictionary_Campaign

## Critical: Data is Stale

1. **Last update: 2023-09-18**. SP has not run since Synapse migration.
2. **campaign_status uses lowercase** ('enabled') while Dictionary_AdGroup uses UPPERCASE ('ENABLED'). Inconsistent casing across cluster.

## Questions for Reviewer

- Has this dictionary been replaced by a Databricks-based lookup?
- The source Fivetran schema uses `adwords_campaign_perf` (no _new_api suffix) while most other Adwords tables use `_new_api`. Is this an older schema?
- 40 campaigns have empty bidding_strategy_type — is this a data quality issue or expected for certain campaign types?

## Cross-Object Consistency

- Central lookup table — referenced by all other Adwords tables via campaign_id.
- Part of SP_Adwords_Pref_Conv cluster (Table #11 of 12).
