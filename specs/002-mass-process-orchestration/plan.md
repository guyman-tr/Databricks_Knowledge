# Implementation Plan: Pipeline Decomposition — Wiki Build + Write Objects

**Branch**: `002-mass-process-orchestration` | **Date**: 2026-03-16 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-mass-process-orchestration/spec.md` + user pivot request to decompose the pipeline for throughput.

## Summary

The monolithic DWH documentation pipeline (14 phases + ALTER generation + downstream propagation + deployment per object, batch size 5, ~25 min/object) is decomposed into a wiki build command and a three-command deployment pipeline: **`build-wiki-dwh`** (wiki build, batch size 10-15, serial inline processing, Synapse+Atlassian only), **`generate-alter-dwh`** (ALTER script generation from wiki files, Databricks optional), and **`deploy-alter-dwh`** (ALTER execution against Unity Catalog, Databricks mandatory). Downstream propagation is deferred to a future **`propagate-downstream-dwh`** command. Combined with phase-skip optimization and the Simple Dictionary Fast-Path, this reduces per-object wiki time from ~25 min to ~5-10 min while achieving avg quality 8.0 across 130 DWH_dbo objects in 15 serial batches.

## Technical Context

**Language/Version**: Cursor rules (`.mdc`), Markdown commands (`.md`), Python helper scripts  
**Primary Dependencies**: Synapse MCP, Atlassian MCP, Databricks MCP, upstream wiki repos, Dataplatform repo  
**Storage**: Local filesystem (wiki files, tracking files, ALTER scripts); Unity Catalog (deployed metadata)  
**Testing**: End-to-end: run both commands on a 10-object subset and verify quality scores ≥ 7.0 and ALTER deployment succeeds  
**Target Platform**: Cursor IDE (agent-driven); future: headless Python orchestrator  
**Project Type**: Agent command pipeline (Cursor rules + commands)  
**Performance Goals**: 10-15 objects per wiki batch with serial inline processing; 25 per ALTER generation batch; 25 per deployment batch  
**Constraints**: Serial inline processing (one object at a time within each batch); one batch per session; context window ~200K tokens  
**Scale/Scope**: DWH_dbo: 130 objects documented (complete). Dealing_dbo: 231 objects (complete). BI_DB_dbo: 30/1204 objects (in progress). Expandable to additional schemas.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Agent-First Knowledge | ✅ PASS | ALTER script remains the ultimate deliverable — produced by `generate-alter-dwh` + `deploy-alter-dwh` from wiki content |
| II. Code Is King | ✅ PASS | Source hierarchy unchanged; all 14 analysis phases preserved in wiki build |
| III. Accuracy Over Coverage | ✅ PASS | Larger batches for simple objects, smaller for complex — prevents quality degradation |
| IV. Incremental Delivery | ✅ IMPROVED | Wiki and deployment are independently deliverable phases |
| V. Canonical Metadata Schema | ✅ PASS | Same output format for all files |
| VI. Lineage Is First-Class | ✅ PASS | `.lineage.md` produced during wiki build; `.lineage.py` during future uc-lineage-injection |
| VII. Domain Boundaries | ✅ PASS | Unchanged |
| VIII. Don't Rebuild What Exists | ✅ PASS | Staleness detection unchanged |
| IX. Repo First, MCP Second | ✅ ENFORCED | NEW principle — Dataplatform SSDT repo for all structural/code reads. MCP only Phases 2-3 |
| Quality Gates (v1.12.0) | ✅ PASS | Four mandatory files per object across pipeline — wiki + sidecar + lineage from build-wiki-dwh, ALTER from generate-alter-dwh |

**Gate result: PASS** — no violations.

**Post-Phase 1 re-check**: The decomposition introduces a temporal gap between wiki generation and ALTER deployment. This is acceptable because: (a) the ALTER script reads from the wiki file, so the content is always traceable, (b) the `_deploy-index.md` tracks staleness (wiki updated after last deploy), and (c) the constitution requires the ALTER script to exist, not that it be generated simultaneously.

## Project Structure

### Documentation (this feature)

```text
specs/002-mass-process-orchestration/
├── plan.md              # This file
├── research.md          # Phase 0: 10 research decisions (batch sizing, phase assignment, etc.)
├── data-model.md        # Phase 1: entity model (commands, indexes, phases, files)
├── quickstart.md        # Phase 1: operator guide for the new two-command workflow
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
.cursor/
├── commands/
│   ├── build-wiki-dwh.md                              # Wiki build command
│   ├── generate-alter-dwh.md                          # ALTER script generation (from wiki files)
│   ├── deploy-alter-dwh.md                            # ALTER execution against Unity Catalog
│   └── propagate-downstream-dwh.md                    # [FUTURE] Downstream column propagation
│
├── rules/
│   ├── dwh-semantic-doc/
│   │   ├── 01-structure-analysis.mdc                   # MODIFIED — repo-first (Constitution IX)
│   │   ├── 02-live-data-sampling.mdc                   # UNCHANGED
│   │   ├── 03-distribution-analysis.mdc                # UNCHANGED
│   │   ├── 04-lookup-resolution.mdc                    # UNCHANGED
│   │   ├── 05-join-analysis.mdc                        # UNCHANGED
│   │   ├── 06-business-logic-discovery.mdc             # UNCHANGED
│   │   ├── 07-view-dependency-scan.mdc                 # UNCHANGED
│   │   ├── 08-procedure-reference-scan.mdc             # UNCHANGED
│   │   ├── 09-procedure-logic-extraction.mdc           # UNCHANGED
│   │   ├── 09b-etl-orchestration-analysis.mdc          # UNCHANGED
│   │   ├── 10-atlassian-knowledge-scan.mdc             # UNCHANGED
│   │   ├── 11-generate-documentation.mdc               # MODIFIED — stripped to wiki + sidecar only
│   │   ├── 11w-write-objects.mdc                       # NEW — ALTER generation + deployment
│   │   ├── 12-cross-object-enrichment.mdc              # UNCHANGED
│   │   ├── 13-production-lineage-mapping.mdc           # MODIFIED — split: code lineage stays, UC queries move to 11w
│   │   ├── 14-query-advisory-metadata.mdc              # UNCHANGED
│   │   ├── 15-uc-lineage-injection.mdc                 # UNCHANGED (already offline)
│   │   ├── fk-lookup-reference.mdc                     # UNCHANGED
│   │   ├── 00-execution-card.mdc                        # Per-object flight checklist
│   │   ├── 10.5b-tier1-enforcement.mdc                  # Tier 1 upstream inheritance rules
│   │   ├── GATE-lineage-contract.mdc                    # Lineage-first execution order contract
│   │   ├── GATE-wiki-generation.mdc                     # Pre-flight + post-write validation gate
│   │   └── mcp-query-rules.mdc                         # UNCHANGED
│   │
│   └── semantic-layer-core/
│       ├── repo-first-access.mdc                       # NEW — Constitution IX enforcement (NON-NEGOTIABLE)
│       ├── batch-orchestration.mdc                     # MODIFIED — DEFAULT_BATCH_SIZE 5→15
│       ├── index-management.mdc                        # MINOR — remove ALTER-related status text
│       ├── context-handoff.mdc                         # UNCHANGED
│       └── deploy-index-management.mdc                 # NEW — _deploy-index.md protocol
│
knowledge/synapse/Wiki/DWH_dbo/
├── _index.md                                           # Wiki build tracking (existing, format preserved)
├── _deploy-index.md                                    # NEW — deployment tracking
├── _batch_context.json                                 # Cross-batch knowledge (existing, unchanged)
├── _dependency_order.json                              # Topological sort (existing, unchanged)
├── Tables/
│   ├── {Object}.md                                     # Wiki doc (build-wiki-dwh)
│   ├── {Object}.review-needed.md                       # Review sidecar (build-wiki-dwh)
│   ├── {Object}.lineage.md                             # Lineage mapping (build-wiki-dwh)
│   ├── {Object}.alter.sql                              # ALTER script (generate-alter-dwh)
│   ├── {Object}.downstream.alter.sql                   # Downstream ALTERs (future propagate-downstream-dwh)
│   ├── {Object}.deploy-report.md                       # Deploy report (deploy-alter-dwh)
│   └── {Object}.lineage.py                             # Lineage injection (future uc-lineage-injection)
└── Views/
    └── ...                                             # Same pattern

├── _batch_generate_lib.py                             # Python batch engine for ALTER generation
├── _deep_propagate_lib.py                             # Deep lineage propagation library

.cursor/scripts/
├── validate-wiki.ps1                                  # Structural validation (5 checks)
├── validate-wiki.sh                                   # Bash equivalent
├── validate-tier1-coverage.ps1                        # Semantic Tier 1 coverage validation
└── validate-tier1-coverage.sh                         # Bash equivalent
```

**Structure Decision**: No new directories. All files stay in the existing `Tables/` and `Views/` folders. Two new schema-level tracking files (`_deploy-index.md`, and eventually a new command pair) are the only additions to the schema folder.

---

## Detailed Design

### Task Group 1: Create `build-wiki-dwh` Command

**File**: `.cursor/commands/build-wiki-dwh.md`

This command replaces `build-semantic-layer-dwh` for documentation generation. It runs as a **single continuous flow** within one session: serial inline processing per object (no subagents), with phase-skip optimization and the Simple Dictionary Fast-Path where applicable.

#### Single Continuous Flow

**Execution model**: Plan + Execute run as a single uninterrupted flow within one session. The agent plans the batch, documents every object inline (serial, no subagents), updates tracking in bulk at the end, and prints a summary. No user input required between start and finish.

1. Load state: Read `_index.md` + `_batch_context.json`. Auto-generate `_index.md` if missing.
2. Plan batch: Select next 10-15 Pending objects (depth-ordered). Write `## Next Batch` to `_index.md`.
3. Execute serial: Process each object through the full phase pipeline (Phases 1-12, 14) inline.
4. Finalize: Bulk-update `_index.md`, write `_batch_context.json`, print end-of-batch banner.
5. Stop: Operator starts a new chat for the next batch.

**Phase-skip optimization**: Phases with no relevant input are skipped (zero grep hits for SP scan, no ID columns for lookup, MCP unavailable for live sampling). A **Simple Dictionary Fast-Path** (1→2→8→4→10A→10B→11) handles tables with ≤10 columns and single-source SP_Dictionaries origin.

#### Other Differences from Current Pipeline

1. **Pre-flight**: Synapse MCP advisory (live data only). Atlassian mandatory. No Databricks.
2. **Phase pipeline**: Phase 1 reads from Dataplatform SSDT repo (Constitution IX). Phases 2-3 query Synapse MCP (live data). Phases 4-10 use repo files + Atlassian MCP. Phase 11 slim (wiki + sidecar + lineage only). Phase 10A/10B (lineage — runs before Phase 11).
3. **Output**: 3 files per object (wiki + sidecar + lineage). No ALTER, no downstream, no deploy report.
4. **Batch size**: 10-15 (conservative, prevents context degradation on later objects).
5. **Verification gate**: 3 files, not 5.

### Task Group 2a: Create `generate-alter-dwh` Command

**File**: `.cursor/commands/generate-alter-dwh.md`

New command for ALTER script generation from existing wiki files. Does NOT execute against Databricks — file generation only.

1. **Pre-flight**: `_index.md` mandatory. Databricks MCP optional (resolves `_Pending` UC targets via bulk `information_schema` query).
2. **Per-object pipeline**: Parse wiki `.md` → resolve UC target → extract metadata → generate `.alter.sql` with table comment, column comments, tags, PII tags.
3. **Batch processing**: Default 25 objects. Bulk UC resolution query runs once per batch.
4. **Tracking**: Updates `_deploy-index.md` with `Generated` status.
5. **Batch engine**: `_batch_generate_lib.py` handles programmatic batch generation.

### Task Group 2b: Create `deploy-alter-dwh` Command

**File**: `.cursor/commands/deploy-alter-dwh.md`

New command for ALTER execution against Unity Catalog. Generates a temporary Python deployment script per batch to avoid browser-tab explosion from individual MCP calls.

1. **Pre-flight**: Databricks MCP mandatory. ALTER scripts must exist from `generate-alter-dwh`.
2. **Execution**: Single `databricks.sql.connect()` session per batch. Sequential statement execution with per-statement logging.
3. **Scope options**: Schema (all Generated), Single, Resume, Status, Dry-run.
4. **Output**: Updated `.alter.sql` (execution footer), `.deploy-report.md`.

### Task Group 2c: Create `propagate-downstream-dwh` Command (Future)

**File**: `.cursor/commands/propagate-downstream-dwh.md`

Placeholder for future downstream column description propagation. Not yet implemented.

### Task Group 3: Refactor Phase 11 to Wiki-Only

**File**: `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc`

Strip the following sections from Phase 11:
- "UC Object Resolution" section (moves to `11w-write-objects.mdc`)
- "UC Table Metadata Discovery" section (moves to `11w-write-objects.mdc`)
- "ALTER Script Template" and "ALTER Script Rules" (moves to `11w-write-objects.mdc`)
- "Table Tags" section (moves to `11w-write-objects.mdc`)
- "Column-Level PII Tags" section (moves to `11w-write-objects.mdc`)
- "Downstream Column Comment Propagation" section (moves to `11w-write-objects.mdc`)
- "ALTER Execution" section (moves to `11w-write-objects.mdc`)
- "Deployment Report" section (moves to `11w-write-objects.mdc`)

Preserve:
- Query-brain template (all 8 sections)
- Strict rules 1-18
- Review sidecar template
- Quality score calculation
- Batch processing quality enforcement (Rules B1-B7)
- Post-generation steps (update `_semantic_index.md`)

Modify:
- "Output Path" section: 3 files per object (wiki + sidecar + lineage), not 5
- Wiki template UC properties: placeholder values ("Pending — resolved during write-objects")
- Verification gate: check for 3 files, not 5
- Completion criteria: marked complete after wiki + sidecar + lineage written (no ALTER check)

### Task Group 4: Create Phase 11W Rule (Write Objects Logic)

**File**: `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc`

New rule file containing all ALTER/deployment logic extracted from Phase 11:

Sections:
1. **Wiki File Parsing Protocol**: How to read and extract from an existing wiki `.md` file
2. **UC Object Resolution**: Current Phase 11 resolution algorithm (unchanged)
3. **UC Table Metadata Discovery**: Current Phase 11 metadata queries (unchanged)
4. **Generic Pipeline Mapping**: Current Phase 10A Step 1/1b queries
5. **ALTER Script Generation**: Current Phase 11 ALTER template and rules
6. **Table Tags**: Current Phase 11 tag generation
7. **Column PII Tags**: Current Phase 11 PII detection
8. **Downstream Propagation**: Current Phase 11 deep lineage section
9. **Execution**: Current Phase 11 deployment script
10. **Deploy Report**: Current Phase 11 report template
11. **Wiki Backfill**: Optional step to update wiki `.md` with resolved UC properties

### Task Group 5: Update Batch Orchestration

**File**: `.cursor/rules/semantic-layer-core/batch-orchestration.mdc`

Changes:
- `DEFAULT_BATCH_SIZE`: 5 → 15
- Add batch sizing guidelines table in the configuration constants section
- Document that write-objects uses its own batch size (default 25) — not governed by this rule

### Task Group 6: Create Deploy Index Management

**File**: `.cursor/rules/semantic-layer-core/deploy-index-management.mdc`

New rule file for `_deploy-index.md` tracking:

Protocols:
1. **CREATE**: Scan `_index.md` for `Done` objects → create `_deploy-index.md` with all as `Pending`
2. **UPDATE**: After each object deploys → update status to `Deployed (Batch N)` or `Failed`
3. **STATUS DISPLAY**: Read-only progress summary
4. **STALE DETECTION**: Check if wiki `.md` was modified after `_deploy-index.md` last deploy timestamp

### Task Group 7: Deprecate Old Commands

- The original `build-semantic-layer-dwh.md` and `build-semantic-layer-dwh-no-propagation.md` commands were deleted during implementation (not deprecated with headers). No action needed — replacements are operational.

### Task Group 8: Update Spec, Constitution, and Rules

- Update `spec.md` to reference the two-command architecture (FR-013 added: repo-first access)
- Update `constitution.md`: add Principle IX (Repo First, MCP Second) as NON-NEGOTIABLE, update Quality Gates for four-file decomposed model — v1.6.0 → v1.8.0
- Create `.cursor/rules/semantic-layer-core/repo-first-access.mdc` — shared enforcement rule with full table, repo paths, and phase-by-phase source assignment
- Fix `01-structure-analysis.mdc`: remove incorrect "DDL Source is Synapse Metadata, NOT a Repo" header — replace with repo-first approach per Constitution IX

---

## Implementation Order

```
Task Group 3 (refactor Phase 11 to wiki-only)
    │
    ├── Task Group 4 (create Phase 11W)          ← can parallelize
    │
    ▼
Task Group 1 (build-wiki-dwh command)
    │
    ├── Task Group 5 (update batch orchestration) ← can parallelize
    │
    ▼
Task Group 6 (deploy-index-management)
    │
    ▼
Task Group 2a (generate-alter-dwh command)
Task Group 2b (deploy-alter-dwh command)        ← can parallelize with 2a
Task Group 2c (propagate-downstream-dwh)        ← placeholder, future
    │
    ▼
Task Group 8 (update spec — THIS SYNC)
```

**Critical path**: TG3 → TG1 → TG6 → TG2a/TG2b (can start testing wiki build before ALTER generation/deploy is ready)

---

## Risk Assessment

| Risk | Probability | Impact | Actual Outcome |
|------|------------|--------|----------------|
| Wiki quality drops with larger batches | Medium | High | **Mitigated**: Batch size reduced from 25 to 10-15. Quality avg 8.0 across 15 DWH_dbo batches (range 4.5-9.4). GATE enforcement + post-write validation catch degradation. |
| Phase 10B partial mode misses lineage data | Low | Medium | **Resolved**: Phase 10B moved before Phase 11 (GATE-lineage-contract). Lineage file is now mandatory input for doc generation. |
| Existing Batch 1 objects need re-processing | Low | Low | **Confirmed OK**: Wiki files valid. `generate-alter-dwh` deploys from them as-is. |
| Two-command workflow confuses operators | Low | Medium | **Evolved**: Now 3 commands (build-wiki, generate-alter, deploy-alter). Clear separation of concerns. Status commands on all three. |
| Deploy-index and index get out of sync | Medium | Medium | **Mitigated**: `_deploy-index.md` reads `_index.md` as source of truth. Stale detection works. |
| Parallel subagent quality | High | High | **Confirmed**: Abandoned. Serial inline with GATE enforcement achieves higher quality (avg 8.0 vs projected 6-7 for parallel). |

---

## Complexity Tracking

No constitution violations to justify.

| Aspect | Decision | Simpler Alternative Rejected Because |
|--------|----------|-------------------------------------|
| Three commands (plus future propagation) | Split wiki build from ALTER generation and deployment | One command couldn't scale past batch size 5 — too much per-object context |
| Two tracking files | `_index.md` + `_deploy-index.md` | Single file with two status columns is harder to parse and mixes concerns |
| New rule file `11w-write-objects.mdc` | Extract ALTER logic from Phase 11 | Keeping it in Phase 11 with conditional execution adds complexity and makes the rule file enormous |

---

## Success Criteria (Measurable)

| Criterion | Target | Actual | How Verified |
|-----------|--------|--------|-------------|
| Wiki batch size | ≥ 10 objects per batch | 10-15 (DWH_dbo avg ~9) | `_index.md` batch logs |
| Wiki quality | Avg ≥ 7.0 for first 3 batches | 8.0 avg across 15 batches | `_index.md` quality scores |
| Last-vs-first quality gap | ≤ 1.0 points | Within range | Batch log comparison |
| Per-object wiki time | ≤ 15 min for dim tables | ~5-10 min | Wall-clock observation |
| Deploy batch size | ≥ 25 objects per batch | 25 (default) | `_deploy-index.md` |
| ALTER execution success | ≥ 95% statements succeed | Achieved | Deploy reports |
| Full schema timeline | DWH_dbo complete | ✅ 130 objects, 15 batches | `_index.md` status |
| Backward compatibility | All existing docs valid | ✅ Batch 1 objects deployed | Deploy reports |
