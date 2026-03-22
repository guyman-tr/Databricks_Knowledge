---
object: Dealing_CIDs_CommissionsAndFails_PIs
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pii_present
  - small_population
quality_score: 9.0
---

## Review Flags

### FLAG 1 — PII PRESENT (HIGH)
**Severity**: High
**Description**: Columns `CID` and `UserName` are present. PIs are a named, identifiable group — even stricter access controls may apply as they are high-profile clients.
**Action**: Confirm appropriate RLS and data masking. Consider whether UserName exposure is required for the primary analytical use case.

### FLAG 2 — SMALL POPULATION, DATA GAPS EXPECTED (LOW)
**Severity**: Low
**Description**: Only 217 unique CIDs over 3 years. On days when fewer than 20 PIs have commission activity, fewer than 20 rows will exist. Queries using `TOP 1` or expecting exactly 20 rows per date will return incomplete results on sparse days.
**Action**: When building trend charts using this table, explicitly handle dates with fewer than 20 rows rather than assuming 20 rows always exist.
