---
object: Dealing_Fails_PI_ErrorCodes
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - no_etl_sp_identified
  - stale_lookup_risk
quality_score: 7.5
---

## Review Flags

### FLAG 1 — NO AUTOMATED ETL SP IDENTIFIED (MEDIUM)
**Severity**: Medium
**Description**: No stored procedure populates this table on a schedule. It is maintained manually or via ad-hoc load. The platform adds new error codes when new features are released, and there is no automated process to keep the lookup in sync.
**Action**: Identify the owner of this lookup table and establish a process to update it when new platform error codes are introduced. A periodic check query (see Section 7) can alert when unmapped codes appear in `Dealing_Fails_PI`.

### FLAG 2 — STALE LOOKUP CAUSES NULL Generic_FailReason (MEDIUM)
**Severity**: Medium
**Description**: Any error code emitted by the platform that is not yet in this table will produce `NULL` in `Dealing_Fails_PI.Generic_FailReason`. Over time, as new error codes are introduced, the NULL rate may increase, degrading the usability of `Generic_FailReason` for fail analysis.
**Action**: Run the unmapped error code check query (Section 7) monthly. When new codes are found, add them to this lookup. The lookup is a critical dependency for the usefulness of `Dealing_Fails_PI.Generic_FailReason`.
