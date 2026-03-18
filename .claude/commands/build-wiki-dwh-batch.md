---
description: Batch command for DWH schema-wide semantic wiki documentation. Each session plans one batch, documents all objects inline (serial, no subagents), and stops. The external loop script starts a new session for the next batch.
---

# DWH Wiki Documentation - Batch Session

**Phase Rule Files**: `/.cursor/rules/dwh-semantic-doc/*.mdc`
**Core Orchestration Rules**: `/.cursor/rules/semantic-layer-core/*.mdc`

## Purpose

This command is the **batch orchestrator** for DWH schema-wide semantic documentation, adapted for **Claude Code** terminal sessions. It uses a **single-session architecture**: each session plans the next batch AND documents it inline, then stops. The external loop script (`run-dwh-wiki-batch-loop.ps1`/`.sh`) handles session cycling.

**Your workflow**: Same command every time. Each session:
1. Loads state from `_index.md` and `_batch_context.json`
2. Identifies the next batch of undocumented objects (from `_dependency_order.json`)
3. Documents each object SERIALLY in-agent through the full phase pipeline
4. Bulk-updates `_index.md`, writes context handoff, prints banner
5. HARD STOP - the loop script starts a fresh session for the next batch

## User Input

```text
$ARGUMENTS
```

### Input Detection

The user provides the schema name. For the DWH pipeline, this is typically `DWH_dbo`.

| Input Format | Example | How to Parse |
|-------------|---------|-------------|
| **Schema name** | `DWH_dbo` | Schema = `DWH_dbo` |
| **Empty** | (none) | Default to `DWH_dbo` |

Wiki output path: `knowledge/synapse/Wiki/{Schema}/`
SSDT repo path: `../DataPlatform/SynapseSQLPool1/sql_dp_prod_we/{Schema}/`
Dependency graph: `knowledge/synapse/Wiki/_dependency_order.json`

---

## CRITICAL: The REPO is the Single Source of Truth

**The Dataplatform SSDT repo is the ABSOLUTE TRUTH for all structural information.**

| Task | Source | NEVER Use |
|------|--------|-----------|
| Discover objects in a schema | **Glob** on SSDT + `_dependency_order.json` | ~~MCP query to sys.tables/sys.objects~~ |
| Read object DDL (columns, types) | **Read tool** on the `.sql` file from SSDT | ~~MCP query to INFORMATION_SCHEMA~~ |
| Find dependencies between objects | **Parse** the `.sql` file + `_dependency_order.json` | ~~MCP query to sys.dependencies~~ |
| Read procedure/function code | **Read tool** on the `.sql` file from SSDT | ~~MCP query to sp_helptext~~ |

**MCP (Synapse) is ONLY for live data queries during Phase execution (Phases 2, 3, 6): SELECT TOP N, COUNT(*), GROUP BY, MIN/MAX.**

---

## CRITICAL: Encoding Rule

Use ONLY plain ASCII characters in ALL generated files:
- Use `-` (hyphen) NOT em/en dashes
- Use `*` NOT bullet symbols
- Use `->` NOT `-->`
- Em dashes cause `a]!` corruption in some editors.

---

## Step 0: Load Core Rules (MANDATORY - First Action Every Session)

**Before anything else, read these rule files using the Read tool:**

1. `.cursor/rules/semantic-layer-core/batch-orchestration.mdc` - batch planning, sizing, execution flow
2. `.cursor/rules/semantic-layer-core/index-management.mdc` - `_index.md` tracking protocol
3. `.cursor/rules/semantic-layer-core/context-handoff.mdc` - `_batch_context.json` cross-batch knowledge
4. `.cursor/rules/semantic-layer-core/repo-first-access.mdc` - repo-first data access rules
5. `.cursor/rules/dwh-semantic-doc/00-execution-card.mdc` - per-object flight checklist (KEEP LOADED)

**These five rules govern the entire session. Read them NOW before proceeding.**

---

## Step 1: Pre-Flight MCP Connection Check (MANDATORY)

**Both MCP connections MUST be verified before any work.**

### Check 1: Synapse MCP

Run a trivial query via Synapse MCP:
```sql
SELECT 1 AS ConnectionTest
```
- Returns `1` -> PASS
- Any failure -> **STOP IMMEDIATELY**:
> **BLOCKED: Synapse MCP is not connected.** Please check your MCP configuration.

### Check 2: Atlassian MCP

Search for a trivial term:
- Returns results (even empty) -> PASS
- Any error -> **WARN** (Phase 10 will be skipped but other phases proceed):
> **WARNING: Atlassian MCP is not working.** Phase 10 (Jira/Confluence scan) will be skipped.

**Synapse MUST pass. Atlassian failure is a warning, not a blocker.**

---

## Step 2: Load State and Detect What To Do

### 2a: Read `_index.md`

Look for: `knowledge/synapse/Wiki/{Schema}/_index.md`

**If it does NOT exist**: Cold start. Read `index-management.mdc` Protocol 1 and create it using Object Discovery from `batch-orchestration.mdc`.

**If it exists**: Parse it to determine documented/pending/queued objects.

### 2b: Load Context Handoff

Read `knowledge/synapse/Wiki/{Schema}/_batch_context.json` if it exists. Apply glossary and cross-references per Protocol 2 in `context-handoff.mdc`.

### 2c: Determine Batch

Follow the **Batch Segmentation Algorithm** from `batch-orchestration.mdc`:
1. Load `_dependency_order.json` + scan SSDT for missing objects
2. Exclude `Done`/`Skipped` objects
3. Group by depth, sort within depth, segment into batches of `DEFAULT_BATCH_SIZE` (10)
4. Identify the NEXT batch (first group of `Pending` objects)

If a batch was interrupted (some objects `Queued` in `_index.md`), resume from the first `Queued` object.

### 2d: Print Session Plan

```
===============================================================
 DWH WIKI BUILD - Batch {N}
 Schema: {Schema} | Date: {today}
===============================================================

 Total objects in schema: {N}
 Already documented:      {N} ({pct}%)
 Failed:                  {N}
 Queued for this batch:   {N} objects

 Batch Objects:
 ---------------------------------------------------------------
  #  | Object                          | Type     | Depth | Dependencies
 ----|--------------------------------|----------|-------|-------------
   1 | DWH_dbo.Dim_Instrument          | Table    |  0    | (leaf)
   2 | DWH_dbo.Dim_Currency            | Table    |  0    | (leaf)
   3 | DWH_dbo.Dim_Position            | Table    |  2    | -> #1, #2
  ...
 ---------------------------------------------------------------

 Starting execution...
===============================================================
```

**Start immediately - no user confirmation needed.**

---

## Step 3: Execute - Document Each Object (Serial, Full Quality)

**Process objects ONE AT A TIME in the exact order from the batch. SERIAL ONLY - NO PARALLEL SUBAGENTS.**

### CRITICAL: NO PARALLEL SUBAGENTS

This is the single most important rule. Each object gets the full phase pipeline in the SAME agent context. Context from earlier objects enriches later ones.

### Session Quality Contract

| Rule | Value |
|------|-------|
| **Max objects per session** | 10 (DEFAULT_BATCH_SIZE from batch-orchestration.mdc) |
| **Minimum quality per object** | 8.0 |
| **Execution mode** | SERIAL - one object at a time, same agent, no subagents |

### For Each Object:

#### 3a: Load Phase Rules (MANDATORY - Every Object, Every Time)

Read the GATE rule first: `.cursor/rules/dwh-semantic-doc/GATE-wiki-generation.mdc`

Then load each phase rule file FRESHLY using the Read tool. Do NOT rely on memory from previous objects.

#### 3b: Run the Full Phase Pipeline

Execute in this EXACT order (from `batch-orchestration.mdc`):

```
Phase 1  (Structure Analysis)        -> .cursor/rules/dwh-semantic-doc/01-structure-analysis.mdc
Phase 2  (Live Data Sampling + ETL)  -> .cursor/rules/dwh-semantic-doc/02-live-data-sampling.mdc + mcp-query-rules.mdc
  IMMEDIATE HARD GATE: check Phase 2 gate. If FAILED -> skip object.
Phase 3  (Distribution Analysis)     -> .cursor/rules/dwh-semantic-doc/03-distribution-analysis.mdc
Phase 4  (Lookup Resolution)         -> .cursor/rules/dwh-semantic-doc/04-lookup-resolution.mdc + fk-lookup-reference.mdc
Phase 5  (JOIN Analysis)             -> .cursor/rules/dwh-semantic-doc/05-join-analysis.mdc
Phase 6  (Business Logic Discovery)  -> .cursor/rules/dwh-semantic-doc/06-business-logic-discovery.mdc
Phase 7  (View Dependency Scan)      -> .cursor/rules/dwh-semantic-doc/07-view-dependency-scan.mdc
Phase 8  (Procedure Reference Scan)  -> .cursor/rules/dwh-semantic-doc/08-procedure-reference-scan.mdc
Phase 9  (Procedure Logic Extract)   -> .cursor/rules/dwh-semantic-doc/09-procedure-logic-extraction.mdc
Phase 9B (ETL Orchestration)         -> .cursor/rules/dwh-semantic-doc/09b-etl-orchestration-analysis.mdc
Phase 10 (Atlassian Knowledge Scan)  -> .cursor/rules/dwh-semantic-doc/10-atlassian-knowledge-scan.mdc
Phase 10.5 (Upstream Wiki Bridge)    -> .cursor/rules/dwh-semantic-doc/13-production-lineage-mapping.mdc (Steps 1/1b/1c/3)
Phase 11 (Generate Documentation)   -> .cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc
Phase 13 (Column Lineage)           -> .cursor/rules/dwh-semantic-doc/13-production-lineage-mapping.mdc (Steps 2/4/5/6)
```

**Simple Dictionary Fast-Path**: If object has <= 10 columns, no computed columns, and single-source from SP_Dictionaries, use the condensed pipeline from `batch-orchestration.mdc`.

#### 3c: Phase Gate Checklist (Before Phase 11)

Emit the phase gate checklist from `GATE-wiki-generation.mdc` and `00-execution-card.mdc`. If ANY HARD-gated phase is unchecked, DO NOT generate. Go run that phase.

#### 3d: Write the Documentation

Write the `.md` file to: `knowledge/synapse/Wiki/{Schema}/Tables/{Schema}.{ObjectName}.md`
(or `Views/` for views)

#### 3e: Track Result in Memory

Record status (Done/Failed/Skipped) and quality score. Do NOT update `_index.md` per-object - bulk update at end.

#### 3f: Print Per-Object Completion

```
[{N}/{total}] DWH_dbo.Dim_Position (Table) - Quality: 8.5 - 14 phases - 3 deps inherited
```

---

## Step 4: Finalize Batch and HARD STOP

After all objects in the batch are processed:

### 4a: Bulk-Update `_index.md`

Call `index-management.mdc` Protocol 2 (BATCH UPDATE) to record all results at once.

### 4b: Write Context Handoff

Call `context-handoff.mdc` Protocol 1 (WRITE) or Protocol 3 (MERGE) to serialize `_batch_context.json`.

### 4c: Print End-of-Batch Banner

```
+==================================================================+
|  BATCH {N} COMPLETE - {Schema}                                    |
|                                                                   |
|  Objects:  {processed} processed, {failed} failed                 |
|  Quality:  avg {avg} (range {min} - {max})                       |
|  Progress: {total_done}/{total_objects} ({pct}%)                 |
|  Next:     Batch {N+1} ({next_count} objects remaining)          |
|                                                                   |
|  SESSION ENDS HERE - loop script starts next session.             |
+==================================================================+
```

### 4d: HARD STOP - DO NOT CONTINUE

After printing the summary:
1. **DO NOT** start planning the next batch
2. **DO NOT** ask "shall I continue?"
3. **DO NOT** run Phase 12 enrichment (that's for schema completion)
4. **STOP. The batch session is complete. The loop script handles the next iteration.**

---

## Schema Complete

When all objects are documented (no `Pending` remaining), print:

```
+==================================================================+
|  SCHEMA COMPLETE - {Schema}                                       |
|                                                                   |
|  Batches:  {total_batches}                                        |
|  Objects:  {documented} documented, {failed} failed               |
|  Quality:  avg {avg}                                              |
|                                                                   |
|  Recommended next step:                                           |
|  /build-wiki-dwh-batch enrich {Schema}                           |
|  (runs Phase 12 cross-object enrichment across all docs)         |
+==================================================================+
```

---

## Error Recovery

| Issue | Solution |
|-------|----------|
| MCP connection lost mid-batch | Stop. Objects already written are safe. Resume in next session. |
| Object fails quality check | Re-attempt once. If still fails, mark as `Failed` with reason, continue. |
| Dependency `.md` missing | Document it first (safety net). |
| `_index.md` corrupt | Use Glob on wiki folder to rebuild documented set. Proceed to plan. |
| Session interrupted mid-batch | On re-run, find `Queued` objects and resume from first `Queued`. |
| `_dependency_order.json` missing | STOP with error. Run `_build_dependency_order.py` first. |
