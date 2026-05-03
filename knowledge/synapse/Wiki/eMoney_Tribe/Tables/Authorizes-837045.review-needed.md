# Review Needed: eMoney_Tribe.Authorizes-837045

## Summary

All 9 columns are Tier 3 — no upstream production wiki exists (`_no_upstream_found.txt` confirmed). Descriptions are grounded in DDL structure, SP_eMoney_Reconciliation_ETLs code analysis, and live data sampling.

## Items for Human Review

### 1. Created vs @Created Semantics
- **Issue**: The table has both `@Created` (datetime2) and `Created` (datetime2). `@Created` is the XML ingestion metadata timestamp used as the incremental watermark. `Created` is ~11% NULL in recent data and its exact semantic origin is unclear.
- **Action needed**: eMoney/Tribe team to clarify whether `Created` represents a business event timestamp, a secondary ingestion timestamp, or a redundant field.

### 2. etr_y / etr_ym / etr_ymd Purpose
- **Issue**: These Generic Pipeline temporal partition markers are 99.8% NULL across the dataset. They are not consumed by any downstream SP.
- **Action needed**: Confirm whether these columns are vestigial from the Generic Pipeline schema or actively populated for a subset of records. Consider whether they can be dropped.

### 3. No Upstream Production Wiki
- **Issue**: `_no_upstream_found.txt` marker present. The Tribe card processing platform has no documented wiki in any upstream repo (DB_Schema, ExperianceDBs, etc.).
- **Action needed**: If Tribe platform documentation becomes available, column descriptions should be upgraded from Tier 3 to Tier 1.

### 4. @FileName Deprecated in ETL
- **Issue**: `@FileName` is stored but no longer used in SP_eMoney_Reconciliation_ETLs (replaced with `NULL` at line 453). The column still receives data from the Generic Pipeline.
- **Action needed**: Confirm whether `@FileName` is used by any other consumer or if it can be considered metadata-only.

### 5. UC Migration Status
- **Issue**: Table is marked `_Not_Migrated` to Unity Catalog.
- **Action needed**: Determine if eMoney_Tribe raw landing tables are candidates for UC migration or if only the downstream ETL_ tables (eMoney_dbo) will be migrated.
