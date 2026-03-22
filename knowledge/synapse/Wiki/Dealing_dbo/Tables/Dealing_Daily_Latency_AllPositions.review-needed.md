---
object: Dealing_dbo.Dealing_Daily_Latency_AllPositions
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Daily_Latency_AllPositions

## Auto-Generated Flags

- [ ] **295.7M ROWS**: Second largest position-level table in Dealing_dbo. Confirm if this is expected growth rate and if any retention/archival policy exists.
- [ ] **STALE since 2025-01-11**: Same as Dealing_Daily_Latency. Confirm if SP_Latency_Report was intentionally halted.
- [ ] **RoutedTime/ClientToRoutedLatency NULL before Oct 2024**: Confirm this is expected backfill absence (columns added SR-274939).

## Reviewer Corrections

<!-- Add corrections here. -->
