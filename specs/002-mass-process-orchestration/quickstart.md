# Quickstart: Wiki Build + Write Objects (Post-Pivot)

**Branch**: `002-mass-process-orchestration` | **Date**: 2026-03-22

---

## The Commands

The monolithic `build-semantic-layer-dwh` (14 phases + ALTER + deploy per object, batch size 5) is replaced by focused commands:

| Command | What It Does | Needs | Batch Size | Notes |
|---------|-------------|-------|------------|-------|
| `/build-wiki-dwh` | Phases 1→12 → wiki `.md` + sidecar + lineage | Synapse + Atlassian | 10-15 | Serial per object in batch |
| `/generate-alter-dwh` | Read wikis → `.alter.sql` (no UC execution) | Optional Databricks for `_Pending` targets | 25 | Updates `_deploy-index.md` |
| `/deploy-alter-dwh` | Execute ALTERs against Unity Catalog | Databricks | 25 | `.deploy-report.md` per object |

Downstream propagation (if used) remains `/propagate-downstream-dwh` per object or batch.

---

## Workflow

### Step 1: Build Wikis (`build-wiki-dwh`)

Generate semantic documentation for all objects in a schema.

```
/build-wiki-dwh {schema_name}
```

**What happens:**
1. Loads `_index.md` (or auto-generates if first run). Reads `_batch_context.json` for cross-batch knowledge.
2. Plans the next batch: 10-15 Pending objects, depth-ordered.
3. Processes each object serially through the phase pipeline (Phases 1→2→3→...→10→10A→10B→11→12).
4. Bulk-updates `_index.md`, writes `_batch_context.json`, prints summary.
5. Stops. Start a new chat for the next batch.

**Output per object:** `.md` (wiki), `.review-needed.md` (sidecar), `.lineage.md` (column lineage)

**Repeat** until all objects are `Done` in `_index.md`.

### Step 2: Generate ALTERs (`generate-alter-dwh`)

Generate ALTER scripts from wiki files. Does NOT execute against Databricks.

```
/generate-alter-dwh {schema_name}
```

**What happens:**
1. Reads `_index.md` — processes all objects with wiki status `Done`.
2. Optionally queries Databricks to resolve `_Pending` UC targets (bulk `information_schema` query).
3. Generates `.alter.sql` per object (table comment, column comments, tags, PII).
4. Updates `_deploy-index.md` with `Generated` status.

### Step 3: Deploy ALTERs (`deploy-alter-dwh`)

Execute ALTER scripts against Unity Catalog. Requires Databricks connection.

```
/deploy-alter-dwh {schema_name}
```

**What happens:**
1. Reads `_deploy-index.md` — deploys all `Generated` objects.
2. Opens a single `databricks.sql.connect()` session per batch.
3. Executes ALTER statements sequentially with per-statement logging.
4. Generates `.deploy-report.md` per object.
5. Updates `_deploy-index.md` with `Deployed` status.

### Step 4: Review & Re-deploy

After deployment, review results and handle any issues:

1. Check `_deploy-index.md` status — any `Failed` objects?
2. For failed objects: check `.deploy-report.md` for error details, fix the wiki, regenerate ALTER, redeploy.
3. For objects with review sidecar items: use `/wiki-review` to walk through Tier 4 and unverified items.
4. When upstream DB_Schema wikis are updated: re-run `build-wiki-dwh` for affected objects (staleness threshold handles this), then `generate-alter-dwh` + `deploy-alter-dwh`.

---

## Workflow: Document a Single Object

For one-off documentation:
```
/build-wiki-dwh {schema_name}.{object_name}
```

Then generate and deploy:
```
/generate-alter-dwh {schema_name}.{object_name}
/deploy-alter-dwh {schema_name}.{object_name}
```

---

## File Organization (Unchanged)

Everything stays grouped in the same folder:

```
knowledge/synapse/Wiki/DWH_dbo/
├── _index.md                              ← wiki build progress
├── _deploy-index.md                       ← deployment progress
├── _batch_context.json                    ← cross-batch knowledge
├── Tables/
│   ├── Dim_ActionType.md                  ← wiki doc (build-wiki-dwh)
│   ├── Dim_ActionType.review-needed.md    ← review sidecar (build-wiki-dwh)
│   ├── Dim_ActionType.lineage.md          ← lineage mapping (build-wiki-dwh)
│   ├── Dim_ActionType.alter.sql           ← ALTER script (generate-alter-dwh)
│   ├── Dim_ActionType.downstream.alter.sql← downstream (propagate-downstream-dwh, if used)
│   ├── Dim_ActionType.deploy-report.md    ← deploy report (deploy-alter-dwh)
│   ├── Dim_ActionType.lineage.py          ← lineage inject (optional / downstream tooling)
│   ├── Dim_Customer.md
│   ├── Dim_Customer.review-needed.md
│   └── ...
└── Views/
    ├── V_Dim_Customer.md
    └── ...
```

---

## Throughput

| Metric | Value |
|--------|-------|
| Wiki batch size | 10-15 objects |
| Wiki per-object time | ~5-10 min (complex), ~2-3 min (dictionary fast-path) |
| Wiki batches per operator-day | 1-2 |
| ALTER generation batch size | 25 objects |
| ALTER generation time | ~2-3 min per batch |
| Deploy batch size | 25 objects |
| Deploy time | ~5 min per batch |

### Actual Progress

| Schema | Objects | Wiki Batches | Avg Quality | Status |
|--------|---------|-------------|-------------|--------|
| DWH_dbo | 130 | 15 | 8.0 | ✅ Complete |
| Dealing_dbo | 231 | 20 | 7.8 | ✅ Complete |
| BI_DB_dbo | 30/1204 | 6 | 9.1 | 🟡 In progress |

---

## Function Documentation

Functions follow a tailored phase path:
- **No Phase 2/3**: Functions don't hold data — no live sampling or distribution analysis
- **Reversed Phase 7**: Instead of finding views this function depends on, find callers (views/SPs that use this function)
- **UC Target**: Defaults to `_Not_Migrated` since most DWH functions don't have UC counterparts
- **Output**: Same three files (`.md`, `.review-needed.md`, `.lineage.md`) in `knowledge/synapse/Wiki/{Schema}/Functions/`

---

## Migration Status

DWH_dbo wiki documentation is complete (130 objects across 15 batches). Dealing_dbo is complete (231 objects, 20 batches). BI_DB_dbo is in progress (30 of 1204 active objects documented across 6 batches).

ALTER generation and deployment are operational for DWH_dbo and Dealing_dbo. BI_DB_dbo ALTER deployment will follow wiki completion.

---

## Rule Files Summary

### New Files

| File | Purpose |
|------|---------|
| `.cursor/commands/build-wiki-dwh.md` | Wiki build command |
| `.cursor/commands/generate-alter-dwh.md` | ALTER generation (no execution) |
| `.cursor/commands/deploy-alter-dwh.md` | UC deployment command |
| `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc` | ALTER generation + deployment logic |
| `.cursor/rules/semantic-layer-core/deploy-index-management.mdc` | `_deploy-index.md` tracking protocol |

### Modified Files

| File | Change |
|------|--------|
| `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` | Strip ALTER/deploy sections → wiki + sidecar + lineage only |
| `.cursor/rules/semantic-layer-core/batch-orchestration.mdc` | `DEFAULT_BATCH_SIZE` 5 → 15 |

### Deprecated Files

| File | Replacement |
|------|------------|
| `.cursor/commands/build-semantic-layer-dwh.md` | `build-wiki-dwh.md` |
| `.cursor/commands/build-semantic-layer-dwh-no-propagation.md` | Redundant — wiki build IS no-propagation |
