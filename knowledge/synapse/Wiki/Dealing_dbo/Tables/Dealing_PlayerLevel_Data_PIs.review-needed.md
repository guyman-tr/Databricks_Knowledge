---
object: Dealing_PlayerLevel_Data_PIs
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - sparse_tier_coverage
  - full_outer_join_nulls
quality_score: 8.5
---

## Review Flags

### FLAG 1 — ONLY 2 TIERS TYPICALLY PRESENT (LOW)
**Severity**: Low
**Description**: In observed data (2026-03-10), only Diamond (7) and Platinum Plus (6) tiers appear. Lower tiers (Bronze, Silver, Gold, Platinum) are not present because PIs rarely occupy those tiers. Consumers building reports across all 6 tiers will see no data for 4 of them.
**Action**: When joining this table to a tier dimension, use LEFT JOIN from the dimension side to avoid missing tiers from the result. Confirm whether lower-tier PI data is intentionally absent or should be backfilled.

### FLAG 2 — FULL OUTER JOIN SEMANTICS MAY PRODUCE NULLs (LOW)
**Severity**: Low
**Description**: The SP uses a FULL OUTER JOIN between the commission and fail data subsets for PIs. On a day where a tier has commission data but no fails (or vice versa), the ISNULL coalescing on PlayerLevel and PlayerLevelID columns means the label is taken from whichever side is non-NULL. The final values should be correct but the join pattern can produce unexpected NULLs in edge cases.
**Action**: When Count_Fails or TotalCommission is NULL (not zero), it means no data was found for that side of the FULL OUTER JOIN — not that the value was zero. Treat NULL as "no activity" for that dimension on that date.
