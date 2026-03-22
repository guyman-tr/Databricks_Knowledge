# Review Sidecar — Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD

## Auto-generated verification

| Check | Status | Notes |
|-------|--------|-------|
| Writer SP in SSDT | **N/A** | Decommissioned HOLD — frozen **2023-05-17** (same stop as **CBH_HOLD**) |
| Row volume vs CBH | **OK** | ~**49K** rows vs ~**10.2M** — wiki calls out routing penetration |
| Schema parity | **OK** | **48** elements — aligned with **CBH_HOLD** DDL |
| Wiki template | **OK** | Property table, 8 sections, Elements **5 columns**, tier suffix **inline** |
| CBH cross-ref | **OK** | Wiki **Relationships** links **CBH_HOLD**; routing **HSBC / BofA / Citadel** |
| Lineage file | **OK** | `Dealing_Best_Execution_Compensation_HBC_HOLD.lineage.md` — **do not** auto-edit |

## Items for human review

| # | Column / topic | Confidence | Question |
|---|----------------|------------|----------|
| 1 | HBC acronym / routing | Medium | Confirm **HSBC → BofA → Citadel** ordering matches internal LP documentation |
| 2 | Volume delta vs CBH | Medium | Narrow routing rules vs instrument subset — which gates excluded most flow? |
| 3 | Intersection diagnostic | Low | Should **PositionID** ever appear in **both** HOLD tables same **Date**? (Sample query in wiki) |
| 4 | Compensation policy | Medium | Same policy engine as **CBH** path — single SP with routing parameter? |
| 5 | Retention | Low | Archive-only — confirm no downstream legal hold exceptions |

## Reviewer corrections

*(Empty — awaiting human review)*

## Tier distribution (wiki)

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No upstream production wiki |
| Tier 2 | 47 | Structural analogy to **CBH_HOLD** |
| Tier 3 | 0 | — |
| Tier 4 | 1 | `UpdateDate` ETL metadata |

**Quality score (wiki footer)**: 5.5

---

*Reformatted to standard DWH wiki template — Batch 7 (redo) — 2026-03-21*
