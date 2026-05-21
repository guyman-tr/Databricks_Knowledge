# Handoff — DWH Wiki Corruption Cleanup

This file exists so a fresh Cursor chat can pick up this work cold. Read it in full before doing anything else.

## What this is

A multi-phase cleanup of corrupted Tier-1 column-documentation claims in the Synapse-mirror wikis under `knowledge/synapse/Wiki/` and their downstream propagation into `knowledge/UC_generated/`, `.alter.sql` files, live Unity Catalog column comments, and possibly `.cursor/skills/` and `.cursor/rules/`.

A prior independent LLM audit already detected 106 WRONG-verdict columns and emitted ready-to-paste `suggested_rewrite` text into `knowledge/_dwh_llm_judge_cache/*.json` — but **none of those fixes were ever applied**. A second new audit (`audits/_tier1_audit_dwh_dbo_2026-05-21T06-44-41Z/`) found an additional 474 FAILs in DWH_dbo alone, mostly via a new "Layer 1 structural promotion lie" detector that the old judge didn't have. Cleanup must reconcile both detection sources, apply all corrections, cascade through every downstream artifact, deploy to UC, and harden the generator to prevent regression.

## The plan you must execute

**`c:\Users\guyman\.cursor\plans\dwh_wiki_corruption_full_cleanup_0fed28b5.plan.md`**

23 todos, 6 phases (A-E + closing pass). Do NOT edit the plan. Read it in full first. Create your own TodoWrite list mirroring the 23 todos and execute them in order. Mark `in_progress` on entry, `completed` only when actually done.

Phase order (todo ids):
1. `reconcile` → `dag_loader` → `tvf_view_name_match` → `propagation_map`
2. `apply_wikis` → `regen_alter`
3. `cascade_synapse` → `cascade_uc_generated` → `cascade_skills`
4. `deploy_uc_dwh` → `deploy_uc_bi` → `deploy_uc_generated` (USER APPROVAL GATES)
5. `audit_dag_queue` → `audit_dag_walk` (the big DAG-walk of all remaining schemas)
6. `blame_origin` → `harden_generator` → `ci_gate` → `silent_lineage_audit`
7. `commit_phase_a` through `commit_phase_e`

## Existing artifacts (read these, do NOT rebuild)

| Path | What it is | Why |
|---|---|---|
| `audits/_tier1_audit_dwh_dbo_2026-05-21T06-44-41Z/report.csv` | 1,050 audited claims, 474 FAILs | Primary input to `reconcile` |
| `audits/_tier1_audit_dwh_dbo_2026-05-21T06-44-41Z/report.md` | Human summary + hot-list | Quick orientation |
| `audits/_tier1_audit_dwh_dbo_2026-05-21T06-44-41Z/compare.md/.html` | Side-by-side review view | Spot-checking |
| `audits/_tier1_audit_dwh_dbo_2026-05-21T06-44-41Z/credit_chain_spotcheck.md` | Worked example: `Credit` column blast radius from OLTP to UC live comments | **Validation reference — the generic machinery must catch and fix this end-to-end with no Credit-specific code anywhere** |
| `audits/_tier1_audit_cache/` | LLM judge cache for new audit (safe to keep across re-runs) | LLM cost saver |
| `knowledge/_dwh_llm_judge_cache/*.json` | 132 files, 106 WRONG verdicts with `suggested_rewrite` | Second input to `reconcile` |
| `knowledge/_dwh_llm_judge.csv` | Index of the above | Cross-reference |
| `knowledge/_dwh_judge_review.csv` | Possibly human-curated review | Cross-reference |
| `knowledge/_dictionary_truth.json` | Live-data truth used by earlier pass | Cross-reference |

## Pre-built tools (use as-is, do NOT rebuild)

| Path | Purpose |
|---|---|
| `tools/audit_tier1_claims.py` | Main audit CLI. Args: `--scope <dir>`, `--include-glob <glob>`, `--max-tags N`, `--no-llm`, `--judge-model claude-haiku`, `--cache-dir <dir>`, `--output <dir>`, `--progress-every N`. Defaults: scope=DWH_dbo, output=`audits/_tier1_audit_<UTC>`. |
| `tools/tier1_audit/parser.py` | Parses `(Tier N -- X)` tags and column rows from synapse/OLTP wikis. Handles 5-col DWH and 7-col OLTP layouts. Public: `find_tier1_claims(path) -> list[ColumnRow]`. |
| `tools/tier1_audit/resolver.py` | Resolves Tier-1 tag text → source wiki paths. Handles `Schema.Table`, `X via Y`, prose ("inherited from X wiki"), bare names, `Function_*` TVF lookup. |
| `tools/tier1_audit/source_lookup.py` | Fuzzy column-match against source wiki. Returns `(description, source_tier, source_confidence, is_oltp_truth)`. |
| `tools/tier1_audit/judge.py` | Claude CLI subprocess judge with SHA-256 on-disk cache. Substantive vs cosmetic prompt. |
| `tools/tier1_audit/reporter.py` | `AuditRow` dataclass, CSV/MD writers with hot-list + blast-radius table. |
| `tools/render_audit_compare.py` | Side-by-side compare renderer. Args: `--html`, `--filter-wiki <glob>`, `--only PASS\|FAIL`, `--severity HIGH\|MEDIUM\|LOW`, `--layer L0-unresolved\|L1-structural\|L2-semantic`, `--out-prefix <name>`. |
| `tools/merge_wiki_column_comments_into_alter.py` | Regen `.alter.sql` from corrected `.md`. Use for `regen_alter`. |
| `tools/audit_wiki_alter_comment_parity.py` | Verify `.md` ↔ `.alter.sql` agreement. Run after every regen. |
| `tools/scan_uc_comment_gaps.py` | Verify UC live comments after deploy. |
| `tools/deploy_canonical_uc_cols.py` / `tools/redeploy_schema.py` | UC deploy tooling (via `uc-deploy-comments` skill). |

## DAG truth files (the ONLY valid signals for downstream / ordering)

| File | Shape | Use for |
|---|---|---|
| `knowledge/UC_generated/_dag.json` | `nodes[]: {full_name, catalog, schema, table_type, wiki_status, routing_rule, cached_wiki_path, in_pilot_scope, topological_layer, source_code_available, column_count}` | Topological ordering. Filtering in-scope. UC full_name → schema. |
| `knowledge/UC_generated/_upstream_wiki_index.json` | `wikis[full_name]: {wiki_path, wiki_kind, synapse_schema, synapse_object, synapse_folder, column_count}` | Bidirectional UC full_name ↔ wiki_path. |
| `knowledge/UC_generated/<schema>/_discovery/column_lineage/<obj>.json` | `rows[]: {source_table_full_name, source_column_name, target_column_name, entity_type, event_count}` | **Column-level real lineage edges** from Databricks system tables. Authoritative for "this downstream column inherits from that upstream column". |
| `knowledge/synapse/Wiki/_upstream_wiki_routing.json` | `upstream_databases[db]: {wiki_path, schema_details[]}` | Synapse→OLTP routing. |

**`tools/cleanup_tier1/dag.py` (which you will build) is the ONLY allowed entry point for querying these.** Every other module imports from it. If you ever feel the urge to write `if column_name in wiki_text:`, **stop and ask the user** — that is the failure mode this entire cleanup is correcting for.

## Available skills (read SKILL.md before using)

- `.cursor/skills/uc-deploy-comments/SKILL.md` — all UC ALTER COLUMN deploys
- `.cursor/skills/upstream-wiki-router/SKILL.md` — Tier-1 source resolution conventions
- `.cursor/skills/tvf-enrichment/SKILL.md` — required reference for the `tvf_view_name_match` side task (Synapse TVFs materialised as VIEWs in `main.etoro_kpi[_prep]`)
- `.cursor/skills/wiki-review/SKILL.md` — pattern reference for interactive review flows (silent_lineage_audit sign-off)
- `.cursor/skills/databricks-connection/SKILL.md` — Databricks Python/MCP connection patterns

## Hard rules

1. **NEVER substring-match across MDs to discover downstream consumers.** Use `tools/cleanup_tier1/dag.py` (which you will build per the plan) and its `downstream_columns_of()` exclusively. The previous downstream process failed at scale because of substring matching — this entire cleanup exists to correct that.
2. **NEVER auto-write to wikis without going through `apply_corrections.py --dry-run` first.** User must see a diff preview before approving `--apply`.
3. **NEVER deploy to live UC without explicit user approval.** UC deploys (`deploy_uc_dwh`, `deploy_uc_bi`, `deploy_uc_generated`) are explicit gates — pause and ask. Local file edits + git commits proceed without asking per the plan.
4. **NEVER amend commits or force-push.** One commit per phase as specified in the plan's commit strategy.
5. **NEVER edit `c:\Users\guyman\.cursor\plans\dwh_wiki_corruption_full_cleanup_0fed28b5.plan.md`.** It is the contract.
6. **Ask the user about `conflict_flag=TRUE` rows in reconcile, `narrative_review_needed=TRUE` corrections, and silent_lineage_audit candidates.** Don't auto-resolve ambiguity.

## Operational guidance

- Work the todos in plan order. Don't skip ahead.
- Mark `in_progress` on entry, `completed` only when the artifact is actually produced and validated.
- Commit at every `commit_phase_*` checkpoint. Use `git status` + `git diff --stat` to confirm scope before each commit.
- After each major phase completes, append a line to `audits/_handoff_status.md` so the user can monitor progress without reading your chat. Include: phase name, todos done, todos remaining, anything needing user input, current git HEAD.
- If a tool throws repeatedly, write the error to `audits/_handoff_status.md` and ask the user — don't loop forever.
- After Phase D completes (the big DAG-walk), before `silent_lineage_audit`, explicitly cross-check the `Credit` chain in `credit_chain_spotcheck.md` and report findings. This is the natural test that the generic machinery worked.

## LLM cost / runtime note for Phase D

The DAG-walk audit (`audit_dag_walk`) hits all schemas except DWH_dbo (already done). Plan estimates 6–10 hours of LLM time with `--judge-model claude-haiku-*` (3-5× faster than default). Use haiku if available — verify by running `claude --model claude-haiku-3-5 --help` or similar. Fall back to default if not available and warn the user about runtime up front.

## Acceptance criteria (when you're done)

1. `python tools/audit_tier1_claims.py --no-llm` on every audited scope returns 0 HIGH severity FAILs.
2. `python tools/audit_wiki_alter_comment_parity.py` (full repo) is clean.
3. `python tools/scan_uc_comment_gaps.py` shows no regressions for touched schemas.
4. `tools/render_audit_compare.py` rendered for every audit dir; visual spot-check 10 random PASS + 10 FAIL rows per schema in `compare.html`.
5. Every WRONG verdict in `knowledge/_dwh_llm_judge_cache/*.json` has a matching applied correction in `_tier1_truth_corrections.csv`.
6. The `Credit` chain (per `credit_chain_spotcheck.md`) is fully resolved end-to-end.

Final report back to user: total files edited per layer, total UC ALTERs deployed, how the `Credit` chain resolved, any conflict/silent-gap rows awaiting user review, per-phase commit SHAs.

## What's intentionally NOT in scope

- Rewriting §1 Business Meaning / §2 Business Logic narrative sections of corrupted wikis. The audit targets only §4 Elements column descriptions + tier tags. Flag fabricated narratives in `_tier1_truth_corrections.csv` with `narrative_review_needed=True`.
- Re-generating wikis from scratch. We patch.
- Auto-resolving `conflict_flag=TRUE` rows. Those go to `_tier1_corrections_manual_review.csv`.
- Native UC FUNCTIONs from `system.information_schema.routines`. Confirmed 1-2 trivial; out of scope. Synapse TVF-as-VIEW handled via `tvf_view_name_match` side task.
- Catalogs/schemas outside the synapse mirror without a matching synapse Functions wiki.

## Start command

After reading this file, read the plan file in full, then read `credit_chain_spotcheck.md` for the validation reference. Then create your TodoWrite list and begin with the `reconcile` todo.

---

*Last touched: 2026-05-21 by previous chat. Status: plan finalised (23 todos pending), tooling ready, audit baseline done, no cleanup code written yet.*
