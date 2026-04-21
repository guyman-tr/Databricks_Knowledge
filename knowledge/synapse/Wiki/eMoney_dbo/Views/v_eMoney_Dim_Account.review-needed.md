# Review Needed — eMoney_dbo.v_eMoney_Dim_Account

Generated: 2026-04-21 | Reviewer: Data Engineering / eTM Platform Team

## Tier 4 Items (Requires Verification)

None — all 78 columns are direct pass-throughs from `eMoney_Dim_Account`. Tiers inherit from the base table (27 T1, 51 T2).

## Open Questions

1. **TOP (1000) without ORDER BY**: The view uses `TOP (1000)` with no `ORDER BY` clause. Row selection is non-deterministic — Synapse may return any 1,000 rows from the current-day result set. Was this intentional (freshness-check only, not analytical)? If the full row set on a refresh day exceeds 1,000, downstream consumers may silently receive incomplete data.

2. **Date filter renders view empty on non-refresh days**: The `WHERE CAST(GETDATE() AS DATE) = (SELECT CAST(UpdateDate AS DATE) FROM a)` predicate means the view returns 0 rows on any day that `SP_eMoney_Dim_Account` did not run. As of 2026-04-21, the last refresh was 2026-04-13 (8 days stale). Is this by design? Are consumers aware that the view is empty except on the SP run day?

3. **11 excluded columns vs. base table**: The view excludes these 11 columns from `eMoney_Dim_Account`: `RegAccountProgramID`, `RegAccountProgram`, `RegAccountSubProgramID`, `RegAccountSubProgram`, `HasAccountProgramChanged`, `HasAccountSubProgramChanged`, `AccountPropertiesTime`, `AccountPropertiesDate`, `CountAccountProgramChanges`, `CountAccountSubProgramChanges`, `Entity`. Was this an intentional data-governance decision (PII, sensitivity, relevance) or a maintenance gap?

4. **SP_eMoney_Dim_Account refresh frequency**: The view only shows data when `SP_eMoney_Dim_Account` ran today. How frequently does this SP run? If it runs daily, the window of data availability is ~1 day per week (weekdays only)? Confirm SP schedule to clarify when this view is queryable.

5. **UC migration status**: Marked `_Not_Migrated` — confirmed as an operational live-state view, not an analytical layer. If `eMoney_Dim_Account` (the base table) is migrated to UC Gold, should a corresponding UC view be created, or is the live-state pattern not needed in Databricks?

## Reviewer Corrections

*[To be filled by reviewer]*

## Flagged Risks

- **Silent empty result set**: Queries against this view on non-refresh days return 0 rows with no error. Consumers not aware of the date filter will get misleading empty results.
- **Non-deterministic TOP (1000)**: If the base table has >1,000 active accounts on a refresh day, the view may return a different subset each time it is queried — no ordering guarantee.
- **Base table column drift**: If `eMoney_Dim_Account` adds or removes columns, the view SELECT list (hardcoded 78 columns) will silently diverge unless the view DDL is updated.
