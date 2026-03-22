# Review Sidecar — Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD

## Auto-generated verification

| Check | Status | Notes |
|-------|--------|-------|
| Writer SP in SSDT | **N/A** | Decommissioned HOLD — frozen **2023-05-17** |
| OpsDB / schedule | **N/A** | Refresh = **Frozen — decommissioned** |
| HASH(`CID`) vs slippage HOLD | **Review** | CBH/HBC compensation HOLD use **HASH(CID)**; `Daily_Slippage_Positions_HOLD` is **ROUND_ROBIN** — confirm intentional platform design / load era |
| Wiki template | **OK** | Property table, 8 sections, Elements **5 columns**, tier suffix **inline** |
| CBH / HBC cross-ref | **OK** | Wiki **Relationships** links **HBC_HOLD**; routing labels documented (**Citadel / BofA / HSBC**) |
| Lineage file | **OK** | `Dealing_Best_Execution_Compensation_CBH_HOLD.lineage.md` — **do not** auto-edit |

## Items for human review

| # | Column / topic | Confidence | Question |
|---|----------------|------------|----------|
| 1 | CBH acronym / routing | Medium | Confirm **Citadel → BofA → HSBC** ordering matches internal LP documentation |
| 2 | Compensation actioning | Medium | Were **`Compensation`** values ever posted to payments / credits, or analysis-only? |
| 3 | `Compensation` vs `Compensation_Limit` | Medium | Confirm cap logic (`MIN` of slippage vs limit, or other rule) for audit reconstruction |
| 4 | `Percent_Diff` denominator | Medium | Confirm formula vs **`CustomerChosenRate`** / **`LP_Rate`** sign conventions |
| 5 | Pair with HBC | Low | Confirm same pipeline authored both variants (same **UpdateDate** stop) |

## Reviewer corrections

*(Empty — awaiting human review)*

## Tier distribution (wiki)

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No upstream production wiki |
| Tier 2 | 47 | DDL / structural parity with non-HOLD CBH table |
| Tier 3 | 0 | — |
| Tier 4 | 1 | `UpdateDate` ETL metadata |

**Quality score (wiki footer)**: 5.5

---

*Reformatted to standard DWH wiki template — Batch 7 (redo) — 2026-03-21*
