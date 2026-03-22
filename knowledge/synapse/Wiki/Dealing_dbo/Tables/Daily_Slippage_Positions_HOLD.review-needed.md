# Review Sidecar — Dealing_dbo.Daily_Slippage_Positions_HOLD

## Auto-generated verification

| Check | Status | Notes |
|-------|--------|-------|
| Writer SP in SSDT | **N/A** | Decommissioned HOLD — no active SP; frozen **2023-06-14** |
| OpsDB / schedule | **N/A** | Refresh = **Frozen — decommissioned** |
| Live sample vs wiki | **OK (historical)** | Prior gate: max **Date** **2023-06-13**, ~**65.9M** rows — wiki reflects frozen state |
| Wiki template | **OK** | Property table, 8 sections, Elements **5 columns**, tier suffix **inline** in Description |
| Lineage file | **OK** | `Daily_Slippage_Positions_HOLD.lineage.md` — **do not** auto-edit |

## Items for human review

| # | Column / topic | Confidence | Question |
|---|----------------|------------|----------|
| 1 | Original writer SP | Low | Which procedure historically loaded this table — variant of execution/slippage SP family? |
| 2 | Retention / drop | Medium | Safe to drop or must remain for **regulatory audit**? |
| 3 | ChosenToTrigger vs TriggerToReceived | Medium | Confirm practical interpretation for audit replay vs ETL implementation |
| 4 | `[slippage %]` | Low | Confirm intentional column name (space + `%`) and quoting standard for consumers |
| 5 | Successor objects | Medium | Confirm authoritative replacement path after **`Dealing_Daily_Slippage_Positions`** decommission |

## Reviewer corrections

*(Empty — awaiting human review)*

## Tier distribution (wiki)

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No upstream production wiki |
| Tier 2 | 38 | Column semantics from DDL / structure / domain inference |
| Tier 3 | 0 | — |
| Tier 4 | 1 | `UpdateDate` ETL metadata |

**Quality score (wiki footer)**: 6.0

---

*Reformatted to standard DWH wiki template — Batch 7 (redo) — 2026-03-21*
