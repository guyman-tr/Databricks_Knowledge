# Auto KB Full Findings Report (2026-06-19)

## Plain-English Summary

The pipeline is partly working:
- The latest one-command run completed successfully (`overall_ok=true`) with Confluence intentionally skipped.
- The implications dataset still shows historical failures from earlier runs.
- Net result: there is one real actionable change, several valid skips, and several old blockers still in the history window.

## What "Blocker" Means

A row is marked `BLOCKER` when an item failed to process due to a hard runtime issue (not a business decision), for example:
- agent timeout while processing UC items
- missing MCP tool/session for Confluence

This is different from `NO_CHANGE_SKIPPED`, which means:
- the system reviewed the item and intentionally decided there is no new durable knowledge to ingest.

## Source Artifacts Reviewed

- `Data_Skills_Automation/Auto_KB_Integrator/out/daily_once_latest.json`
- `Data_Skills_Automation/Auto_KB_Integrator/out/integrated_summary.md`
- `Data_Skills_Automation/Auto_KB_Integrator/out/implications_summary.csv`
- `Data_Skills_Automation/Auto_KB_Integrator/out/implications_rows.csv`
- `Data_Skills_Automation/Auto_KB_Integrator/out/integrated_agentic_appendix.md`

## Latest Run Health (Operational)

From `daily_once_latest.json`:
- `overall_ok = true`
- `staging = true`
- Confluence was skipped by flag (by request).
- Steps passed:
  - watcher_genie
  - watcher_uc_object
  - watcher_dbschema
  - watcher_confluence (skipped)
  - implications_report
  - integrator

Important note:
- This confirms the orchestrator now runs cleanly in the selected mode.

## Implication Totals (Current History Window)

From `implications_summary.csv`:
- `ACTIONABLE_CHANGE = 1`
- `BLOCKER = 5`
- `NO_CHANGE_SKIPPED = 6`

Interpretation:
- There is one candidate worth promoting.
- There are six legitimate "no new knowledge" outcomes.
- Five blocker rows are historical failures still present in the current report window.

## Actionable Skill/Doc Implication

Exactly one actionable item was found:
- App: `uc_object`
- Item: `main.bi_output.australia_tag_ob_june26`
- Status: `done`
- Implication: `ACTIONABLE_CHANGE`
- Artifact reference: `wiki:knowledge/UC_generated/bi_output/Views/australia_tag_ob_june26.md`

Meaning:
- This is the one concrete update candidate in the current findings.

## Rejected / Skipped Implications

`NO_CHANGE_SKIPPED` rows are expected and not failures. Main reasons recorded:
- Genie: knowledge already covered by existing skills.
- DBSchema: source-to-lake mapping and semantics already documented.
- Confluence (one row): page was new but had no tracked skill mapping, so skipped by non-spray rule.

These are valid rejects, not bugs.

## Blockers Found (Historical Rows)

Blocker rows in the dataset are mainly from earlier attempts:
- UC object processing timeouts (`cursor_sdk Agent.prompt timed out`)
- Confluence MCP unavailability (`no Confluence tools discovered` / `no MCP servers discovered`)

These rows remain visible because the implication report aggregates a time window, not only the latest clean run.

## Why It Looks Contradictory (Run Green vs Report Blocked)

Both statements are true:
- The latest orchestrated run was green in the chosen mode.
- The implication report includes older blocker rows still inside the lookback window.

So:
- "System can run now" = true.
- "History still contains failures" = also true.

## Recommended Read of the Current State

If your question is "did we find anything worth acting on right now?":
- Yes: one actionable UC item.

If your question is "are we fully stable across all modes with no past errors?":
- Not yet: historical blocker entries still exist in the report window.

## Next Practical Step

To reduce confusion in daily reporting, split outputs into:
- **Latest-run-only implications** (for go/no-go now)
- **History-window implications** (for reliability tracking)

That will prevent old blockers from masking what just worked.
