---
object: Dealing_PlayerLevel_Fails_PIs
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - extreme_sparsity
  - other_dominance_limits_utility
quality_score: 7.5
---

## Review Flags

### FLAG 1 — EXTREME DATA SPARSITY (LOW)
**Severity**: Low
**Description**: This table is extremely sparse — only 1–2 rows per date at most (Diamond + Platinum Plus with "Other"). Most fail reason categories will never appear in this table because PIs don't trigger size-validation or funds-check failures. On quiet market days, the table may have 0 rows.
**Action**: When building dashboards from this table, handle zero-row dates gracefully (LEFT JOIN to a calendar dimension). Do not interpret a missing row as "data not loaded."

### FLAG 2 — "Other" DOMINANCE LIMITS ANALYTICAL VALUE (MEDIUM)
**Severity**: Medium
**Description**: "Other" is the only fail reason that consistently appears for PI clients at high tiers. This limits the analytical value of this table compared to its full-population counterpart. The root cause is that PI execution failures tend to be hedge-server-level rejections, which produce free-text fail messages not matched by the 28-bucket LIKE patterns.
**Action**: For meaningful PI fail analysis, use `Dealing_Fails_PI` (row-level) with `IsPI = 1` filter and examine `HedgeFailReason` to break down the "Other" category. This aggregate table is useful for quick volume checks but not for root-cause analysis of PI fails.
