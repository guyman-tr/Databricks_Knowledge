# Review Needed: BI_DB_dbo.BI_DB_AbuseAPI

## Critical: Table is Empty / Dormant

1. **0 rows**: This table has no data. The active counterpart is `Dealing_dbo.Dealing_AbuseAPI` (28,290 rows).
2. **Migration SR-222941**: SP_AbuseAPI was migrated from BI_DB_dbo to Dealing_dbo scope in December 2023 by Gili.
3. **DDL cleanup candidate**: Consider removing this DDL from the SSDT repo if no downstream process references it.

## Questions for Reviewer

- Should this table be formally decommissioned and the DDL removed from the SSDT repo?
- Is there any external process (PowerBI, ADF, Databricks) that still references BI_DB_dbo.BI_DB_AbuseAPI?
- The SP comment says "insert into dbo.BI_DB_AbuseAPI" but the code inserts into Dealing_dbo — was the comment intentionally left as a breadcrumb or just not updated?

## Column Count Discrepancy

- OpsDB assignment says 19 columns, DDL has 18 columns. DDL is authoritative. (OpsDB may count a row number or have stale metadata.)
