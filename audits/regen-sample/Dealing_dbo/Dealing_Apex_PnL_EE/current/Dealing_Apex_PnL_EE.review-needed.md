# Review Sidecar -- Dealing_dbo.Dealing_Apex_PnL_EE

## Auto-generated verification

| Check | Status | Notes |
|-------|--------|-------|
| Writer SP | OK | `Dealing_dbo.SP_Apex_PnL` (equity WTD INSERT) |
| Stale data flag | **ATTENTION** | Last row **2024-06-07** |
| Lineage sidecar | OK | `Dealing_Apex_PnL_EE.lineage.md` — equity/transfers/dividends mapping |
| Tier suffixes in wiki | OK | Eight elements, all `(Tier 2 — SP_Apex_PnL)` |
| EE naming | Review | Wiki states **EE = equity-level** — confirm official glossary |

## Items for human review

| # | Column / topic | Confidence | Question |
|---|----------------|------------|----------|
| 1 | EE abbreviation | Medium | Is **EE** officially **“equity-level”** (or another term)? Update glossary if different. |
| 2 | Dividends tie-out | Medium | Does **`Dividends`** here equal **`SUM(Dealing_Apex_PnL.Dividends)`** per **`Date` + AccountNumber** in practice? Any **accrual vs cash** timing? |
| 3 | Transfers sign | Medium | Confirm **negative `Transfers`** means **withdrawal from Apex** — any **FX or internal mapping** quirks? |
| 4 | PnL + Dividends reporting | Medium | Which **Middle Office pack** defines **“total PnL”** — **`PnL` only** vs **`PnL + Dividends`**? |

## Reviewer corrections

*(Empty -- awaiting human review)*

## Tier distribution (wiki)

| Tier | Count | Examples |
|------|-------|----------|
| Tier 2 | 8 | Date, equity start/end, transfers, PnL, dividends, UpdateDate |
| Tier 4 | 0 | — |

**Quality score (target):** 7.5

---

*Generated: 2026-03-21 | Batch: 7 (redo)*
