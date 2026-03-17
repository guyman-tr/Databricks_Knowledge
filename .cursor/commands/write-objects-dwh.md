---
description: Deploy DWH wiki documentation to Unity Catalog. Generates ALTER scripts, tags, PII metadata, and downstream propagation from existing wiki files.
---

# Write Objects — DWH (Deploy to Unity Catalog)

**Spec Reference**: `/.specify/specs/003-synapse-knowledge/spec.md`
**Config Reference**: `/.specify/Configs/dwh-semantic-doc-config.json`

## Purpose

Deploy wiki documentation to Unity Catalog. Reads wiki `.md` files produced by `build-wiki-dwh` and generates ALTER scripts (table comment, column comments, tags, PII metadata) plus downstream propagation. This command does NOT re-run wiki analysis phases — it consumes existing wiki output.

---

## 1. Command Overview & Arguments (T059)

### Invocation

```text
/write-objects-dwh {schema_name | single_object_name} [scope]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `schema_name` | Yes* | Schema to deploy (e.g., `DWH_dbo`) |
| `single_object_name` | Yes* | Fully qualified object (e.g., `DWH_dbo.Dim_ActionType`) — triggers single-object mode |
| `scope` | No | Optional scope keyword (see Section 3) |

*First argument is either a schema name OR a fully qualified object name. If the first argument contains a dot and matches `{Schema}.{ObjectName}`, treat as single-object mode.

### Scope Detection

- **First arg is `{Schema}.{ObjectName}`** (e.g., `DWH_dbo.Dim_ActionType`) → Single-object mode
- **Second arg is `status`** → Status mode (read-only)
- **Second arg is `resume`** → Resume mode (continue from last deploy batch)
- **Second arg is `re-deploy`** → Re-deploy stale objects only
- **Second arg absent** → Schema mode (deploy all Done objects)

---

## 2. Pre-Flight Checks (T060)

Before any processing, verify prerequisites:

| Check | Source | Required | Note |
|-------|--------|----------|------|
| Databricks MCP | MCP connection | **MANDATORY** | UC deployment target. **STOP** if unavailable — deployment cannot proceed |
| Synapse MCP | MCP connection | Optional | PII GDPR queries — graceful degradation to column-name patterns |
| Atlassian MCP | N/A | **NOT NEEDED** | Business context already in wiki |
| Dataplatform SSDT repo | Local filesystem | Advisory | For verify SP references; not required for deployment |
| `_index.md` | Local filesystem | **MANDATORY** | Must exist for schema scope — lists Done objects |
| Wiki `.md` files | Local filesystem | **MANDATORY** | Per-object wiki must exist |

### Check 1: Databricks MCP

Run a test query (e.g., `SELECT 1`). If it fails → **STOP**: "Databricks MCP unavailable. UC deployment requires Databricks connectivity. Generate ALTER scripts manually or retry when connected."

### Check 2: Synapse MCP (Advisory)

Run `SELECT 1 AS ConnectionTest`. If it fails → **WARN**: "Synapse MCP unavailable. PII detection will fall back to column-name patterns."

### Check 3: Schema Files

For schema scope: verify `knowledge/synapse/Wiki/{Schema}/_index.md` exists. If missing → **STOP**: "Run `build-wiki-dwh {Schema}` first to create wiki documentation."

For single-object mode: verify the wiki `.md` file exists at the expected path.

---

## 3. Scope Options (T061)

| Scope | Description |
|-------|-------------|
| **schema** (default) | Deploy all objects with wiki status `Done` in `_index.md` |
| **resume** | Continue from last deployment batch in `_deploy-index.md` — deploy Pending objects that were not yet processed |
| **status** | Read-only: show deployment progress from `_deploy-index.md` via `deploy-index-management.mdc` Protocol 3 |
| **single** | Deploy one object (auto-detected when first arg is fully qualified, e.g., `DWH_dbo.Dim_ActionType`) |
| **re-deploy** | Re-deploy objects whose wiki was updated after last deploy (stale detection via Protocol 4) |

---

## 4. Per-Object Pipeline (T062)

Reference `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc` (Phase 11W) for the full pipeline. Steps:

1. **Parse wiki `.md` file** — Wiki File Parsing Protocol from 11w (header table, Section 1 Business Meaning, Section 4 Elements, Section 5 Lineage, quality footer)
2. **UC Object Resolution** — Find the UC target table via `information_schema`, `SHOW TABLES`, or mapping view
3. **UC Table Metadata Discovery** — `DESCRIBE DETAIL`, `DESCRIBE TABLE EXTENDED` for format, partitioning
4. **Generic Pipeline Mapping query** — For `refresh_frequency`, `sla`, `source_system`, `pii` (Phase 13 Step 1b)
5. **ALTER script generation** — Table comment + column comments (≤1024 chars each)
6. **Table tags generation** — domain, object_type, refresh_frequency, sla, source_system, etc.
7. **Column PII tags** — `none` or `direct` per column
8. **Downstream column comment propagation** — Deep lineage via `_deep_propagate_lib.py` → `.downstream.alter.sql`
9. **ALTER execution** — Single-session Python script (do NOT execute via individual MCP calls)
10. **Deploy report generation** — `.deploy-report.md`

---

## 5. Batch Processing (T063)

### Batch Configuration

- **Default batch size**: 25 objects (deployment is lighter than wiki build)
- **Order**: Bottom-up from `_dependency_order.json` (upstream first)
- **Parallel subagents**: Up to 4 concurrent, each processing 5–8 objects

### Flow

1. Load `_deploy-index.md` (create via `deploy-index-management.mdc` Protocol 1 if missing)
2. Filter to objects with status `Pending` (or `Stale` for re-deploy scope)
3. Order by dependency depth
4. Split into batches of 25
5. For each batch: dispatch subagents, each running the per-object pipeline
6. Update `_deploy-index.md` after each object via Protocol 2

---

## 6. _deploy-index.md Management (T064)

- **Auto-create**: On first schema run, if `_deploy-index.md` does not exist, create it via `deploy-index-management.mdc` Protocol 1 (scan `_index.md` for Done objects, initialize all as Pending)
- **Update**: After each object deploys, update status via Protocol 2
- **Stale detection**: For `re-deploy` scope, run Protocol 4 to identify objects with `Stale — wiki updated`

---

## 7. Single-Object Mode (T065)

When first argument is a fully qualified name (e.g., `DWH_dbo.Dim_ActionType`):

1. **Bypass** batch planning and `_deploy-index.md` creation
2. **Deploy one object** directly using the per-object pipeline (11w-write-objects.mdc)
3. **Prerequisite**: Wiki `.md` file must exist
4. **Optional**: Update `_deploy-index.md` if it exists (add/update this object's status)

---

## 8. Rule File References (T066)

### Deployment Rules

```
.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc
.cursor/rules/semantic-layer-core/deploy-index-management.mdc
.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc
.cursor/rules/semantic-layer-core/repo-first-access.mdc
```

### Related (for context)

```
.cursor/rules/semantic-layer-core/index-management.mdc   (_index.md for wiki build)
.cursor/rules/semantic-layer-core/batch-orchestration.mdc (batch sizing reference)
```

---

## Repository Structure

| Path | Purpose |
|------|---------|
| `knowledge/synapse/Wiki/{Schema}/Tables/` | Table wiki + ALTER output |
| `knowledge/synapse/Wiki/{Schema}/Views/` | View wiki + ALTER output |
| `knowledge/synapse/Wiki/{Schema}/_index.md` | Wiki build tracking |
| `knowledge/synapse/Wiki/{Schema}/_deploy-index.md` | Deployment tracking |
| `knowledge/synapse/Wiki/_dependency_order.json` | Dependency graph for batch order |

---

## Output Files Per Object

| File | Description |
|------|-------------|
| `{ObjectName}.alter.sql` | Main ALTER script (table comment, tags, column comments, PII tags) |
| `{ObjectName}.downstream.alter.sql` | Downstream column comment propagation |
| `{ObjectName}.deploy-report.md` | Deployment execution summary |

---

## Error Recovery

| Issue | Solution |
|-------|----------|
| Databricks MCP unavailable | **STOP** — deployment cannot proceed |
| UC target not found | Mark as Failed in `_deploy-index.md`, continue with next object |
| ALTER execution error | Log in deploy report, mark column/object in review sidecar |
| Mid-batch crash | Resume: run `/write-objects-dwh {Schema} resume` |
