---
object: Dealing_PlayerLevel_Fails
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - other_bucket_opacity
  - playerlevel_id_non_sequential
quality_score: 9.0
---

## Review Flags

### FLAG 1 — "Other" BUCKET OPACITY (LOW)
**Severity**: Low
**Description**: The "Other" fail reason is the catch-all for unmatched LIKE patterns in the 28-bucket classification. At high tiers (Platinum Plus, Diamond), "Other" may be the dominant category because these clients see more execution-level failures (hedge server rejections) that don't match the standard message patterns.
**Action**: For high-tier analysis, supplement with `Dealing_Fails_PI.HedgeFailReason` to break down "Other" into more specific sub-categories at the row level.

### FLAG 2 — PlayerLevelID NON-SEQUENTIAL ORDERING (LOW)
**Severity**: Low
**Description**: PlayerLevelID values (1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond) do not map to tier order. Sorting ORDER BY PlayerLevelID will not give ascending tier hierarchy.
**Action**: Use CASE WHEN or join to a tier-order lookup when producing ordered tier reports. See `Dealing_PlayerLevel_Data` for the same note.
