---
object: Dealing_dbo.Dealing_DailySpreadsAggregated
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_DailySpreadsAggregated

## Auto-Generated Flags

- [ ] **`AvgAskAt23` naming**: Column name implies hour 23 but actually captures average Ask at hours 14–16 UTC. Confirm exact hours from SP code and document the reason for the misleading name.
- [ ] **Hardcoded LP mapping**: SP contains 20 hardcoded LPs. Confirm whether this list is current or outdated (LPs may have been added/removed since SP was written).
- [ ] **STALE since 2025-02-17**: `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` disruption. Confirm if permanent.
- [ ] **`updateDate` casing**: Lowercase `updateDate` vs `UpdateDate` standard. Not a data issue but inconsistent.
- [ ] **NULL hours**: What does NULL in `hourN` mean — no trades in that hour vs. no data from that LP? Clarify for consumers.

## Reviewer Corrections

<!-- Add corrections here. -->
