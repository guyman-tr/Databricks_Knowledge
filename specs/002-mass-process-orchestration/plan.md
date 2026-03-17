# Implementation Plan: Pipeline Decomposition — Wiki Build + Write Objects

**Branch**: `002-mass-process-orchestration` | **Date**: 2026-03-16 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-mass-process-orchestration/spec.md` + user pivot request to decompose the pipeline for throughput.

## Summary

The monolithic DWH documentation pipeline (14 phases + ALTER generation + deployment per object, batch size 5, ~25 min/object) is decomposed into two independent commands: **`build-wiki-dwh`** (fast wiki build, batch size 25, **parallel subagents for independent objects**, Synapse+Atlassian only) and **`write-objects-dwh`** (ALTER generation + UC deployment, parallel, Databricks only). Combined with Bonnie's Plan/Execute two-session model and depth-level parallelism, this reduces estimated full-schema coverage from ~3-4 weeks to **~2-3 days** while preserving quality via Rules B1-B7.

## Technical Context

**Language/Version**: Cursor rules (`.mdc`), Markdown commands (`.md`), Python helper scripts  
**Primary Dependencies**: Synapse MCP, Atlassian MCP, Databricks MCP, upstream wiki repos, Dataplatform repo  
**Storage**: Local filesystem (wiki files, tracking files, ALTER scripts); Unity Catalog (deployed metadata)  
**Testing**: End-to-end: run both commands on a 10-object subset and verify quality scores ≥ 7.0 and ALTER deployment succeeds  
**Target Platform**: Cursor IDE (agent-driven); future: headless Python orchestrator  
**Project Type**: Agent command pipeline (Cursor rules + commands)  
**Performance Goals**: 25 objects per wiki batch with parallel subagents (10x improvement over current); 25-50 per deployment batch  
**Constraints**: Max 4 concurrent subagents; 3 tables/subagent (Rule B1); serial across depth levels, parallel within; context window ~200K tokens  
**Scale/Scope**: 281 objects in DWH_dbo schema (259 tables, 22 views); expandable to 5+ schemas

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Agent-First Knowledge | ✅ PASS | ALTER script remains the ultimate deliverable — produced by `write-objects-dwh` from wiki content |
| II. Code Is King | ✅ PASS | Source hierarchy unchanged; all 14 analysis phases preserved in wiki build |
| III. Accuracy Over Coverage | ✅ PASS | Larger batches for simple objects, smaller for complex — prevents quality degradation |
| IV. Incremental Delivery | ✅ IMPROVED | Wiki and deployment are independently deliverable phases |
| V. Canonical Metadata Schema | ✅ PASS | Same output format for all files |
| VI. Lineage Is First-Class | ✅ PASS | `.lineage.md` produced during wiki build; `.lineage.py` during write-objects |
| VII. Domain Boundaries | ✅ PASS | Unchanged |
| VIII. Don't Rebuild What Exists | ✅ PASS | Staleness detection unchanged |
| IX. Repo First, MCP Second | ✅ ENFORCED | NEW principle — Dataplatform SSDT repo for all structural/code reads. MCP only Phases 2-3 |
| Quality Gates (v1.8.0) | ✅ PASS | Four mandatory files per object across pipeline — wiki + sidecar + lineage from build, ALTER from write-objects |

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
│   ├── build-wiki-dwh.md                              # NEW — wiki build command
│   ├── write-objects-dwh.md                            # NEW — deployment command
│   ├── build-semantic-layer-dwh.md                     # DEPRECATED — replaced by build-wiki-dwh
│   └── build-semantic-layer-dwh-no-propagation.md      # DEPRECATED — redundant
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
│   ├── {Object}.alter.sql                              # ALTER script (write-objects-dwh)
│   ├── {Object}.downstream.alter.sql                   # Downstream ALTERs (write-objects-dwh)
│   ├── {Object}.deploy-report.md                       # Deploy report (write-objects-dwh)
│   └── {Object}.lineage.py                             # Lineage injection (write-objects-dwh)
└── Views/
    └── ...                                             # Same pattern
```

**Structure Decision**: No new directories. All files stay in the existing `Tables/` and `Views/` folders. Two new schema-level tracking files (`_deploy-index.md`, and eventually a new command pair) are the only additions to the schema folder.

---

## Detailed Design

### Task Group 1: Create `build-wiki-dwh` Command

**File**: `.cursor/commands/build-wiki-dwh.md`

This command replaces `build-semantic-layer-dwh` for documentation generation. It adopts the **Plan/Execute two-session model** from DB_Schema (Bonnie's architecture) and adds **parallel subagent dispatch for independent objects**.

#### Two-Session Architecture (from DB_Schema)

**Plan mode** (auto-detected when no `## Next Batch` in `_index.md`):
1. Pre-flight: Synapse MCP advisory (only needed for Phases 2-3 live data — structure comes from repo). Atlassian MCP mandatory. Databricks SKIPPED.
2. Read `_dependency_order.json`, scan for pending objects
3. Select next 25 objects (depth-ordered, self-consistent slice)
4. Write `## Next Batch` section to `_index.md`
5. **STOP** — print plan summary, instruct operator to start new chat

**Execute mode** (auto-detected when `## Next Batch` exists):
1. Read queued objects from `_index.md`
2. Group by depth level
3. **For each depth level**: dispatch parallel subagents
4. Validate output, update tracking
5. Write `_batch_context.json`
6. Print end-of-batch banner

Operator workflow: run the same command every time, it alternates Plan/Execute automatically.

#### Parallel Subagent Dispatch

Within each depth level, objects are independent (by definition of topological depth). The parent agent dispatches up to **4 concurrent subagents**, each documenting **3 tables** (Rule B1) or **5 views**:

```
Depth 0: [Dim_ActionType, Dim_CardType, Dim_ContractType] → Subagent 1
          [Dim_Date, Dim_MoveMoneyReason, Ext_Dim_Country] → Subagent 2
          [Ext_Dim_Country_Region_Desk, Ext_PhoneVerif, DWH_Status] → Subagent 3
          [DataSolutionsTablesRunInd, Dim_AccountStatus, Dim_AccountType] → Subagent 4
          
          Wait for all 4 → validate (Rule B7) → update _index.md → next round
```

Each subagent receives:
- Object names to document
- Full phase pipeline instructions (Phases 1-11 slim)
- Repo paths for DDL files (Dataplatform SSDT — Constitution IX)
- MCP access: Synapse (Phases 2-3 live data only) + Atlassian (Phase 10)
- Glossary from `_batch_context.json`
- References to existing dependency wiki files (already on disk)

**Quality enforcement**: Rules B1-B7 apply per subagent. Parent spot-checks 1 random doc per subagent (Rule B7). Failed checks → re-dispatch serially.

**Serial fallback**: Objects with cross-depth dependencies within the same batch, or objects that fail quality checks, are re-run serially by the parent agent.

#### Other Differences from Current Pipeline

1. **Pre-flight**: Synapse MCP advisory (live data only). Atlassian mandatory. No Databricks.
2. **Phase pipeline**: Phase 1 reads from Dataplatform SSDT repo (Constitution IX). Phases 2-3 query Synapse MCP (live data). Phases 4-10 use repo files + Atlassian MCP. Phase 11 slim (wiki + sidecar + lineage only). Phase 13 partial (code lineage only, no UC queries).
3. **Output**: 3 files per object (wiki + sidecar + lineage). No ALTER, no downstream, no deploy report.
4. **Batch size**: 25 (same as DB_Schema).
5. **Verification gate**: 3 files, not 5.

### Task Group 2: Create `write-objects-dwh` Command

**File**: `.cursor/commands/write-objects-dwh.md`

New command for ALTER generation and UC deployment. Structure:

1. **Pre-flight**: Databricks MCP mandatory. Synapse MCP optional (needed for PII GDPR queries — graceful degradation to column-name patterns if unavailable). Atlassian not needed.

2. **Scope options**:
   - **Schema**: Deploy all objects with wiki status `Done` in `_index.md`
   - **Resume**: Continue from last deployment batch
   - **Status**: Show deployment progress from `_deploy-index.md`
   - **Single**: Deploy one object
   - **Re-deploy**: Re-deploy objects whose wiki was updated after last deploy

3. **Per-object pipeline** (loaded from `11w-write-objects.mdc`):
   - Read and parse wiki `.md` file (Elements table, Business Meaning, Lineage)
   - UC Object Resolution (current Phase 11 algorithm)
   - UC Table Metadata Discovery (DESCRIBE DETAIL + EXTENDED)
   - Generic Pipeline mapping query (Phase 13 Step 1/1b)
   - ALTER script generation (table comment + column comments)
   - Tag generation (domain, object_type, source_schema, refresh_frequency, sla, etc.)
   - PII tag generation (GDPR tables + column patterns)
   - Downstream propagation (deep lineage via `_deep_propagate_lib.py`)
   - ALTER execution (single-session Python script)
   - Deploy report generation
   - Optional: backfill UC properties into wiki `.md`

4. **Batch size**: Default 25. Each object is much lighter — read wiki + generate SQL + execute.

5. **Tracking**: Manages `_deploy-index.md` via `deploy-index-management.mdc`.

6. **Dependency ordering**: Uses `_dependency_order.json` for bottom-up processing (upstream objects deployed before their downstream consumers).

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
4. **Generic Pipeline Mapping**: Current Phase 13 Step 1/1b queries
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

- Move `build-semantic-layer-dwh.md` to a `deprecated/` subfolder or add a `DEPRECATED` header pointing to the two new commands
- Remove `build-semantic-layer-dwh-no-propagation.md` (redundant — wiki build IS no-propagation)

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
Task Group 2 (write-objects-dwh command)
    │
    ▼
Task Group 7 (deprecate old commands)
    │
    ▼
Task Group 8 (update spec)
```

**Critical path**: TG3 → TG1 → TG6 → TG2 (can start testing wiki build before write-objects is ready)

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Wiki quality drops with larger batches | Medium | High | Start with batch of 10, measure quality, increase gradually. Quality thresholds from Rules B1-B7 catch degradation |
| Phase 13 partial mode misses important lineage data | Low | Medium | SP code analysis captures most lineage. UC mapping view data is supplementary and gets added during write-objects |
| Existing Batch 1 objects need re-processing | Low | Low | They don't — wiki files exist and are valid. Write-objects can deploy from them as-is |
| Two-command workflow confuses operators | Low | Medium | Clear quickstart guide. Status commands on both show what's done/pending |
| Deploy-index and index get out of sync | Medium | Medium | Deploy-index always reads index as source of truth. No write-objects without matching Done in index |

---

## Complexity Tracking

No constitution violations to justify.

| Aspect | Decision | Simpler Alternative Rejected Because |
|--------|----------|-------------------------------------|
| Two commands instead of one | Split wiki build from deployment | One command couldn't scale past batch size 5 — too much per-object context |
| Two tracking files | `_index.md` + `_deploy-index.md` | Single file with two status columns is harder to parse and mixes concerns |
| New rule file `11w-write-objects.mdc` | Extract ALTER logic from Phase 11 | Keeping it in Phase 11 with conditional execution adds complexity and makes the rule file enormous |

---

## Success Criteria (Measurable)

| Criterion | Target | How to Verify |
|-----------|--------|---------------|
| Wiki batch size | ≥ 15 objects per batch | Run `/build-wiki-dwh DWH_dbo` — verify batch plan shows 15+ objects |
| Wiki quality | Avg ≥ 7.0 for first 3 batches | Check quality scores in `_index.md` after 3 batches |
| Last-vs-first quality gap | ≤ 0.5 points | Compare quality of object #1 vs #15 in same batch |
| Per-object wiki time | ≤ 10 min for dim tables | Measure wall-clock time per object in batch |
| Deploy batch size | ≥ 25 objects per batch | Run `/write-objects-dwh DWH_dbo` — verify batch plan |
| ALTER execution success | ≥ 95% statements succeed | Check deploy report |
| Full schema timeline | ≤ 5 days | Track from first batch to full deployment |
| Backward compatibility | All 8 existing docs valid | Run `/write-objects-dwh` on Batch 1 objects without re-building wiki |
