# BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns -- all 75 columns have verified provenance (5 Tier 1, 68 Tier 2, 1 Tier 5, 1 Tier 3 equivalent).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| eToroPnL (col 49) | Confirm exact formula for close vs hold events -- does eToroPnL use EndForexRate for closes and SettlementPrice for holds, or is the logic more nuanced? |
| IsOpenEOD (col 63) | Uses FIRST_VALUE with DESC ordering -- confirm this correctly identifies closed positions when multiple close events exist on the same day. |
| PreviousProviderMargin (col 42) | LAG with "propagation" -- confirm the propagation mechanism across holiday gaps where no EOD row exists. |
| Weekend dummy rows | Weekend rows have mostly NULL values -- confirm whether downstream consumers filter these out or rely on them for date continuity. |

## Structural Questions

| Topic | Question |
|-------|----------|
| Downstream consumers | No SP-level downstream consumers identified. Confirm primary consumers (Tableau dashboards? Finance team manual queries?). |
| SQF Google Sheet reliability | SQF adjustments come from External_Fivetran_google_sheets_adj. Confirm SLA for Fivetran sync and what happens if the sheet is updated late. |
| Holiday loop coverage | Loop runs @date-2 to @date. Confirm this is sufficient for multi-day holidays (e.g., 3-day weekends, Christmas closures). The 2025-10-07 change added this loop. |
| Trader deduplication | 2025-03-16 fix for duplicate TraderIDs on reopened positions -- confirm this edge case is fully resolved and no further duplicates appear. |
| HedgeServerID = 150 invariant | All rows have HedgeServerID=150 (Marex). If a second futures broker is added, would a new table be created or would this table expand? |

## Change History Summary

| Date | Author | Change |
|------|--------|--------|
| 2025-02-13 | Guy M | Initial creation |
| 2025-03-16 | Guy M | Fix duplicate TraderIDs on reopened positions |
| 2025-05-29 | Guy M | Fix wrong join to ETO marex identification table (duplication) |
| 2025-06-25 | Guy M | Added SQF logic (adj from Fivetran google sheet) |
| 2025-07-01 | Guy M | OUTER APPLY + COALESCE for missing previous settlement data |
| 2025-07-07 | Guy M | Date parsing fix for inconsistent dealer gsheet formatting |
| 2025-10-07 | Markos Ch | Added loop for holiday coverage |
| 2025-10-29 | Markos Ch | Added Regulation column |
| 2025-11-06 | Markos Ch | Regulation uses RegulationIDOnOpen |

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 5 | PositionID, CID, InstrumentID, IsBuy, HedgeServerID |
| Tier 2 | 69 | All SP-derived business columns |
| Tier 5 | 1 | UpdateDate |

---

*Generated: 2026-04-26*

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
| IsSQF | SpotQuotedFuture flag — smaller-contract RealFutures on CME; `Trade.InstrumentGroups.GroupID = 59` via `Function_Instrument_Snapshot_Enriched`. | Tier 2 (lineage only) — "Technical lineage row, no business narrative" | Tier 5 (user expert 2026-05-14) | Replaced fabricated business narrative with grounded product semantic (SpotQuotedFuture, CME). |
