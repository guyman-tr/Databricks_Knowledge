---
object: Dealing_PlayerLevel_Data
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - ratio_division_by_zero
  - playerlevel_id_non_sequential
quality_score: 8.5
---

## Review Flags

### FLAG 1 — RATIO CAN BE NULL OR DIVISION BY ZERO (MEDIUM)
**Severity**: Medium
**Description**: `Ratio = Count_Fails / Success_Positions`. If `Success_Positions = 0` on a very quiet day for a tier, this produces a divide-by-zero or NULL. The SP may or may not handle this with NULLIF; the DDL allows NULL for the Ratio column.
**Action**: When using Ratio in reports, always apply `NULLIF(Success_Positions, 0)` or coalesce to 0. Do not treat NULL Ratio as "no fails" — it may mean "no successful trades to compare against."

### FLAG 2 — PlayerLevelID VALUES ARE NON-SEQUENTIAL (LOW)
**Severity**: Low
**Description**: PlayerLevelID is not 1–6 in order: 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond. This causes confusion when sorting by PlayerLevelID to get tier order. The ID values do not reflect the tier hierarchy.
**Action**: Always ORDER BY the text label (Bronze→Silver→Gold→Platinum→Platinum Plus→Diamond) or use a CASE WHEN to map to an ordinal for sorting. Never assume PlayerLevelID ordering equals tier ordering.
