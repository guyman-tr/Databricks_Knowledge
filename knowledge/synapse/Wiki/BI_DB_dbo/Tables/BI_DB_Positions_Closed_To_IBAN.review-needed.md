# BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN — Review Needed

## Tier 4 Items

None.

## Open Questions

1. **External source provenance**: The source is `External_bi_output_finance_bi_db_positions_closed_to_iban_parquet`. Confirm where the finance BI output pipeline produces this file — is it a Databricks job or another ETL system?
2. **R&D design flaw**: The 2025-07-21 fix deduplicates child positions inheriting parent W2FIDs. Confirm this flaw has been resolved upstream, or if this workaround is permanent.

## Reviewer Corrections

None pending.
