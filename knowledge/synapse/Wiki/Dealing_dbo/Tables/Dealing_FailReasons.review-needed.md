---
object: Dealing_FailReasons
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - other_bucket_opacity
  - null_hedgeserverid_ambiguity
quality_score: 9.0
---

## Review Flags

### FLAG 1 — "Other" BUCKET OPACITY (LOW)
**Severity**: Low
**Description**: ~100K–175K fails per day fall into "Other" — the SP's catch-all for unmatched LIKE patterns. This may include newly introduced fail message formats that the SP hasn't been updated to handle. The raw fail reasons are not preserved in this table.
**Action**: Periodically check `CopyFromLake.PositionFailReal_History_PositionFail_DWH` for high-frequency fail messages that are not matched by existing LIKE patterns and add them to the SP.

### FLAG 2 — NULL HedgeServerID SEMANTICS (LOW)
**Severity**: Low
**Description**: NULL in HedgeServerID means the failure occurred at a platform/validation level before reaching a specific hedge server (e.g., "insufficient funds" is checked before routing). This is intentional but may confuse consumers who filter `WHERE HedgeServerID IS NOT NULL`.
**Action**: Document in BI reports that NULL means "platform-level rejection, not server-specific" — do not interpret NULL as missing data.
