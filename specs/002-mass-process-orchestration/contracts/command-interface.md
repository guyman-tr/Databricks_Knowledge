# Contract: Command Interface

**Feature**: Mass Process Orchestration | **Date**: 2026-03-16

## Command: `build-semantic-layer-dwh`

### Scope Options (Step 1 Question)

The command presents one question to determine scope. Each option triggers a different execution path.

```
### Question 1: Documentation Scope
> **What scope of documentation?**
>
> 1. **Single Object** — Document one specific object (e.g., `DWH_dbo.Dim_Position`)
> 2. **Schema** — Document all objects in a schema with automated batch planning (e.g., `DWH_dbo`)
> 3. **Resume** — Continue a previously interrupted schema-level run from the last completed batch
> 4. **Status** — Show current progress (read-only, no files modified)
> 5. **Enrich Existing Docs** — Run cross-object knowledge sync on existing docs
> 6. **Review-Rerun** — Regenerate docs for tables with pending reviewer corrections
```

### Execution Paths

#### Option 1: Single Object (unchanged from today)

```
Input:  Object name (e.g., "DWH_dbo.Dim_Position")
Flow:   Step 2 (resolve) → Step 3 (checklist) → Phases 1–14
Output: .md + .review-needed.md + .alter.sql (+ .downstream.alter.sql if UC available)
State:  No _index.md update (single object mode)
```

#### Option 2: Schema (NEW — batch mode)

```
Input:  Schema name (e.g., "DWH_dbo")
        Optional: batch size (default 5)
Flow:   
  1. Load rules: semantic-layer-core/batch-orchestration.mdc
  2. Load rules: semantic-layer-core/index-management.mdc
  3. Load rules: semantic-layer-core/context-handoff.mdc
  4. SCAN: Query _dependency_order.json, filter by schema
  5. SCAN: Synapse sys.objects scan for objects not in dependency graph
  6. PLAN: Group by depth, segment into batches of N
  7. INDEX: Create or update _index.md with all objects
  8. PROCESS: For each object in current batch:
     a. Run phases 1–14 (same as single object)
     b. Update _index.md (Done/Failed + quality score)
     c. Accumulate glossary and relationships for context handoff
  9. HANDOFF: Write _batch_context.json
  10. REPORT: Print batch summary + resume instruction
Output: Per-object files + _index.md + _batch_context.json
State:  _index.md updated after each object; _batch_context.json at batch end
```

#### Option 3: Resume (NEW)

```
Input:  Schema name (e.g., "DWH_dbo")
Flow:
  1. Load rules: semantic-layer-core/batch-orchestration.mdc
  2. Load rules: semantic-layer-core/index-management.mdc
  3. Load rules: semantic-layer-core/context-handoff.mdc
  4. READ STATE: Parse _index.md → find last completed batch
  5. LOAD CONTEXT: Read _batch_context.json → cross-object knowledge
  6. RE-SCAN: Check _dependency_order.json for new objects (add as Pending)
  7. PLAN: Identify next batch from _index.md
  8. PROCESS: Same as Schema step 8
  9. HANDOFF: Merge new knowledge into _batch_context.json
  10. REPORT: Print batch summary + resume instruction
Output: Same as Schema
State:  Same as Schema (incremental updates)
```

#### Option 4: Status (NEW — read-only)

```
Input:  Schema name (e.g., "DWH_dbo")
Flow:
  1. READ: Parse _index.md frontmatter + object type sections
  2. COMPUTE: Aggregate metrics (done/pending/failed by type)
  3. DISPLAY: Print progress summary (see research.md R7)
Output: Text output only — no files modified
State:  No changes
```

#### Option 5: Enrich Existing Docs (unchanged)

```
Input:  Optional schema filter
Flow:   Phase 12 Cross-Object Enrichment on all existing wiki files
Output: Updated .md files with cross-references
State:  No _index.md changes
```

#### Option 6: Review-Rerun (unchanged)

```
Input:  Optional object name
Flow:   Find .review-needed.md files with corrections → re-run Phase 11
Output: Updated .md + .alter.sql
State:  No _index.md changes (quality score may update)
```

---

## Rule File Loading Contract

### Shared rules (loaded for Schema, Resume, Status scopes)

| Rule | Path | Purpose |
|------|------|---------|
| `batch-orchestration.mdc` | `.cursor/rules/semantic-layer-core/` | Batch planning algorithm, segmentation |
| `index-management.mdc` | `.cursor/rules/semantic-layer-core/` | `_index.md` CRUD |
| `context-handoff.mdc` | `.cursor/rules/semantic-layer-core/` | `_batch_context.json` read/write/distill |

### Target-specific rules (loaded per object, unchanged)

| Rule | Path | Purpose |
|------|------|---------|
| `01-structure-analysis.mdc` through `14-query-advisory-metadata.mdc` | `.cursor/rules/dwh-semantic-doc/` | Per-object documentation phases |
| `mcp-query-rules.mdc` | `.cursor/rules/dwh-semantic-doc/` | Synapse query safety |
| `fk-lookup-reference.mdc` | `.cursor/rules/dwh-semantic-doc/` | Column → table mappings |

---

## File Path Conventions

| File | Path Template | Created By |
|------|---------------|------------|
| Object Registry | `knowledge/synapse/Wiki/{Schema}/_index.md` | `index-management.mdc` |
| Batch Context | `knowledge/synapse/Wiki/{Schema}/_batch_context.json` | `context-handoff.mdc` |
| Dependency Order | `knowledge/synapse/Wiki/_dependency_order.json` | `_build_dependency_order.py` (manual) |
| Object Wiki | `knowledge/synapse/Wiki/{Schema}/Tables/{ObjectName}.md` | Phase 11 |
| Object ALTER | `knowledge/synapse/Wiki/{Schema}/Tables/{ObjectName}.alter.sql` | Phase 11 |
| Object Review | `knowledge/synapse/Wiki/{Schema}/Tables/{ObjectName}.review-needed.md` | Phase 11 |

---

## Resume Protocol Contract

### End-of-batch output (printed by agent)

```
╔══════════════════════════════════════════════════════════════════╗
║  BATCH {N} COMPLETE — {Schema}                                  ║
║                                                                 ║
║  Objects:  {processed} processed, {failed} failed               ║
║  Quality:  avg {avg} (range {min} – {max})                     ║
║  Progress: {total_done}/{total_objects} ({pct}%)               ║
║  Next:     Batch {N+1} ({next_count} objects at depth {depth}) ║
║                                                                 ║
║  To continue, start a new chat and run:                        ║
║  /build-semantic-layer-dwh resume {Schema}                     ║
╚══════════════════════════════════════════════════════════════════╝
```

### Schema-complete output (printed when all batches done)

```
╔══════════════════════════════════════════════════════════════════╗
║  SCHEMA COMPLETE — {Schema}                                     ║
║                                                                 ║
║  Batches:  {total_batches}                                      ║
║  Objects:  {documented} documented, {failed} failed             ║
║  Quality:  avg {avg}                                            ║
║                                                                 ║
║  Recommended next step:                                         ║
║  /build-semantic-layer-dwh enrich {Schema}                     ║
║  (runs Phase 12 cross-object enrichment across all docs)       ║
╚══════════════════════════════════════════════════════════════════╝
```

### Resume handshake

1. Operator starts new chat
2. Operator types: `/build-semantic-layer-dwh resume DWH_dbo`
3. Agent reads `knowledge/synapse/Wiki/DWH_dbo/_index.md`
4. Agent reads `knowledge/synapse/Wiki/DWH_dbo/_batch_context.json`
5. Agent identifies next batch from `_index.md` (first batch with `Queued` objects)
6. Agent loads glossary and relationships from `_batch_context.json`
7. Agent proceeds to process the next batch

### Error recovery

| Scenario | Behavior |
|----------|----------|
| Session crashes mid-object | `_index.md` has the last completed object. Resume skips Done objects. The in-progress object has no status change — treated as Pending on resume. |
| Session crashes mid-batch | Some objects are Done, rest are still Queued. Resume processes remaining Queued objects in the same batch. |
| `_batch_context.json` missing | Resume proceeds without cross-object context. Warns operator. |
| `_index.md` missing | Resume fails with clear error: "No tracking file found. Run schema scope first." |
| `_dependency_order.json` missing | Schema scope fails with clear error: "No dependency graph found. Run _build_dependency_order.py first." |
