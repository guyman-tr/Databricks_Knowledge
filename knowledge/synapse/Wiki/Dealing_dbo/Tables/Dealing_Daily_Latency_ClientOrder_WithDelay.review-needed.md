---
object: Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Daily_Latency_ClientOrder_WithDelay

## Auto-Generated Flags

- [ ] **STALE since 2025-01-11**. Verify if SP decommissioned.
- [ ] **Type inconsistencies**: IsBuy=int, IsSettled=int — confirm if intentional vs AllPositions (bit/tinyint).
- [ ] **"WithDelay" scope**: Confirm what threshold or filter defines "WithDelay" — the SP code doesn't explicitly filter by latency threshold before inserting here. Is this ALL positions or specifically delayed ones?

## Reviewer Corrections

<!-- Add corrections here. -->
