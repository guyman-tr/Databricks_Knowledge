# Review Needed: BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH

## Summary

Partition-switch shadow table — transient infrastructure artifact with no independent business logic. All 169 columns are identical to `BI_DB_CID_DailyPanel_FullData` (created via `SELECT TOP 0 *`). Table is always empty at rest (0 rows).

## Tier 4 Items

| Column | Current Tier | Reason | Suggested Action |
|--------|-------------|--------|-----------------|
| FirstAction | Tier 4 | Deprecated -- always NULL. SP explicitly writes `NULL AS FirstAction`. Inherited from parent table. | Confirm column is still required in DDL or flag for removal |
| FirstInstrument | Tier 4 | Deprecated -- always NULL. SP explicitly writes `NULL AS FirstInstrument`. Inherited from parent table. | Confirm column is still required in DDL or flag for removal |

## Schema Drift Risk

- **DDL column count mismatch**: This SWITCH table DDL has 169 columns, while the parent `BI_DB_CID_DailyPanel_FullData` has 183 columns (14 columns added 2024-2025). The CREATE SP handles this by re-creating from `SELECT TOP 0 *` at each run, but the SSDT DDL is out of sync.
- **SSDT DDL partition range**: DDL shows partitions 20180101-20210430, but the SP dynamically creates 3 partitions around the target date. The SSDT DDL does not reflect runtime partition state.

## Questions for Reviewer

1. Should the SSDT DDL for `_SWITCH` be updated to match the parent table's 183 columns (currently 169)? The SP handles this dynamically, but the SSDT DDL divergence could cause confusion.
2. Is this table still actively used in the daily load process, or has the ETL been migrated to a different partition-switching mechanism?
3. Should this infrastructure table be documented in the wiki at all, or should it be blacklisted as a transient staging artifact?
