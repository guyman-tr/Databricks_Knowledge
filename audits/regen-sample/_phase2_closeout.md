# Phase 2 closeout — in-scope slop fix

_Closed 2026-04-28 14:29 UTC._

## Inputs

- 35 in-scope slop wikis (T4InfHits >= 1, in ALTER scope per `_alter_scope.json`).
- Pipeline: `regen_one.ps1` — preload_upstream → writer → judge → 1 retry.
- Driver: `run_all.ps1 -ManifestPath _phase2_manifest.csv -SkipFinishedObjects`.

## Headline

| Metric | Value |
|---|---|
| Total processed | 35 / 35 |
| Compare verdict BETTER | 26 (74%) |
| Compare verdict EQUIVALENT | 8 (23%) |
| Compare verdict WORSE | 1 (3%) |
| Total cost | $110.85 USD ($3.17/wiki incl. compare) |
| Avg score lift on BETTER | +1.6 points |
| Max score lift | +4.35 (`Dim_HistorySplitRatio`) |

For comparison, Phase 1 (25 obj) had 60% BETTER / 8% WORSE. **+14pp BETTER, −5pp WORSE** — the
preload-upstream fix (commit `9cfeb51`, adds writer-SP join discovery) is doing its job.

## Promoted (26)

All BETTER objects copied to live wiki tree via
`promote_regen.ps1 -FromList _phase2_approved.txt -AcceptVerdicts BETTER -Apply`.
Includes 3 objects whose regen got judge-verdict FAIL but are still strictly better than
what was in the wiki tree (CIDFirstDates, Boundary_Cost, HedgeCost).

Each promotion created `<file>.bak` next to the live file for rollback.
Promotion log: `audits/regen-sample/_promote_log_20260428_142924.csv`.

## Skipped — EQUIVALENT (8, no change to wiki tree)

- `BI_DB_dbo.BI_DB_Adwords_Keywords_Conv` (delta +0.2)
- `BI_DB_dbo.BI_DB_Adwords_Keywords_Pref` (delta +0.1)
- `BI_DB_dbo.BI_DB_Adwords_Search_Conv` (delta -0.3)
- `Dealing_dbo.Dealing_Apex_PnL_EE` (delta +0.1)
- `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` (delta +0.1)
- `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` (delta +0.0)
- `DWH_dbo.Dim_ContractType` (delta +0.25)
- `DWH_dbo.Fact_CurrencyPriceWithSplit` (delta +0.1)

These are tied with the current versions; no urgency to replace. Phase 3 may revisit if
score floor is raised.

## Skipped — WORSE (1, regression)

- `Dealing_dbo.Dealing_Execution_Slippage` (regen 6.80 vs current 7.90, delta −1.10)

Regen output kept at `audits/regen-sample/Dealing_dbo/Dealing_Execution_Slippage/regen/final/`
for diagnosis. **Live wiki untouched.**

## Deferred to Phase 3 — judge FAIL bucket (4)

These 4 objects scored < 8.0 even after MaxAttempts=2 retry. Three were promoted anyway
(better than current); one was skipped as a regression. All four belong on the polish
queue for Phase 3 (re-run with hand-tuned bundles or MaxAttempts=3).

| Object | Regen score | Promoted? |
|---|---:|---|
| `BI_DB_dbo.BI_DB_CIDFirstDates` | 7.30 | YES (was 4.80) |
| `Dealing_dbo.Dealing_Boundary_Cost` | 6.95 | YES (was 4.25) |
| `Dealing_dbo.Dealing_HedgeCost` | 7.30 | YES (was 4.20) |
| `Dealing_dbo.Dealing_Execution_Slippage` | 6.80 | NO (was 7.90 — regression) |

## What's next

- **Loop is now safe to start** with the new pipeline:
  `powershell -File .claude/scripts/run-dwh-wiki-harness-loop.ps1 -SchemaName BI_DB_dbo -BatchSize 4 -MaxObjects 10`
  for a 10-object pilot, then full 593-object newbuild backlog (Phase 4).
- Or run Phase 3 first: 307 already-documented in-scope wikis with `Q < 8.0`
  (~$770, ~3 days). See `.cursor/plans/phase3_in_scope_doc_upgrade_a8d72f01.plan.md`.
