# Data Model: Pipeline Decomposition — Wiki Build + Write Objects

**Branch**: `002-mass-process-orchestration` | **Date**: 2026-03-16

---

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SCHEMA (DWH_dbo)                            │
│                                                                     │
│  ┌──────────────┐    ┌──────────────────┐    ┌──────────────────┐  │
│  │  _index.md   │    │ _deploy-index.md │    │ _batch_context   │  │
│  │  (wiki build │    │ (write-objects   │    │    .json         │  │
│  │   tracking)  │    │   tracking)      │    │ (cross-batch     │  │
│  └──────┬───────┘    └────────┬─────────┘    │  knowledge)      │  │
│         │                     │              └──────────────────┘  │
│         │ "Done" objects      │ reads from                         │
│         │ eligible for        │ _index.md                          │
│         ▼ deployment          ▼                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    OBJECT (per table/view)                    │  │
│  │                                                              │  │
│  │   build-wiki-dwh produces:          write-objects-dwh reads: │  │
│  │   ┌─────────────┐                   ┌─────────────┐         │  │
│  │   │ {Object}.md │ ─────────────────▶│ {Object}.md │         │  │
│  │   └─────────────┘                   └──────┬──────┘         │  │
│  │   ┌──────────────────────┐                 │                │  │
│  │   │ {Object}             │                 │ produces:      │  │
│  │   │   .review-needed.md  │                 ▼                │  │
│  │   └──────────────────────┘         ┌──────────────────┐     │  │
│  │   ┌──────────────────────┐         │ {Object}         │     │  │
│  │   │ {Object}             │         │   .alter.sql     │     │  │
│  │   │   .lineage.md        │         └──────────────────┘     │  │
│  │   └──────────────────────┘         ┌──────────────────┐     │  │
│  │                                    │ {Object}         │     │  │
│  │                                    │   .downstream    │     │  │
│  │                                    │   .alter.sql     │     │  │
│  │                                    └──────────────────┘     │  │
│  │                                    ┌──────────────────┐     │  │
│  │                                    │ {Object}         │     │  │
│  │                                    │   .deploy-report │     │  │
│  │                                    │   .md            │     │  │
│  │                                    └──────────────────┘     │  │
│  │                                    ┌──────────────────┐     │  │
│  │                                    │ {Object}         │     │  │
│  │                                    │   .lineage.py    │     │  │
│  │                                    └──────────────────┘     │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Entity: Wiki Build Command (`build-wiki-dwh`)

### Inputs

| Input | Source | Required |
|-------|--------|----------|
| Schema name | User argument | Yes |
| `_dependency_order.json` | Pre-computed | Yes |
| Synapse MCP connection | MCP server | Advisory (Phases 2-3 live data only per Constitution IX) |
| Atlassian MCP connection | MCP server | Yes |
| Upstream wiki files | Local repo | Advisory |
| Dataplatform repo (SP code) | Local repo | Advisory |
| `knowledge/glossary.md` | Local file | Advisory |
| `_batch_context.json` | Previous batch | On resume |
| `_index.md` | Previous run | On resume |

### Outputs (per object)

| Output | Format | Content |
|--------|--------|---------|
| `{Object}.md` | Markdown | Wiki documentation (8 sections) |
| `{Object}.review-needed.md` | Markdown | Review sidecar with Tier 4 items |
| `{Object}.lineage.md` | Markdown | Column-level production lineage |

### Outputs (per schema, per batch)

| Output | Format | Content |
|--------|--------|---------|
| `_index.md` | YAML + Markdown | Wiki build progress tracking |
| `_batch_context.json` | JSON | Cross-batch glossary/relationships |

### Scope Options

| Scope | Description |
|-------|-------------|
| Schema | Full batch processing for all objects in a schema |
| Resume | Continue from last completed batch |
| Status | Read-only progress display |
| Single | Document one object |

---

## Entity: Write Objects Command (`write-objects-dwh`)

### Inputs

| Input | Source | Required |
|-------|--------|----------|
| Schema name or object name | User argument | Yes |
| Wiki `.md` files | `build-wiki-dwh` output | Yes |
| Databricks MCP connection | MCP server | Yes |
| `_index.md` | Wiki build tracking | Yes (schema scope) |
| Synapse MCP connection | MCP server | Optional (PII queries) |
| `.lineage.md` files | Wiki build output | Optional |

### Outputs (per object)

| Output | Format | Content |
|--------|--------|---------|
| `{Object}.alter.sql` | SQL | Table comment + column comments + tags + PII |
| `{Object}.downstream.alter.sql` | SQL | Downstream UC object comments |
| `{Object}.deploy-report.md` | Markdown | Execution summary |
| `{Object}.lineage.py` | Python | UC lineage injection (offline) |

### Outputs (per schema)

| Output | Format | Content |
|--------|--------|---------|
| `_deploy-index.md` | YAML + Markdown | Deployment progress tracking |

### Scope Options

| Scope | Description |
|-------|-------------|
| Schema | Deploy all documented objects in a schema |
| Resume | Continue deployment from last batch |
| Status | Read-only deployment progress display |
| Single | Deploy one object |
| Re-deploy | Re-deploy after review-rerun corrections |

---

## Entity: `_index.md` (Wiki Build Tracking)

### YAML Frontmatter

```yaml
---
schema: DWH_dbo
database: Synapse DWH
total_objects: 281
documented: 120
failed: 2
last_batch: 8
last_updated: "2026-03-18"
quality_avg: 7.8
---
```

### Status Values

| Status | Meaning |
|--------|---------|
| `Done (Batch N)` | Wiki + sidecar written in batch N |
| `Queued (Batch N, #M)` | Assigned to batch N, position M |
| `Pending` | Not yet assigned to any batch |
| `Failed (Batch N) — {reason}` | Failed during batch N |
| `Skipped — stale <30d` | Wiki file exists and is fresh |

Same format as existing `_index.md` — no structural changes needed. Only `DEFAULT_BATCH_SIZE` increases to 15.

---

## Entity: `_deploy-index.md` (Deployment Tracking)

### YAML Frontmatter

```yaml
---
schema: DWH_dbo
database: Synapse DWH
total_deployable: 120
deployed: 80
failed: 3
last_batch: 4
last_updated: "2026-03-20"
---
```

### Status Values

| Status | Meaning |
|--------|---------|
| `Deployed (Batch N)` | ALTER executed successfully in batch N |
| `Queued (Batch N, #M)` | Assigned for deployment |
| `Pending` | Has wiki doc but not yet scheduled |
| `Failed (Batch N) — {reason}` | ALTER execution failed |
| `Stale — wiki updated` | Wiki was regenerated after last deploy |

### Markdown Body

```markdown
## Deployment Progress

| Metric | Value |
|--------|-------|
| **Deployable** | {count with Done status in _index.md} |
| **Deployed** | {count} ({pct}%) |
| **Failed** | {count} |
| **Stale** | {count} |

## Next Deployment Batch (Batch N) — {M} objects

| # | Object | Type | Wiki Quality | Dependencies |
|---|--------|------|-------------|--------------|
| 1 | DWH_dbo.Dim_ActionType | Table | 7.8 | (none) |
| ... | ... | ... | ... | ... |

## Completed Deployments (newest first)
...

## Tables
| Object | Wiki Quality | Deploy Status | Last Deployed |
|--------|-------------|---------------|---------------|
| ... | ... | ... | ... |

## Views
...
```

---

## Entity: Phase 11 Slim (Wiki Build Variant)

### What Changes From Current Phase 11

| Section | Current | Wiki Build Variant |
|---------|---------|-------------------|
| Wiki `.md` generation | ✅ | ✅ Same |
| Review sidecar generation | ✅ | ✅ Same |
| UC Object Resolution | ✅ (3-4 UC queries) | ❌ Removed |
| UC Table Metadata Discovery | ✅ (2 UC queries) | ❌ Removed |
| ALTER script generation | ✅ | ❌ Moved to write-objects |
| Table tags | ✅ | ❌ Moved to write-objects |
| PII tags | ✅ | ❌ Moved to write-objects |
| Downstream propagation | ✅ | ❌ Moved to write-objects |
| Deploy script + execution | ✅ | ❌ Moved to write-objects |
| Deploy report | ✅ | ❌ Moved to write-objects |
| Quality score calculation | ✅ | ✅ Same |
| Cross-object pre-read | ✅ | ✅ Same |

### Wiki Template Changes

The wiki properties table uses placeholder values for UC-specific fields:

```markdown
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending_ |
| **UC Partitioned By** | _Pending_ |
| **UC Table Type** | _Pending_ |
```

Phase 11 Rules B1-B7 (batch quality enforcement) are preserved — they apply to wiki generation regardless of whether ALTER scripts follow.

---

## Entity: Phase 11W — Write Objects Logic

### New Rule File: `11w-write-objects.mdc`

Encapsulates all UC-facing operations previously embedded in Phase 11:

1. **Wiki Parsing**: Read existing `.md` file, extract Elements table, Business Meaning, Lineage
2. **UC Object Resolution**: Same algorithm as current Phase 11 (search information_schema, SHOW TABLES, mapping view)
3. **UC Table Metadata**: DESCRIBE DETAIL + DESCRIBE TABLE EXTENDED for format/partitioning
4. **Generic Pipeline Mapping**: Query for refresh_frequency, sla, source_system
5. **PII Detection**: GDPR tables + column patterns
6. **ALTER Generation**: Same template as current Phase 11
7. **Tag Generation**: Same tag set
8. **Downstream Propagation**: Same deep lineage library
9. **Execution**: Same single-session Python script
10. **Deploy Report**: Same template

### Wiki Backfill (Optional)

After UC resolution, optionally update the wiki `.md` file's properties table with the resolved UC target and metadata. This is a quality-of-life improvement, not a requirement.

---

## Relationships Between Entities

```
build-wiki-dwh                         write-objects-dwh
┌────────────────┐                      ┌────────────────┐
│                │                      │                │
│  _index.md     │─── "Done" objects ──▶│ _deploy-       │
│                │    eligible for      │  index.md      │
│                │    deployment        │                │
│                │                      │                │
│  {Object}.md   │─── wiki content ───▶│ ALTER script   │
│  .lineage.md   │    feeds ALTER       │ generation     │
│  .review-      │    generation        │                │
│   needed.md    │                      │ .alter.sql     │
│                │                      │ .downstream    │
│  _batch_       │    (not used by      │  .alter.sql    │
│   context.json │     write-objects)   │ .deploy-report │
│                │                      │ .lineage.py    │
└────────────────┘                      └────────────────┘
```

### Dependency Rules

1. An object must have status `Done` in `_index.md` before `write-objects-dwh` can deploy it
2. The wiki `.md` file must exist and pass validation (all 8 sections, Elements table) before ALTER generation
3. `_deploy-index.md` is created by `write-objects-dwh` on first run — it doesn't exist until deployment starts
4. `_batch_context.json` is only used within `build-wiki-dwh` — `write-objects-dwh` never reads it
5. Downstream propagation in `write-objects-dwh` requires prior upstream objects to be deployed first (bottom-up processing order from `_dependency_order.json`)
