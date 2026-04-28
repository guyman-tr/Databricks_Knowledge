# Review Sidecar -- Dealing_dbo.Dealing_Apex_PnL

## Auto-generated verification

| Check | Status | Notes |
|-------|--------|-------|
| Writer SP | OK | `Dealing_dbo.SP_Apex_PnL` (shared with Daily / EE variants) |
| Stale data flag | **ATTENTION** | Last row **2024-06-07**; last load **2024-06-08** — confirm pipeline status with Ops |
| Lineage sidecar | OK | `Dealing_Apex_PnL.lineage.md` present; LP external staging path |
| Tier suffixes in wiki | OK | All element descriptions end with `(Tier 2 — SP_Apex_PnL)` |
| Atlassian Phase 10 | OK | No sources — Section 8 placeholder retained |

## Items for human review

| # | Column / topic | Confidence | Question |
|---|----------------|------------|----------|
| 1 | Pipeline / LP | Medium | Was the **Apex Clearing** relationship ended or replaced around **June 2024**? What is the current US equities LP if not Apex? |
| 2 | Staging name | Low | What does **`EXT872_3EU_217314`** denote in **`LP_APEX_EXT872_3EU_217314`** (contract, account, feed version)? |
| 3 | Zero column | Medium | Confirm **`Zero`** from **`Dealing_DailyZeroPnL_Stocks`** is understood as **positions fully closed to zero units** within the window — any carve-outs? |
| 4 | PnL_DBPrice use | Medium | Is **`PnL_DBPrice`** used in a **formal reconciliation** pack vs Apex, or only ad hoc investigation? |
| 5 | Consumer inventory | Low | Which **Middle Office** reports or dashboards still reference this table post-2024-06? |

## Reviewer corrections

*(Empty -- awaiting human review)*

## Tier distribution (wiki)

| Tier | Count | Examples |
|------|-------|----------|
| Tier 2 | 21 | All columns traced to `SP_Apex_PnL` / staging joins |
| Tier 4 | 0 | — |

**Quality score (target):** 7.5

---

*Generated: 2026-03-21 | Batch: 7 (redo)*
