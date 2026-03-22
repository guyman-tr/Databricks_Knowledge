---
description: Generate ALTER scripts from existing DWH wiki documentation. Resolves UC targets, builds .alter.sql files with table comments, column comments, tags, and PII metadata. Does NOT execute — use deploy-alter-dwh for execution.
---

# Generate ALTER Scripts — DWH (From Wiki)

**Config Reference**: `/.specify/Configs/dwh-semantic-doc-config.json`
**Rule Reference**: `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc`
**Batch Engine**: `knowledge/synapse/Wiki/_batch_generate_lib.py`

## Purpose

Parse existing wiki `.md` files (produced by `build-wiki-dwh`) and generate `.alter.sql` scripts for Unity Catalog deployment. Each script contains ALTER statements for table/view/function comment, column comments, table tags, and column PII tags. Functions are scanned from `Functions/` alongside `Tables/` and `Views/` — most will have no UC counterpart (expected), but any that do will get ALTER scripts.

**This command generates files only — it does NOT execute anything against Databricks.** Use `deploy-alter-dwh` to execute the generated scripts.

**No downstream propagation.** Downstream column comment propagation is handled separately by `propagate-downstream-dwh`.

---

## 1. Command Overview & Arguments

### Invocation

```text
/generate-alter-dwh {schema_name} [single_object_name | status | regenerate]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `schema_name` | Yes | Schema to process (e.g., `Dealing_dbo`) |
| `single_object_name` | No | Single object name — generates ALTER for one object only |
| `status` | No | Read-only: show generation progress from `_deploy-index.md` |
| `regenerate` | No | Re-generate ALTERs for objects whose wiki was updated after last generation |

### Scope Detection

- **Second arg is a name** → Single-object mode
- **Second arg is `status`** → Status mode (read-only)
- **Second arg is `regenerate`** → Regenerate mode (stale detection)
- **Second arg absent** → Schema mode (generate ALTERs for all Done wiki objects)

---

## 2. Pre-Flight Checks

| Check | Source | Required | Note |
|-------|--------|----------|------|
| `_index.md` | Local filesystem | **MANDATORY** | Must exist — lists Done objects eligible for ALTER generation |
| Wiki `.md` files | Local filesystem | **MANDATORY** | Per-object wiki must exist with UC Target property |
| Databricks MCP | Network | **OPTIONAL** | When available: resolves `_Pending` UC targets and backfills wikis. When unavailable: skips `_Pending` objects |

### Check 1: Schema Files

Verify `knowledge/synapse/Wiki/{Schema}/_index.md` exists. If missing → **STOP**: "Run `/build-wiki-dwh {Schema}` first."

### Check 2: Wiki UC Target Property

Each wiki `.md` must have a `| **UC Target** | ... |` row in its property table. If missing or blank → mark as Failed with reason "No UC target in wiki".

### Check 3: Databricks MCP Connectivity

Test Databricks MCP with a lightweight query (e.g., `SELECT 1`). Record result as `dbx_available = true/false`.

- **If available**: `_Pending` UC targets will be resolved via `information_schema.tables` lookup.
- **If unavailable**: Objects with `_Pending` UC targets are skipped (same as prior behavior). Log: `"Databricks MCP unavailable — {N} objects with _Pending UC targets will be skipped. Connect Databricks MCP to resolve them."`

---

## 3. Per-Object Pipeline

For each object, follow these steps from `11w-write-objects.mdc`:

### Step 1: Parse Wiki File (11W Section 3)

Read the wiki `.md` file and extract:
- **Header table**: Schema, Object Type, Production Source, Refresh, Synapse Distribution/Index
- **Section 1 (Business Meaning)**: → table comment (compress to ≤1024 chars)
- **Section 4 (Elements)**: → column comments (each ≤1024 chars). Every description MUST have a `(Tier N — source)` suffix — if missing, flag as non-compliant
- **Section 5 (Lineage)**: → context for tags
- **Quality footer**: → semantic_grade tag

### Step 2: Resolve UC Target

Extract the UC target from the wiki property table row `| **UC Target** | ... |`.

1. **Already resolved** (e.g., `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`) → use as-is. Record `Resolved via: Wiki property table`.
2. **`_Pending` AND `dbx_available = true`** → run Step 2b (UC Resolution Algorithm). On success, backfill the wiki and proceed. On failure (0 rows in UC), mark as `No UC table exists`.
3. **`_Pending` AND `dbx_available = false`** → skip object with reason "UC target pending — Databricks unavailable".
4. **Missing or blank** → mark Failed with reason "No UC target row in wiki".

### Step 2b: UC Resolution Algorithm (when `_Pending`)

**In batch mode, run the bulk query ONCE before processing objects** (see Section 4). In single-object mode, run per-object.

**Bulk query** — fetches all DWH gold-layer tables in one round trip:
```sql
SELECT table_catalog, table_schema, table_name
FROM system.information_schema.tables
WHERE table_catalog = 'main'
  AND table_name LIKE 'gold_sql_dp_prod_we_%'
ORDER BY table_schema, table_name
```
Cache the full result set. For each wiki object, derive the expected UC name pattern and match against the cache.

**Per-object matching:**
1. Derive the expected UC name: `gold_sql_dp_prod_we_{schema}_{table}` all lowercased (e.g., `DWH_dbo.Dim_Affiliate` → `gold_sql_dp_prod_we_dwh_dbo_dim_affiliate`)
2. Search the cache for rows where `table_name` starts with that pattern
3. Classify the result:

| Result Pattern | Classification | Primary UC Target | Secondary UC Target |
|---|---|---|---|
| 1 row in `dwh` schema, no `_masked` suffix | **Standard** | `main.dwh.{name}` | — |
| Row in `dwh` with `_masked` suffix + row in `pii_data` without suffix | **PII Masked** | `main.dwh.{name}_masked` | `main.pii_data.{name}` |
| Row in `pii_data` only, none in `dwh` | **PII Only** | `main.pii_data.{name}` | — |
| 0 rows | **Not in UC** | — | — |

**Wiki backfill** — after resolution, update the wiki `.md` property table:
- Set `| **UC Target** |` to the primary UC target (3-level name without `main.` catalog prefix, e.g., `dwh.gold_...`)
- For PII Masked tables, add/update: `| **UC Target (PII)** | pii_data.gold_... |` and `| **UC Masked Columns** | {cols from GDPR_DL_Tables_Data or column-name patterns} |`

**ALTER generation for dual targets** — when a secondary UC target exists, the `.alter.sql` file contains two sections:
1. Primary target ALTER statements (table comment, tags, column comments, PII tags)
2. `-- === Secondary UC Target (PII unmasked) ===` separator
3. Secondary target ALTER statements (identical column comments — meaning is the same regardless of masking)

Record `Resolved via: information_schema bulk query` in the ALTER script header.

### Step 3: Extract Metadata from Wiki Properties

Read the remaining wiki property rows for tag values:

| Wiki Property | ALTER Tag |
|---------------|-----------|
| `Schema` | `synapse_schema` |
| `Object Type` | `object_type` |
| `Production Source` | `source_system` |
| `Refresh` | `refresh_frequency` |
| `Synapse Distribution` | `synapse_distribution` |
| `Synapse Index` | `synapse_index` |
| `UC Format` | `uc_format` |
| `UC Partitioned By` | `uc_partitioned_by` (if not `_Pending`) |
| Quality footer | `semantic_grade` |

### Step 4: Generate ALTER Script

Write `{ObjectName}.alter.sql` containing:

1. **Header comment** with UC target, resolution method, generation timestamp
2. **Table comment** (`ALTER TABLE ... SET TBLPROPERTIES ('comment' = '...')`)
3. **Table tags** (`ALTER TABLE ... SET TAGS (...)`) — domain, object_type, refresh_frequency, sla, source_system, synapse_distribution, synapse_index, uc_format, uc_partitioned_by, pipeline, semantic_grade
4. **Column comments** — one `ALTER TABLE ... ALTER COLUMN ... COMMENT` per column
5. **Column PII tags** — one `ALTER TABLE ... ALTER COLUMN ... SET TAGS ('pii' = '...')` per column

### Step 6: Column Validation (Deferred)

Column existence validation (does the column actually exist in UC?) is **deferred to deploy-alter-dwh**, which has Databricks connectivity. At generation time, emit ALTERs for all columns found in the wiki Section 4.

The deploy-alter-dwh command will run `DESCRIBE TABLE` before executing and skip non-existent columns, add partition columns (`etr_y`, `etr_ym`, `etr_ymd`), and report mismatches.

### Output Per Object

| File | Description |
|------|-------------|
| `{ObjectName}.alter.sql` | Main ALTER script (table comment, tags, column comments, PII tags) |

---

## 4. Schema Mode — Batch Processing

### Flow

1. Load `_deploy-index.md` (create via `deploy-index-management.mdc` Protocol 1 if missing — scans `_index.md` for Done objects, initializes all as Pending)
2. Filter to Pending objects
3. Order by dependency depth (from `_dependency_order.json` if available)
4. **UC Bulk Resolution** (if `dbx_available`): run the Step 2b bulk query ONCE. Cache all `gold_sql_dp_prod_we_*` table rows from `information_schema.tables`. This cache is reused for every object in the batch — no per-object queries needed.
5. Process each object through the per-object pipeline (Steps 1-6). Step 2b uses the cached results.
6. After each object: update `_deploy-index.md` status to `Generated` (not `Deployed` — that's for deploy-alter-dwh)
7. Print end-of-run summary with resolution statistics

### End-of-Run Summary

The summary report (`_alter_generation_report.md`) uses these categories:

| Category | Meaning |
|----------|---------|
| **Generated** | ALTER script produced — UC target was resolved (from wiki or bulk query) |
| **Resolved this run** | Was `_Pending`, resolved via Databricks bulk query in this run (subset of Generated) |
| **No UC table exists** | Bulk query returned 0 rows — table is not exported to Unity Catalog |
| **Databricks unavailable** | `_Pending` target, but Databricks MCP was not connected |
| **Parse failure** | Wiki file could not be parsed (missing columns, bad format, etc.) |
| **Views (Synapse-only)** | Views — generally not exported via Generic Pipeline |

### Batch Size

Default 25 objects per run. Generation is fast (no ALTER execution, no propagation).

---

## 5. Single-Object Mode

When second argument is an object name:

1. Bypass batch planning
2. Generate ALTER for one object (Steps 1-6)
3. Update `_deploy-index.md` if it exists

---

## 6. Status Mode

When argument is `status`:

1. Read `_deploy-index.md` via `deploy-index-management.mdc` Protocol 3
2. Display: objects Generated/Pending/Failed, generation progress
3. No file modifications

---

## 7. Batch Engine — `_batch_generate_lib.py`

The batch generation is handled by `knowledge/synapse/Wiki/_batch_generate_lib.py`, a schema-agnostic Python utility that lives alongside `_deep_propagate_lib.py` and `_broadcast_propagate.py`.

### Invocation (via Shell tool)

```bash
python "knowledge/synapse/Wiki/_batch_generate_lib.py" {schema_name} [--force] [--offline] [--dry-run]
```

| Flag | Effect |
|------|--------|
| `--force` | Regenerate ALTER scripts even for objects with already-resolved UC targets |
| `--offline` | Skip Databricks queries — only process objects with pre-resolved UC targets |
| `--dry-run` | Print what would happen without writing any files |

### What it does

1. **Bulk UC resolution** — queries `system.information_schema.tables` ONCE for all `gold_{server}_{schema}_*` tables
2. **PII masking detection** — queries `ColumnsToMask` from Generic Pipeline config
3. **Directory scanning** — scans `Tables/`, `Views/`, and `Functions/` wiki directories (deduplicates across directories)
4. **Per-object processing** — for each wiki `.md` file: parse header/columns, match against UC cache, backfill wiki, generate `.alter.sql`
5. **Summary** — prints generation statistics to stdout (with per-type breakdown for views/functions)

### Schema support

Works for any Synapse schema. The UC table name prefix is derived automatically:
- `DWH_dbo` → `gold_sql_dp_prod_we_dwh_dbo_*`
- `Dealing_dbo` → `gold_sql_dp_prod_we_dealing_dbo_*`
- `BI_DB_dbo` → `gold_sql_dp_prod_we_bi_db_dbo_*`

### Programmatic usage

The lib can also be imported and called from the agent directly:
```python
import sys
sys.path.insert(0, "knowledge/synapse/Wiki")
import _batch_generate_lib as bgl

results = bgl.process_schema("DWH_dbo", cursor=dbx_cursor, force=True)
```

---

## 8. Rule File References

### Primary

```
.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc  (Sections 3-10 only — skip Section 11 downstream)
.cursor/rules/semantic-layer-core/deploy-index-management.mdc
```

### Related

```
.cursor/rules/semantic-layer-core/index-management.mdc  (_index.md reference)
.cursor/rules/semantic-layer-core/repo-first-access.mdc
knowledge/synapse/Wiki/_batch_generate_lib.py  (batch engine)
knowledge/synapse/Wiki/_deep_propagate_lib.py  (downstream propagation)
```

---

## 9. Output Structure

```
knowledge/synapse/Wiki/{Schema}/Tables/{ObjectName}.alter.sql
knowledge/synapse/Wiki/{Schema}/Views/{ObjectName}.alter.sql
knowledge/synapse/Wiki/{Schema}/Functions/{ObjectName}.alter.sql
knowledge/synapse/Wiki/{Schema}/_deploy-index.md
knowledge/synapse/Wiki/{Schema}/_alter_generation_report.md
```

---

## 10. Error Recovery

| Issue | Solution |
|-------|----------|
| Wiki missing UC Target property | Mark Failed — "No UC target in wiki". Object needs re-run of build-wiki-dwh |
| UC Target is `_Pending`, Databricks available | Resolve via Step 2b bulk query. If 0 rows → mark "No UC table exists" |
| UC Target is `_Pending`, Databricks unavailable | Skip — "UC target pending, Databricks unavailable". Retry when MCP connected |
| Wiki file missing tier suffixes | Flag as non-compliant, skip object, mark Failed in deploy-index |
| Wiki file not found | Skip object, mark Failed |
| PII masked dual target | Generate ALTER sections for BOTH `dwh.*_masked` and `pii_data.*` targets in one `.alter.sql` file |
