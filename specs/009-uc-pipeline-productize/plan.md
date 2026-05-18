# Implementation Plan: UC-Pipeline DAG-First Productization

**Branch**: `009-uc-pipeline-productize` | **Date**: 2026-05-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/009-uc-pipeline-productize/spec.md`

## Summary

Scale the proven `uc-pipeline-doc` framework from the 3-object pilot to ~80-150 DAG-anchored UC objects across 5 named schemas (`de_output`, `bi_output`, `bi_dealing`, `etoro_kpi_prep`, `etoro_kpi`). Build the lineage DAG once per run, persist it locally, then process objects in topological order so every passthrough column inherits from an already-authored upstream wiki (Phase 3 Rules 1-5). Never AI-author when an upstream is reachable but undocumented; emit deterministic null-with-provenance only at terminal roots. Headless single-command entrypoint that runs from a Cursor agent loop or a Claude CLI loop with identical behavior.

## Technical Context

**Language/Version**: Python 3.11 (existing repo standard; `tools/uc_pipelines/` already uses Python 3.11)
**Primary Dependencies**: `databricks-sql-connector` (UC queries), `databricks-sdk` (Workspace API for source-code fetch), `sqlglot` (SQL parse for view DDL + notebook SQL), `pyyaml` (frontmatter), `requests` (auth fallback). All already in repo `requirements.txt` / pinned versions.
**Storage**: Filesystem only — JSON / Markdown artifacts under `knowledge/UC_generated/` (DAG, schema cards, per-object 4-file artifact sets, per-schema deploy indexes, per-run audit summaries). No new database. UC itself is read-only via existing `system.access.*` system tables; UC writes happen only through the existing `tools/deploy_alter_batch.py` runner.
**Testing**: `pytest` for tool-level unit tests (DAG topo-sort, no-inference validator, idempotency checks). Pilot regression: the existing 3-object pilot acts as an integration test — productized pipeline must produce equivalent artifacts byte-for-byte (modulo `generated_at`).
**Target Platform**: Windows PowerShell 5.1+ (developer machine; current target), and Linux/macOS bash (cloud agent / Claude CLI loop terminal). Python runtime is cross-platform; only shell-wrapper scripts have platform variants.
**Project Type**: Python CLI tools + Cursor rule files (markdown). Single-project layout.
**Performance Goals**: One full headless run across all 5 schemas completes in under 1 hour wall-clock for ~100 objects (SC-008). DAG-build phase issues exactly 1 query each to `system.access.column_lineage` and `system.access.table_lineage` (SC-005).
**Constraints**: UC comment 1024-char limit per Constitution Principle I. Phase 3 Routing Rules 1-5 are the only acceptable upstream-wiki sources (no new rules in this spec). No new auth surface beyond existing `DATABRICKS_TOKEN` / `DATABRICKS_MCP_PROFILE`. Re-runs must be idempotent (skip phases whose outputs exist; same input → same output bytes modulo `generated_at`).
**Scale/Scope**: ~80-150 in-scope UC objects across 5 schemas after DAG-anchoring filter. Each object produces 4 artifact files; estimated ~600 files generated per full run. Per-schema deploy index + per-run audit summary on top. Total disk footprint roughly 30-60 MB of generated content.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Justification |
|---|---|---|
| **I. Agent-First Knowledge** (ALTER script as ultimate deliverable; 1024-char limit) | PASS | Pack already emits `.alter.sql` per object via existing Phase 6 (`06-deploy.mdc`). FR-008 keeps the deploy-index format byte-compatible with existing `tools/deploy_alter_batch.py`. Comment-truncation logic from current `build_alter_from_wiki.py` carries over unchanged. |
| **II. Code Is King** (Tier 5 > 1 > 2 > 2b > 3 > 3b > 4 hierarchy; verbatim inheritance) | PASS | FR-005 mandates verbatim inheritance for passthrough columns; SC-003 makes this byte-for-byte verifiable. Phase 3 Routing Rules locate the upstream wiki; the column's existing tier tag is inherited unchanged (existing GATE-lineage-contract.mdc enforces this). |
| **III. Accuracy Over Coverage** (no fabrication; `[UNVERIFIED]` flag; sidecar) | PASS | FR-005 forbids any description that is not (a) verbatim inheritance, (b) source-code narration, or (c) null-with-provenance placeholder. FR-010 logs every gap to the per-object `.review-needed.md` sidecar AND the per-schema schema card. No silent gaps. |
| **IV. Incremental Delivery** | PASS | Three independently-testable user stories (P1 headless run, P1 honest gap reporting, P2 operator handoff). Each delivers value alone. |
| **V. Canonical Metadata Schema** | PASS | DAG node schema, deploy-index row schema, audit summary schema all defined in [data-model.md](./data-model.md). All four artifact-file shapes already canonicalized in `.cursor/rules/uc-pipeline-doc/GOLDEN-REFERENCE.mdc`. |
| **VI. Lineage Is First-Class** | PASS | Lineage DAG is the central architectural artifact (FR-003). `.lineage.md` per-object is a hard prerequisite to `.md` via existing GATE-lineage-contract.mdc. |
| **VII. Domain Boundaries** | PASS | Pack restricts itself to 5 named schemas (FR-001). Cross-pack interactions (uc-domain-doc, dwh-semantic-doc) happen only via the Phase 3 routing rules — never by direct dependency. |
| **VIII. Don't Rebuild What Exists** | PASS | Pack reuses: existing `uc-pipeline-doc` rule files (with 3 small additions documented in [research.md](./research.md)), existing `tools/uc_pipelines/` modules, existing `tools/deploy_alter_batch.py`, existing Phase 3 routing rules, existing GOLDEN-REFERENCE quality assertions. The headless runner is glue code. |
| **IX. Repo First, MCP Second** | PASS | UC queries restricted to `system.access.*` system tables, and only during DAG build (SC-005 = exactly 1 of each). View DDL fetched via `system.information_schema.views.view_definition` (one query at DAG-build time, alongside lineage). Notebook source code via Workspace API (`databricks-sdk`) — already justified at the existing `02-source-code-fetch.mdc` level (notebooks live in Databricks, not in this repo). |
| **X. Skill Artifacts Conform to eToro DE Schema** | N/A | This spec does not author any SKILL.md. If a follow-up wraps the runner in a Cursor skill, that follow-up spec inherits Principle X. |
| **XI. No Unsubstantiated Facts** (NON-NEGOTIABLE; codepoint-to-name verbatim) | PASS | FR-005 + new Assertion 13 in GOLDEN-REFERENCE mechanically enforce no-AI-inference. The pack does NOT produce codepoint-to-name claims itself — every codepoint-to-name claim it ships is inherited verbatim from upstream wikis (which themselves passed Principle XI on creation). The validator (FR-009) checks byte-for-byte equality for passthrough columns. |

**Constitution gate**: PASS. No violations. No complexity-tracking entries required.

## Project Structure

### Documentation (this feature)

```text
specs/009-uc-pipeline-productize/
├── plan.md              # This file
├── research.md          # Phase 0 — rationale + alternatives + 3 rule-file deltas
├── data-model.md        # Phase 1 — DAG schema, deploy-index schema, audit summary
├── quickstart.md        # Phase 1 — operator quick start (headless command line)
├── contracts/           # Phase 1 — machine-readable interface defs (no HTTP; this is CLI)
│   ├── cli.contract.md  # Headless entrypoint flags + exit codes
│   ├── dag.schema.json  # Lineage DAG JSON shape
│   └── deploy-index.schema.md  # Per-schema deploy-index Markdown shape
├── tasks.md             # Phase 2 (NOT created by /speckit.plan)
└── checklists/
    └── requirements.md  # Spec quality checklist (already exists from /speckit.specify)
```

### Source Code (repository root)

```text
.cursor/rules/uc-pipeline-doc/          # EXISTING — 3 small deltas + 1 new rule file in this spec
├── 00-execution-card.mdc                # unchanged
├── 00-schema-card.mdc                   # unchanged
├── 01-uc-discovery.mdc                  # unchanged
├── 02-source-code-fetch.mdc             # unchanged
├── 03-upstream-wiki-bridge.mdc          # DELTA: clarify terminal-root null-with-provenance behaviour (Rule 6 → option for downstream deferral when upstream is in-scope-but-not-yet-authored)
├── 04-column-lineage.mdc                # unchanged
├── 05-generate-doc.mdc                  # DELTA: add §No-Inference Contract subsection
├── 06-deploy.mdc                        # unchanged (existing comment-truncation logic stays)
├── 07-adversarial-evaluation.mdc        # NEW — adapts dwh-semantic-doc Phase 16 to UC; 6-dimension rubric (Inheritance Fidelity 35%, Source-Code Narration 25%, Null-with-Provenance Correctness 15%, Completeness 10%, Shape Fidelity 10%, Lineage Coherence 5%); ≥7.5 PASS, one regen retry max
├── GATE-lineage-contract.mdc            # unchanged
└── GOLDEN-REFERENCE.mdc                 # DELTA: add Assertion 13 (no-AI-inferred descriptions for un-anchored columns)

tools/uc_pipelines/                      # EXISTING — 4 new modules + 1 validator delta
├── _conn.py                             # unchanged
├── discover_schema.py                   # unchanged
├── fetch_writer_source.py               # unchanged
├── cache_upstream_wikis.py              # DELTA: add --write-cache flag for run-start cache build
├── build_lineage.py                     # unchanged
├── build_alter_from_wiki.py             # unchanged
├── build_deploy_index.py                # DELTA: emit Blocked rows + Blocked-by-upstream count
├── validate_pipeline_wiki.py            # DELTA: add --assert-no-inference mode (Assertion 13 enforcement)
├── build_dag.py                         # NEW — Phase -1, one-shot DAG builder; queries system.access.column_lineage + table_lineage once and persists knowledge/UC_generated/_dag.json
├── build_upstream_wiki_index.py         # NEW — Phase 0, scans existing wiki trees + emits _index_cache/upstream_wikis.json
├── generate_wiki.py                     # NEW — Phase 5 wiki authoring with DAG-aware verbatim inheritance + source-code narration + null-with-provenance
├── adversarial_evaluate.py              # NEW — Phase 7 evaluator; reads .md + cached upstream + source code; emits PASS/FAIL + regen feedback
├── write_audit_summary.py               # NEW — stitches per-schema worker results into one _runs/{ts}/summary.md
└── run_pipeline.py                      # NEW — coordinator + ProcessPoolExecutor fan-out; Wave 1 (de_output, bi_output, bi_dealing, etoro_kpi_prep) parallel, Wave 2 (etoro_kpi) sequential

knowledge/UC_generated/                   # EXISTING — generated artifacts root
├── _dag.json                            # NEW — single DAG for the run
├── _runs/                               # NEW — per-run audit summaries
│   └── 2026-05-17T19-00-00Z/
│       └── summary.md                   # FR-011 audit summary
├── de_output/                           # already piloted
├── bi_output/                           # new this run
├── bi_dealing/                          # new this run
├── etoro_kpi_prep/                      # partially piloted (3 wikis already authored)
└── etoro_kpi/                           # new this run
```

**Structure Decision**: Single-project layout. All new code lives under [tools/uc_pipelines/](tools/uc_pipelines/), all generated artifacts under [knowledge/UC_generated/](knowledge/UC_generated/), and the only rule-file deltas are the three documented above. No new Cursor skills, no new MCP servers, no new auth surfaces. The Cursor IDE and Claude CLI loops both invoke `python tools/uc_pipelines/run_pipeline.py --schemas ...` — identical entrypoint, identical artifacts.

## Phase 0: Outline & Research

See [research.md](./research.md). Resolves these design decisions:

- **R-1**: One-shot DAG schema (nodes / edges / per-node `wiki_status` enum) and the SQL that builds it.
- **R-2**: Topological-sort semantics when upstream is in-scope-but-not-yet-authored vs. terminal-no-wiki.
- **R-3**: No-inference enforcement mechanism — validator pass + byte-for-byte upstream diff for passthrough columns.
- **R-4**: Idempotency mechanism — per-phase output checkpoints; `--force` flag for explicit re-runs.
- **R-5**: Three rule-file deltas (exact text to add/modify in `03-upstream-wiki-bridge.mdc`, `05-generate-doc.mdc`, `GOLDEN-REFERENCE.mdc`).
- **R-6**: Audit-summary format and per-run directory naming convention.
- **R-7**: Cross-runtime parity (Cursor agent vs. Claude CLI loop) — confirms same Python entrypoint, same env vars, same exit codes.
- **R-8**: Schema-level parallelism — `ProcessPoolExecutor(max_workers=4)` Wave 1 (de_output, bi_output, bi_dealing, etoro_kpi_prep) then sequential Wave 2 (etoro_kpi depends on etoro_kpi_prep). UC query budget preserved by single-coordinator DAG build.
- **R-9**: Adversarial evaluator (Phase 7) — default-ON 6-dimension rubric pass per object; ≥7.5 PASS / <7.5 FAIL with one regeneration retry max; isolated cognitive pass (evaluator does not see generator reasoning).

## Phase 1: Design & Contracts

### Data model

See [data-model.md](./data-model.md). Defines:

- **DAG node** schema: `full_name`, `schema`, `table_type`, `upstreams[]`, `downstreams[]`, `wiki_status` (5 enum values), `routing_rule`, `cached_wiki_path`, `in_pilot_scope`, `topological_layer`, `source_code_available`.
- **DAG edge** schema: `from_node`, `to_node`, `column_lineage_rows` (count), `is_passthrough_only`, `event_count_90d`.
- **Per-run audit summary** schema: per-schema rollups + per-upstream blocked-counts + wall-clock breakdown.
- **Deploy-index row** schema (UNCHANGED from existing; documented here for completeness).

### Contracts

CLI-only — no HTTP, no RPC. Contracts under [contracts/](./contracts/):

- **`cli.contract.md`**: `run_pipeline.py` flags (`--schemas`, `--force`, `--phases`, `--dry-run`), exit codes (0 = all good, 1 = at least one object failed, 2 = run aborted at DAG build, 3 = auth failure), stdout shape (per-line phase progress + final summary table), required env vars.
- **`dag.schema.json`**: JSON Schema (Draft 2020-12) for `_dag.json`. Strict; deviations fail at DAG-build time.
- **`deploy-index.schema.md`**: Markdown structural contract (frontmatter fields, row statuses, header rollup) — byte-compatible with existing `tools/deploy_alter_batch.py` consumer.

### Quickstart

See [quickstart.md](./quickstart.md). 5-minute operator walkthrough:

1. `git checkout 009-uc-pipeline-productize`
2. `python tools/uc_pipelines/run_pipeline.py --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi`
3. Open `knowledge/UC_generated/_runs/<timestamp>/summary.md`, check counts.
4. For each schema with `Generated` rows, run `tools/deploy_alter_batch.py --deploy-index knowledge/UC_generated/<schema>/_deploy-index.md --schema <schema> --batch-size 5 --deploy-batch 1`.
5. Done.

### Agent context

The repo uses `.cursor/rules/` for agent context, not a centralized AGENTS.md. The three rule-file deltas in `.cursor/rules/uc-pipeline-doc/` ARE the agent-context update. No separate update-agent-context invocation needed.

## Post-Phase-1 Constitution Re-check

After Phase 1 design (data-model.md, contracts/, quickstart.md) re-evaluate the same 11 principles. Expected result: PASS — Phase 1 introduces no new external dependencies, no new auth surfaces, no new tier-hierarchy claims. The DAG-build query joins `system.access.column_lineage` to `system.information_schema.tables` to determine `table_type` — both UC-managed; consistent with Principle IX (UC is the source of truth FOR UC metadata; Repo First applies to Synapse/SSDT artifacts, not UC system tables).

## Complexity Tracking

No constitutional violations. No complexity entries.

## Stop & Report

This `/speckit.plan` invocation produces 5 artifacts under `specs/009-uc-pipeline-productize/`:

- `plan.md` (this file)
- `research.md`
- `data-model.md`
- `quickstart.md`
- `contracts/` (3 files)

Next command: `/speckit.tasks` to break the plan into ordered implementation tasks.
