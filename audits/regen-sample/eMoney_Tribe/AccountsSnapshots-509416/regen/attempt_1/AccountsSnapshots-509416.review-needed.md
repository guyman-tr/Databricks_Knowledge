# Review Needed: eMoney_Tribe.AccountsSnapshots-509416

## Summary

All 9 columns are Tier 3 — no upstream wiki exists (`_no_upstream_found.txt` confirmed). Descriptions are grounded in DDL structure, SP code (`SP_eMoney_Reconciliation_ETLs`), and live data sampling.

## Items for Human Review

### 1. etr_y / etr_ym / etr_ymd — Purpose Unknown

- All three ETL partition columns (`etr_y`, `etr_ym`, `etr_ymd`) are consistently NULL across all sampled rows.
- These appear to be Generic Pipeline partition keys that were never populated for this table.
- **Action needed**: Confirm whether these columns are deprecated or actively used by a pipeline component not visible in SP code.

### 2. @Created vs Created — Semantic Difference

- `@Created` appears to be the XML source timestamp (varies per record).
- `Created` on older rows (pre-2024) is often set to `2023-12-20 18:07:56.937` regardless of `@Created`, suggesting a bulk reload/backfill occurred on that date.
- For recent data (2024+), `Created` matches `@Created`.
- **Action needed**: Confirm whether `Created` represents the original ingestion timestamp or the most recent reload timestamp.

### 3. Production Source Unresolved

- No upstream production database wiki exists for the Tribe XML ingestion pipeline.
- The table naming convention (`AccountsSnapshots-509416`) suggests an auto-generated name from the Tribe platform's export configuration.
- **Action needed**: Identify the Tribe platform API or export configuration that produces these XML files for richer lineage documentation.

### 4. UC Migration Status

- Table is marked `_Not_Migrated` — no Unity Catalog target exists.
- Given the table's role as a raw landing zone consumed by `SP_eMoney_Reconciliation_ETLs`, migration priority depends on whether the downstream ETL (`ETL_AccountSnapshot`) is being migrated.
- **Action needed**: Confirm UC migration plan for the eMoney Tribe raw landing tables.

### 5. Row Volume — 1.5B Rows

- At ~1.5 billion rows, this is a very large landing table. Consider whether historical data beyond the ETL watermark is still needed.
- **Action needed**: Validate retention policy for raw Tribe XML landing tables.
