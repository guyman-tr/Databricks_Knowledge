# Quickstart: Wiki Build + Write Objects (Post-Pivot)

**Branch**: `002-mass-process-orchestration` | **Date**: 2026-03-16

---

## The Two Commands

The monolithic `build-semantic-layer-dwh` (14 phases + ALTER + deploy per object, batch size 5) is replaced by two focused commands:

| Command | What It Does | Needs | Batch Size | Per-Object Time |
|---------|-------------|-------|------------|----------------|
| `/build-wiki-dwh` | Phases 1-12+14 → wiki `.md` + sidecar + lineage | Synapse + Atlassian | 15-25 | ~5-10 min |
| `/write-objects-dwh` | Read wiki → ALTER + tags + PII + downstream + deploy | Databricks | 25-50 | ~3-5 min |

---

## Workflow: Document a Full Schema (DWH_dbo)

### Step 1: Build All Wikis (~5-6 days)

```
/build-wiki-dwh DWH_dbo
```

This discovers all 281 objects, plans batches of 15-25, and starts documenting.

After each batch completes (~2h), start a new chat and run the same command — it auto-detects Plan vs Execute mode:
```
/build-wiki-dwh DWH_dbo
```

Check progress anytime:
```
/build-wiki-dwh DWH_dbo status
```

**Output**: 281 wiki `.md` files + `.review-needed.md` sidecars + `.lineage.md` files. All in `knowledge/synapse/Wiki/DWH_dbo/Tables/` and `Views/`.

### Step 2: Review Offline (parallel with Step 1)

Domain experts review `.review-needed.md` files at their own pace. Corrections go into `## Reviewer Corrections`. No rush — this doesn't block wiki build.

### Step 3: Deploy to Unity Catalog (~2-3 days)

```
/write-objects-dwh DWH_dbo
```

This reads all wiki files with status `Done`, generates ALTER scripts, and executes them against UC.

After each batch:
```
/write-objects-dwh DWH_dbo resume
```

**Output**: `.alter.sql` + `.downstream.alter.sql` + `.deploy-report.md` + `.lineage.py` per object.

### Step 4: Re-Deploy After Reviews

After domain experts correct items:
```
/write-objects-dwh DWH_dbo re-deploy
```

Picks up objects whose wiki was updated after last deployment (status `Stale` in `_deploy-index.md`).

---

## Workflow: Document a Single Object

For one-off documentation:
```
/build-wiki-dwh DWH_dbo.Dim_Customer
```

Then deploy it:
```
/write-objects-dwh DWH_dbo.Dim_Customer
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
│   ├── Dim_ActionType.alter.sql           ← ALTER script (write-objects-dwh)
│   ├── Dim_ActionType.downstream.alter.sql← downstream (write-objects-dwh)
│   ├── Dim_ActionType.deploy-report.md    ← deploy report (write-objects-dwh)
│   ├── Dim_ActionType.lineage.py          ← lineage inject (write-objects-dwh)
│   ├── Dim_Customer.md
│   ├── Dim_Customer.review-needed.md
│   └── ...
└── Views/
    ├── V_Dim_Customer.md
    └── ...
```

---

## Comparison: Before vs After

| Metric | Before (Monolithic) | After (Split) |
|--------|-------------------|---------------|
| Batch size | 5 | 15-25 (wiki), 25 (deploy) |
| Per-object time | ~25 min | ~5-10 min (wiki) + ~3-5 min (deploy) |
| Parallel subagents | None | 4 concurrent (3 tables each) |
| Batches for 281 objects | ~56 | ~26 rounds (wiki) + ~6-12 (deploy) |
| Total time estimate | ~3-4 weeks | **~2-3 days** (with parallel subagents) |
| Resume points | Every 5 objects | Every 15-25 objects |
| Manual chat restarts | ~56 | ~12 plan/execute pairs (wiki) + ~6 (deploy) |
| Databricks connection | Required throughout | Only during write-objects |
| Can review before deploy | No (deploy is inline) | Yes (wiki build → review → deploy) |

---

## Migration: Existing Documented Objects

The 8 objects documented in Batch 1 (`DataLakeTableStatus_ID`, `DataSolutionsProcessesStatus`, `Dim_ActionType`, `Dim_CardType`, `Dim_ContractType`, plus 3 pre-existing) already have wiki `.md` files and some have `.alter.sql` files.

- **No migration needed**: `_index.md` already tracks them as `Done`. The `write-objects-dwh` command can deploy them directly.
- The existing `_index.md` format is compatible — only `DEFAULT_BATCH_SIZE` changes.
- `_deploy-index.md` will be created on first `write-objects-dwh` run.

---

## Rule Files Summary

### New Files

| File | Purpose |
|------|---------|
| `.cursor/commands/build-wiki-dwh.md` | Wiki build command |
| `.cursor/commands/write-objects-dwh.md` | Deployment command |
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
