---
description: Build wiki documentation for DWH Synapse objects. Single continuous flow — plan, execute, and finalize in one uninterrupted session.
---

# Build Wiki — DWH (Synapse)

**Spec Reference**: `/.specify/specs/003-synapse-knowledge/spec.md`
**Config Reference**: `/.specify/Configs/dwh-semantic-doc-config.json`

## Purpose

Generate wiki documentation for Synapse DWH objects in batches. The command produces **3 files per object**: wiki `.md`, review sidecar `.review-needed.md`, and lineage `.lineage.md`. ALTER scripts and UC deployment are handled separately by `write-objects-dwh`.

**Execution model**: One continuous flow. The agent plans the batch, documents every object inline (no subagents), updates tracking, and prints a summary — all without stopping for user input.

---

## 1. Command Overview & Arguments (T037)

### Invocation

```text
/build-wiki-dwh {schema_name} [single_object_name | status | enrich | review-rerun]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `schema_name` | Yes | Schema to document (e.g., `DWH_dbo`) |
| `single_object_name` | No | Single object (e.g., `Dim_ActionType`) — triggers single-object mode |
| `status` | No | Read-only progress display — no file modifications |
| `enrich` | No | Run Phase 12 cross-object enrichment on existing docs |
| `review-rerun` | No | Regenerate docs for objects with pending reviewer corrections |

### Scope Detection

- **Second argument is `status`** → Status mode (read-only)
- **Second argument is `enrich`** → Enrich mode (Phase 12 only)
- **Second argument is `review-rerun`** → Review-rerun mode (Phase 11 only)
- **Second argument is an object name** → Single-object mode
- **Second argument absent** → **Build mode** (plan + execute in one flow)

---

## 2. Pre-Flight Checks (T038)

Before any processing, verify prerequisites:

| Check | Source | Required | Constitution IX Note |
|-------|--------|----------|---------------------|
| Dataplatform SSDT repo | Local filesystem | **MANDATORY** | Primary source for DDLs, SP code, view definitions. Path: `Dataplatform\SynapseSQLPool1\sql_dp_prod_we\{Schema}\` |
| Upstream wiki repos | Local filesystem | Advisory | For Tier 1 column descriptions. Configured in `dwh-semantic-doc-config.json` |
| Synapse MCP | MCP connection | Advisory | **ONLY** for Phases 2-3 (live data sampling/distribution). Graceful degradation: skip phases if unavailable |
| Atlassian MCP | MCP connection | **Mandatory** | Phase 10 knowledge scan. **STOP** if unavailable |
| Databricks MCP | MCP connection OR static fallback | Advisory | Phase 10A uses the Generic Pipeline mapping to trace lineage. If MCP unavailable, falls back to static JSON at `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`. Graceful degradation either way |

### Check 1: Dataplatform SSDT Repo

Verify path exists and contains objects:
```
Dataplatform\SynapseSQLPool1\sql_dp_prod_we\{Schema}\Tables\*.sql
Dataplatform\SynapseSQLPool1\sql_dp_prod_we\{Schema}\Views\*.sql
```
- If missing → **STOP**: "Dataplatform SSDT repo not found. Clone the Dataplatform repo and set path in config."

### Check 2: Atlassian MCP

Run a test search. If it fails → **STOP**: "Atlassian MCP not working. Re-authorize and restart Cursor."

### Check 3: Synapse MCP (Advisory)

Run `SELECT 1 AS ConnectionTest`. If it fails → **WARN**: "Synapse MCP unavailable. Phases 2-3 (live data sampling, distribution analysis) will be skipped. Documentation will proceed from repo-only sources."

### Check 4: Dependency Graph

Verify `knowledge/synapse/Wiki/_dependency_order.json` exists. If missing → **STOP**: "Run `_build_dependency_order.py` first."

---

## 3. Build Mode — Unified Plan + Execute (T039–T048)

This is the default mode when only `schema_name` is provided. It runs as a **single uninterrupted flow**: discover objects → plan batch → execute batch → finalize tracking.

### Step 1: Load State

1. **Check for `_index.md`**:
   - If missing → create via `index-management.mdc` Protocol 1 (full object discovery + initial index generation)
   - If present → read it to identify Done/Failed/Skipped/Queued/Pending objects

2. **Load `_batch_context.json`** if present:
   - Extract glossary, object summaries, cross-references for use during documentation
   - If missing → warn and proceed without cross-batch knowledge

### Step 2: Plan the Next Batch

1. If objects are already `Queued` in `_index.md` (interrupted previous run):
   - Resume from the first `Queued` object in the interrupted batch
   - Skip re-planning — go directly to Step 3

2. If no `Queued` objects exist:
   - Re-scan `_dependency_order.json` and SSDT repo for new objects not in `_index.md`; add any new ones as `Pending`
   - Filter to `Pending` objects (exclude Done, Failed, Skipped)
   - Apply staleness detection: skip objects with wiki files modified within 30 days
   - Run batch segmentation per `batch-orchestration.mdc`: 15–25 objects, depth-ordered, dependency-consistent
   - Write batch plan to `_index.md`: mark objects as `Queued (Batch N, #M)`, write `## Next Batch` section
   - **DO NOT STOP** — flow directly into execution

### Step 3: Execute the Batch (Inline Serial)

Process each queued object **serially, in batch order**, using the inline pipeline. The agent performs all phases directly — no subagent dispatch, no user approvals.

**For each object in the batch:**

#### a. Resolve DDL Source

1. Glob for the DDL file in the SSDT repo:
   - `Dataplatform\SynapseSQLPool1\sql_dp_prod_we\{Schema}\Tables\{Schema}.{ObjectName}.sql`
   - `Dataplatform\SynapseSQLPool1\sql_dp_prod_we\{Schema}\External Tables\{Schema}.{ObjectName}.sql`
   - `Dataplatform\SynapseSQLPool1\sql_dp_prod_we\{Schema}\Views\{Schema}.{ObjectName}.sql`
2. If not found → mark as `Skipped (no DDL in SSDT)`, continue to next object
3. Read the DDL file → extract columns, types, nullability, distribution, indexing

#### b. Run Analysis Phases (Inline)

Run each applicable phase directly. Skip phases that have no relevant input — do not force all 14 phases on every object.

| Phase | Action | When to Skip |
|-------|--------|-------------|
| **Phase 1** (Structure) | Read DDL from SSDT repo. Extract columns, types, distribution, index. | Never — always required |
| **Phase 5** (JOIN Analysis) | Grep SSDT repo for JOINs referencing this object in SPs, views, functions. | Skip if zero grep hits |
| **Phase 8** (SP Scan) | Grep SSDT repo for SP references to this object. Read top SPs for ETL logic. | Skip if zero grep hits |
| **Phase 10** (Atlassian) | Search Jira/Confluence for business context about this object. | Never — always run |
| **Phases 2-3** (Live Data) | Sample data and analyze distributions via Synapse MCP. | Skip if MCP unavailable |
| **Phase 4** (Lookup Resolution) | Resolve ID columns using FK lookup reference and Dictionary tables. | Skip if no ID columns |
| **Phase 6** (Business Logic) | Analyze column groups, hierarchies, computed columns. | Skip if table has ≤5 simple columns |
| **Phase 7** (View Deps) | Trace view dependency chains. | Skip if object is a table with no view references |
| **Phase 9** (SP Logic) | Deep-read top SPs for column assignments and transformation logic. | Skip if Phase 8 found no SPs |
| **Phase 9B** (ETL Orchestration) | Map refresh schedules and SP execution order. | Skip if no orchestration SPs found |
| **Phase 10A** (Production source & upstream wiki) | Query Generic Pipeline mapping (MCP or static fallback) to find production source table. Then **read upstream wiki from DB_Schema** and extract Tier 1 column descriptions for inheritance. This is what enables Tier 1 columns in the output. | Never — always run. If MCP fails, use static JSON fallback. If no mapping found, note in lineage file and proceed. |
| **Phase 10B** (Column lineage) | Resolve column-level lineage (production ↔ DWH) for the `.lineage.md` content produced in Phase 11. | Never — always run. If mapping is incomplete, document gaps in the lineage file and proceed. |

**Minimum required phases for every object**: Phase 1, Phase 10A, Phase 10B, Phase 10, Phase 11.

> **CRITICAL — Phase 10A/10B before Phase 11**: Phase 10A and Phase 10B MUST run before Phase 11 so that upstream wiki column descriptions and lineage context are available as Tier 1 sources during documentation generation. Without Phase 10A, every column defaults to Tier 3-4 and zero Tier 1 columns appear in the output.

#### c. Generate Documentation (Phase 11)

Follow `11-generate-documentation.mdc` EXACTLY. Write **3 files**:
1. `knowledge/synapse/Wiki/{Schema}/{TypeFolder}/{ObjectName}.md` — wiki doc
2. `knowledge/synapse/Wiki/{Schema}/{TypeFolder}/{ObjectName}.review-needed.md` — review sidecar
3. `knowledge/synapse/Wiki/{Schema}/{TypeFolder}/{ObjectName}.lineage.md` — lineage map

All 8 section headers required. Individual element descriptions with confidence tiers. Quality score in footer.

**Tier 1 column inheritance** (from Phase 10A results): For each column that Phase 10A mapped to a production source table with an upstream wiki, **read the upstream wiki file** and copy the column description verbatim as Tier 1. The upstream wiki path format: `DB_Schema/etoro/Wiki/{Schema}/Tables/{Schema}.{TableName}.md`. If the column exists in the upstream wiki's Elements table, its description is Tier 1 — do NOT paraphrase or rewrite it. Only append DWH-specific notes prefixed with "DWH note:". This is the single most important step for documentation quality.

#### d. Track Result (In Memory)

Record `{object, status (Done/Failed/Skipped), quality_score, reason}` in a running list. **Do NOT update `_index.md` after every object** — batch-level update happens in Step 4.

### Step 4: Finalize Batch

After all objects in the batch are processed:

1. **Update `_index.md`** in one bulk operation:
   - Change status of all processed objects: `Queued → Done/Failed/Skipped`
   - Add quality scores and wiki file links for Done objects
   - Move batch from `## Next Batch` to `## Completed Batches`
   - Update frontmatter counters (documented, failed, last_batch, quality_avg)
   - Set `## Next Batch` to "Batch N+1 will be planned on next run."

2. **Write `_batch_context.json`**:
   - Collect glossary terms, relationship summaries, cross-references from all documented objects
   - Merge with existing context per `context-handoff.mdc` Protocol 3

3. **Print end-of-batch banner**:

```
╔══════════════════════════════════════════════════════════════════╗
║  BATCH {N} COMPLETE — {Schema}                                  ║
║                                                                 ║
║  Objects:  {processed} processed, {failed} failed               ║
║  Quality:  avg {avg} (range {min} – {max})                     ║
║  Progress: {total_done}/{total_objects} ({pct}%)               ║
║  Next:     Batch {N+1} ({next_count} objects remaining)        ║
║                                                                 ║
║  Run /build-wiki-dwh {Schema} again for the next batch.        ║
╚══════════════════════════════════════════════════════════════════╝
```

If all objects are documented, print schema-complete banner (see `batch-orchestration.mdc`).

---

## 4. Single-Object Mode (T049)

When second argument is an object name (e.g., `Dim_ActionType`):

1. **Bypass** batch planning
2. **Document one object** using the inline pipeline (Step 3a–3c above)
3. **Output**: 3 files — wiki `.md`, `.review-needed.md`, `.lineage.md`
4. **Update `_index.md`** with result (Done/Failed)
5. **No batch context write** — single object does not warrant it

---

## 5. Status Mode (T050)

When argument is `status`:

1. Read `_index.md` via `index-management.mdc` Protocol 3 (STATUS DISPLAY)
2. Display: objects done/pending/failed, next batch plan, quality distribution
3. **No file modifications**

---

## 6. Enrich Mode (T051)

When argument is `enrich`:

1. Run **Phase 12** cross-object enrichment on all existing docs
2. Read all wiki files in the schema
3. Update "Referenced By" sections with full cross-reference graph
4. Reconcile glossary usage
5. **Does NOT** re-document objects (Phases 1–11 not run)

---

## 7. Review-Rerun Mode (T052)

When argument is `review-rerun`:

1. Find objects with pending reviewer corrections in `.review-needed.md` (non-empty `## Reviewer Corrections` without `[RESOLVED]`)
2. **Re-run Phase 11 only** — apply Tier 5 corrections
3. Phases 1–10 are **not** re-run
4. Update wiki `.md`, sidecar `.review-needed.md`, lineage `.lineage.md`

---

## 8. Rule File References (T053)

### Phase Rules (in order)

```
.cursor/rules/dwh-semantic-doc/01-structure-analysis.mdc
.cursor/rules/dwh-semantic-doc/02-live-data-sampling.mdc
.cursor/rules/dwh-semantic-doc/03-distribution-analysis.mdc
.cursor/rules/dwh-semantic-doc/04-lookup-resolution.mdc
.cursor/rules/dwh-semantic-doc/05-join-analysis.mdc
.cursor/rules/dwh-semantic-doc/06-business-logic-discovery.mdc
.cursor/rules/dwh-semantic-doc/07-view-dependency-scan.mdc
.cursor/rules/dwh-semantic-doc/08-procedure-reference-scan.mdc
.cursor/rules/dwh-semantic-doc/09-procedure-logic-extraction.mdc
.cursor/rules/dwh-semantic-doc/09b-etl-orchestration-analysis.mdc
.cursor/rules/dwh-semantic-doc/10-atlassian-knowledge-scan.mdc
.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc   (wiki-only slim variant)
.cursor/rules/dwh-semantic-doc/12-cross-object-enrichment.mdc
.cursor/rules/dwh-semantic-doc/13-production-lineage-mapping.mdc  (Phases 10A and 10B — production mapping, upstream wiki, and column lineage)
.cursor/rules/dwh-semantic-doc/14-query-advisory-metadata.mdc
```

### Shared Rules

```
.cursor/rules/semantic-layer-core/repo-first-access.mdc
.cursor/rules/semantic-layer-core/batch-orchestration.mdc
.cursor/rules/semantic-layer-core/index-management.mdc
.cursor/rules/semantic-layer-core/context-handoff.mdc
.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc
.cursor/rules/dwh-semantic-doc/fk-lookup-reference.mdc
```

---

## Repository Structure

| Path | Purpose |
|------|---------|
| `knowledge/synapse/Wiki/{Schema}/Tables/` | Table wiki output |
| `knowledge/synapse/Wiki/{Schema}/Views/` | View wiki output |
| `knowledge/synapse/Wiki/{Schema}/Functions/` | Function wiki output |
| `knowledge/synapse/Wiki/{Schema}/_index.md` | Batch tracking |
| `knowledge/synapse/Wiki/{Schema}/_batch_context.json` | Cross-batch context |
| `knowledge/synapse/Wiki/_dependency_order.json` | Dependency graph |
| `Dataplatform\SynapseSQLPool1\sql_dp_prod_we\{Schema}\` | SSDT repo (Tables, External Tables, Views, Functions, SPs) |

---

## Wiki ↔ ALTER comment parity (Cursor + repo — not Claude-only)

Whenever a sibling **`{ObjectName}.alter.sql`** exists (from `/generate-alter-dwh` or manual creation), **column `COMMENT` text must match** the wiki **## 4. Elements** descriptions using the same encoding as `merge_wiki_column_comments_into_alter.py` / `sql_string_for_comment`.

| Scope | Command / script |
|-------|------------------|
| **Single wiki** | `python tools/audit_wiki_alter_comment_parity.py path/to/Object.md` |
| **Schema** | `python tools/audit_wiki_alter_comment_parity.py --under {schema_name}` |
| **Validate wiki (includes parity if `.alter.sql` exists)** | `.cursor/scripts/validate-wiki.ps1 -Path path\to\Object.md` |
| **Last run status (batch loop / operator)** | `knowledge/synapse/Wiki/{Schema}/_parity_gate_last_run.txt` and optional `_parity_last_report.json` on FAIL |

See `.cursor/rules/dwh-semantic-doc/00-execution-card.mdc` (THREE VALIDATIONS + batch parity) and `.cursor/rules/semantic-layer-core/batch-orchestration.mdc` (parity subsection).

---

## Error Recovery

| Issue | Solution |
|-------|----------|
| Synapse MCP timeout | Skip Phases 2–3, proceed with repo-only; note in doc |
| Databricks MCP unavailable | Phase 10A falls back to static JSON at `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`; no action needed |
| Atlassian MCP error | **STOP** — Phase 10 required |
| Dataplatform repo missing | **STOP** — clone repo |
| DDL file not found | Mark object as `Skipped (no DDL in SSDT)`, continue to next object |
| Mid-batch crash | Run `/build-wiki-dwh {Schema}` again — resumes from first Queued object |
| Phase failure on one object | Mark as `Failed`, continue to next object in batch |
