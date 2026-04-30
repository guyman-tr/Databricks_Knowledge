# Review Needed: BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results

## Tier 2 Items (all columns -- no upstream wiki available for this derived table)

All 10 columns are Tier 2 (ETL-computed by SP_EY_Audit_Auditor_Unrealized_Calculations). This is expected: the table is entirely derived from position-level audit calculations and client balance aggregates. There is no production source table to inherit Tier 1 descriptions from.

## Open Questions

1. **IsPriceFound column purpose**: The column is hardcoded to NULL in the INSERT. It exists in the DDL (int type) but is never populated. Confirm whether this is a deprecated placeholder or if there are plans to populate it with aggregate price-found metrics.

2. **Division by zero risk**: `Diff_Percentage` is computed as `ABS((Metric_a_Value - Metric_b_Value) / Metric_b_Value * 100)`. If `Metric_b_Value` (Client Balance aggregate) is 0, this will cause a divide-by-zero error. The SP does not guard against this. Verify whether this is a known edge case or if the Client Balance aggregates are guaranteed to be non-zero.

3. **UC migration status**: The table is not confirmed in the generic pipeline mapping. Confirm whether this audit table is intended for Databricks export or remains Synapse-only.

## Notes

- Bundle inheritance used: YES -- the SP code and companion table wiki (`BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation`) from the bundle were used to trace all column transformations.
- No upstream Tier 1 sources exist for this table -- all columns are ETL-computed labels, calculations, or metadata timestamps.
