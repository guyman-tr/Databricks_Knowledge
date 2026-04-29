# Review Needed: BI_DB_dbo.LTV_FromDB_ToBigQuery

## Tier 2 Items Requiring Context

1. **Revenue8Y_LTV_New (Tier 2)**: Description inherited from BI_DB_LTV_BI_Actual wiki. The new methodology (2023+) details are documented there.
2. **FirstDepositDate (Tier 2)**: Sourced from BI_DB_CIDFirstDates context. The date type is `datetime` here but `date` in BI_DB_LTV_BI_Actual — verify if the implicit widening matters for BigQuery consumers.

## Questions for Reviewer

- What is the downstream BigQuery process that consumes this data? Is it an ADF pipeline, Databricks notebook, or another mechanism?
- Is the 90-day window hardcoded intentionally, or should it be configurable? The SP takes @date as a parameter but the 90-day lookback is fixed in the code.
- Should this table be migrated to a direct BigQuery export from Databricks UC instead of Synapse?

## Cross-Object Consistency

- CID: Matches BI_DB_LTV_BI_Actual.CID description (Tier 1 — Customer.CustomerStatic). ✓
- FirstDepositDate: Matches BI_DB_LTV_BI_Actual.FirstDepositDate description (Tier 2). ✓
- Revenue8Y_LTV_New: Matches BI_DB_LTV_BI_Actual.Revenue8Y_LTV_New description (Tier 2). ✓
