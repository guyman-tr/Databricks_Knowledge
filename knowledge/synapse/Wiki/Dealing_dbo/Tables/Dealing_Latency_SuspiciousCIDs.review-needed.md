---
object: Dealing_dbo.Dealing_Latency_SuspiciousCIDs
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Latency_SuspiciousCIDs

## Auto-Generated Flags

- [ ] **`OccurredAtProvider` source stale since Jan 2025**: SP is OpsDB-tracked and still running, but the `Dealing_OccurredAtProvider_Latency_Instrument` cross-reference stopped Jan 11, 2025. Confirm whether the SP gracefully handles empty source data or is silently producing no results.
- [ ] **NULL sentinel rows**: SP inserts a NULL row when `CountINT = 0` to preserve `UpdateDate`. Confirm this is still the behavior and document the sentinel pattern for downstream consumers.
- [ ] **`Date` is datetime**: Stored as datetime vs date in sibling tables — confirm if time component is meaningful.
- [ ] **`Dealing_Latency_SuspiciousCIDs_Email` not documented**: Companion table is written by the same SP. Should it be a standalone wiki entry?

## Reviewer Corrections

<!-- Add corrections here. -->
