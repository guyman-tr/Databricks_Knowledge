---
object: Dealing_dbo.Dealing_DailySpreadsAggregatedFX
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_DailySpreadsAggregatedFX

## Auto-Generated Flags

- [ ] **Stopped Apr 2024**: Confirm why FX data stopped ~10 months before the main table. Was this a deliberate scope removal from SP_DailySpreadsAggregated or a data issue?
- [ ] **Decommission candidate**: If FX spread monitoring has moved elsewhere, confirm whether this table should be deprecated/dropped.
- [ ] **`InstrumentName` varchar(50)** vs varchar(100) in main table — confirm if any FX instrument names exceeded 50 chars and were silently truncated.
- [ ] **`AvgAskAt23` naming**: Same misleading column name issue as parent table.

## Reviewer Corrections

<!-- Add corrections here. -->
