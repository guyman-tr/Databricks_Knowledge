---
object: Dealing_dbo.Dealing_Daily_Latency_AllPositions_StatusUpdateTime
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Daily_Latency_AllPositions_StatusUpdateTime

## Auto-Generated Flags

- [ ] **3-month window only**: Confirm if this was an intentional pilot.
- [ ] **56.9M rows in 3 months**: Higher daily density than the non-SUT variant (~100K/day vs ~58K/day). Verify if this is expected scope difference.
- [ ] **Naming ambiguity**: `ClientToExecutionLatency` measures routing (not fill) in this table. Consider flagging for rename if the table is ever revived.

## Reviewer Corrections

<!-- Add corrections here. -->
