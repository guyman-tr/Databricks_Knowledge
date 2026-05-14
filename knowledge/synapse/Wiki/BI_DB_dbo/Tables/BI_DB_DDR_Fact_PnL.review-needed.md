# BI_DB_dbo.BI_DB_DDR_Fact_PnL — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Tier 5 — Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier | Change Summary |
|--------|-------------------|--------------|----------|----------------|
| IsSQF | SpotQuotedFuture flag (smaller-contract RealFutures on CME); GroupID=59 in Trade.InstrumentGroups | Tier 2 — "Sustainable & Quality-Focused instrument flag" | Tier 5 (user expert correction 2026-05-14) | Replaced fabricated narrative with grounded product semantic. |

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed) override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None — no Tier 4 placeholder columns in §4 Elements (2026-05-14 regen).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| InstrumentTypeID | Confirm full set of InstrumentTypeID values used in DDR reporting (4,5,6,10,12,73 are common but the enum may be larger) |
| IsSettled | Confirm whether IsSettled=1 means "real stock ownership" or "settled CFD" in all contexts — product naming may differ |

## Structural Questions

| Topic | Question |
|-------|----------|
| Orchestration | Which parent SB job calls SP_DDR_Fact_PnL and at what time? Confirm via OpsDB SB_Daily configuration |
| Lake merge keys | SP header (2025-12-07) mentions null handling for merge keys — validate downstream lake consumers handle ISNULL'd values correctly |

## Phase 16 — Adversarial Scorecard (2026-05-14 self-eval)

| Dimension | Score (1–10) | Notes |
|-----------|--------------|-------|
| Tier accuracy | 8.5 | Aggregate `SUM`/`COUNT` columns consistently Tier 2; `IsSQF` elevated to Tier 5 per expert correction |
| Upstream fidelity | 8.0 | `InstrumentTypeID`, `RealCID`, `IsBuy` inherited from local wikis; `IsLeveraged`/`NetProfit` trace to `Trade.PositionTbl` with SP transforms |
| Structural gates | 9.0 | Eight sections, 15 elements, UTF-8; UPSTREAM SEARCH LOG present |
| Source traceability | 9.0 | Verbatim `SP_DDR_Fact_PnL` + TVF predicates |
| **Weighted overall** | **~8.4** | SOFT — not a substitute for `validate-wiki.ps1` |

**Soft fails**

- OpsDB **ETL schedule** for `SP_DDR_Fact_PnL` not confirmed in this run  
- **`UnrealizedPnLChange`** cardinality / double-counting risks across partial-life positions not stress-tested in SQL

**Open questions**

- Should **`IsSQF`** migrate from Tier 5 to Tier 2 once `Function_Instrument_Snapshot_Enriched.md` fully documents CME / RealFutures product language in a Tier-2-acceptable way?  
- Does any consumer require **`InstrumentID`** grain (this table deliberately drops it)?
