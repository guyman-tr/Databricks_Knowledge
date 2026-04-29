# Review Needed: BI_DB_dbo.BI_DB_Adwords_Geo_Pref

## Critical: Data is Stale

1. **Last update: 2023-09-18**. SP has not run since Synapse migration.
2. **cost is in micros** — column renamed from cost_micros but value is NOT converted. Users must divide by 1,000,000.

## Questions for Reviewer

- Has geographic performance data moved to Databricks?
- Should cost be stored in actual currency units rather than micros for analyst usability?
- region_criteria_id is hardcoded NULL — should it be removed from DDL?
- external_customer_id is always equal to customer_id — should the duplicate be removed?

## Cross-Object Consistency

- Performance counterpart to BI_DB_Adwords_Geo_Conv (conversion breakdown).
- Denormalized campaign_name/ad_group_name may differ from Dictionary tables due to snapshot timing.
- Part of SP_Adwords_Pref_Conv cluster (Table #1 of 12 — first processed).
