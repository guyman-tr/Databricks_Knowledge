---
object: Dealing_FailReasons_PIs
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - pi_filter_staleness
  - sparse_data_days
quality_score: 8.5
---

## Review Flags

### FLAG 1 — PI FILTER RELIES ON CURRENT GuruStatusID (MEDIUM)
**Severity**: Medium
**Description**: The PI filter (`GuruStatusID IN (5,6)`) is applied at SP run time using `DWH_dbo.Dim_Customer`, which reflects the customer's *current* PI status, not their status on the fail date. A customer who became a PI after a prior date's fails would be excluded from historical records; a customer who lost PI status would be included in historical rows.
**Action**: Accept as a known limitation. Historical backfills are not performed. When doing trend analysis, note that population composition may shift as PI statuses change.

### FLAG 2 — VERY SPARSE DATA ON QUIET DAYS (LOW)
**Severity**: Low
**Description**: On quiet trading days, PI fail counts can be 0–5 rows total. Any time-series analysis over this table should handle sparse days correctly (e.g., using a date dimension table for joins, not direct GROUP BY on Date).
**Action**: When building reports over this table, LEFT JOIN to a calendar dimension to avoid gaps in trend lines.
