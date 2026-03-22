---
object: Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime

## Auto-Generated Flags

- [ ] **3-month window only**: Confirm if Jul–Oct 2024 coverage was intentional pilot or incomplete backfill.
- [ ] **`ClientToExecutionLatency` naming mismatch**: In this table the column measures routing (RequestOccurred→StatusUpdateTime), not fill. Confusing for anyone joining with the main WithDelay table. Flag for rename if revived.
- [ ] **No `HedgeServerID`**: Main WithDelay table has `HedgeServerID` (added SR-274939 Oct 2024). This table lacks it — confirm if intentional scope difference.

## Reviewer Corrections

<!-- Add corrections here. -->
