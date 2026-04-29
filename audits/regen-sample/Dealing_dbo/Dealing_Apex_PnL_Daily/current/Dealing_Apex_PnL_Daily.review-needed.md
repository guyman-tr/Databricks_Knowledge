# Review Sidecar -- Dealing_dbo.Dealing_Apex_PnL_Daily

## Auto-generated verification

| Check | Status | Notes |
|-------|--------|-------|
| Writer SP | OK | `Dealing_dbo.SP_Apex_PnL` (daily INSERT path) |
| Stale data flag | **ATTENTION** | Last row **2024-06-07** — same freeze as WTD family |
| Lineage sidecar | OK | `Dealing_Apex_PnL_Daily.lineage.md` defers to WTD chain |
| Tier suffixes in wiki | OK | All elements `(Tier 2 — SP_Apex_PnL)` |
| History gap vs WTD | Review | Daily **MIN(Date)** is **2022-07-06** vs WTD **2021-02-10** |

## Items for human review

| # | Column / topic | Confidence | Question |
|---|----------------|------------|----------|
| 1 | Backfill | Low | Was **daily** history **ever backfilled** before **July 2022**, or was the daily path **deployed** then? |
| 2 | Primary consumer | Medium | Is **daily** the **primary** operational check, or was **WTD** the main Middle Office report? |
| 3 | Week-sum vs WTD | Medium | Any **known exceptions** where **sum(daily)** ≠ **WTD row** (corp actions, holidays, restatements)? |

## Reviewer corrections

*(Empty -- awaiting human review)*

## Tier distribution (wiki)

| Tier | Count | Examples |
|------|-------|----------|
| Tier 2 | 21 | All columns — same SP evidence as WTD |
| Tier 4 | 0 | — |

**Quality score (target):** 7.5

---

*Generated: 2026-03-21 | Batch: 7 (redo)*
