---
object: Dealing_Fails_PI
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - misleading_pi_naming
  - count_bigint_overflow
  - staging_vs_copyfromlake_source
  - ispi_snapshot_timing
quality_score: 8.0
---

## Review Flags

### FLAG 1 — MISLEADING TABLE NAME (MEDIUM)
**Severity**: Medium
**Description**: The table name `Dealing_Fails_PI` implies PI-only data, but the table contains ALL position fails with an `IsPI` flag column. Consumers unfamiliar with this convention may incorrectly assume all rows are PI fails and skip the `IsPI` filter.
**Action**: Ensure any BI report or dashboard using this table documents that `WHERE IsPI = 1` must be added for PI-only analysis. Consider noting this distinction in any downstream Unity Catalog table description.

### FLAG 2 — COUNT(*) BIGINT OVERFLOW (HIGH)
**Severity**: High
**Description**: 3.97 billion rows exceeds the INT range (2.1B). Standard `COUNT(*)` returns INT and will throw arithmetic overflow on this table. This is a known data engineering pitfall.
**Action**: Always use `COUNT_BIG(*)` for row-count queries on this table. Databricks/Spark will handle this automatically, but T-SQL queries must be written with `COUNT_BIG`.

### FLAG 3 — DIFFERENT SOURCE PATH FROM CommissionsAndFails FAMILY (MEDIUM)
**Severity**: Medium
**Description**: This table reads from `Dealing_staging.PositionFailReal_History_PositionFail_DWH`, while `Dealing_FailReasons` and the CommissionsAndFails family read from `CopyFromLake.PositionFailReal_History_PositionFail_DWH`. These are two separate ingestion paths for the same production source. Any latency or coverage difference between the two paths could cause discrepancies between aggregated counts in `Dealing_FailReasons` and row-level counts summed from `Dealing_Fails_PI`.
**Action**: When reconciling counts, check both source paths. If discrepancies appear, investigate whether the staging vs CopyFromLake paths have different refresh cadences or coverage windows.

### FLAG 4 — IsPI REFLECTS RUN-TIME STATUS NOT HISTORICAL STATUS (LOW)
**Severity**: Low
**Description**: `IsPI` is set based on `GuruStatusID` from `Fact_SnapshotCustomer` at the time SP_Fails_PI runs. A client who gained or lost PI status after the fail date will show incorrect IsPI on historical rows.
**Action**: Accept as known limitation. Not corrected by backfill. Note in PI-specific analyses.
