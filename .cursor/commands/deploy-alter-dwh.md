---
description: Execute generated ALTER scripts against Unity Catalog. Deploys table comments, column comments, tags, and PII metadata. Self-only — no downstream propagation.
---

# Deploy ALTER Scripts — DWH (Execute to Unity Catalog)

**Config Reference**: `/.specify/Configs/dwh-semantic-doc-config.json`
**Prerequisite**: Run `generate-alter-dwh` first to create `.alter.sql` files.

## Purpose

Execute previously generated `.alter.sql` scripts against Databricks Unity Catalog. Each script is executed via a single authenticated Python session (NOT individual MCP calls — that would open hundreds of browser tabs).

**Self-only deployment.** Each object's ALTER script writes only to its own UC target table. No downstream column propagation — that's handled separately by `propagate-downstream-dwh`.

---

## 1. Command Overview & Arguments

### Invocation

```text
/deploy-alter-dwh {schema_name} [single_object_name | status | resume | dry-run]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `schema_name` | Yes | Schema to deploy (e.g., `Dealing_dbo`) |
| `single_object_name` | No | Single object — deploy one ALTER script only |
| `status` | No | Read-only: show deployment progress from `_deploy-index.md` |
| `resume` | No | Continue from last deploy batch (skip already Deployed objects) |
| `dry-run` | No | Validate ALTER scripts without executing — check UC targets exist, columns match |

### Scope Detection

- **Second arg is a name** → Single-object mode
- **Second arg is `status`** → Status mode (read-only)
- **Second arg is `resume`** → Resume mode
- **Second arg is `dry-run`** → Validation mode (no writes)
- **Second arg absent** → Schema mode (deploy all **`Generated`** objects per `_deploy-index.md` — **not** `Stub only`, not `Pending`)

---

## 2. Pre-Flight Checks

| Check | Source | Required | Note |
|-------|--------|----------|------|
| Databricks MCP | MCP connection | **MANDATORY** | UC deployment target. **STOP** if unavailable |
| `.alter.sql` files | Local filesystem | **MANDATORY** | Must exist — run `generate-alter-dwh` first |
| `_deploy-index.md` | Local filesystem | **MANDATORY** | Tracks deployment status |

### Check 1: Databricks MCP

Run `SELECT 1 AS ConnectionTest` via `user-databricks_sql-execute_sql_read_only`. If it fails → **STOP**: "Databricks MCP unavailable. Deployment cannot proceed."

### Check 2: ALTER Scripts Exist

For schema mode: scan `Tables/*.alter.sql`, `Views/*.alter.sql`, and **`Functions/*.alter.sql`**. If **zero executable** scripts (see below) → **STOP**: "No ALTER scripts found. Run `/generate-alter-dwh {Schema}` first."

**Comment-only stubs (BI_DB `Functions/`, `_Not_Migrated`)**: Files whose body has **no** lines starting with `ALTER TABLE` / `ALTER VIEW` (after stripping comments) are **skipped** for UC execution — they still satisfy "ALTER file exists" for repo completeness but must **not** be passed to `DESCRIBE TABLE` or `cursor.execute`.

### Check 3: Deploy Index

Verify `_deploy-index.md` exists. If missing → **STOP** with explicit operator text: "`_deploy-index.md` missing — run `python tools/build_deploy_index.py --schema {Schema}` to CREATE the deploy index, then resume deploy." Do not deploy batches without updating the index in the same session once the file exists.

### Check 3b: ALTER script sanity (regression guard — spec FR-012–FR-015)

Before large batches, spot-check or run:

`python tools/audit_alter_uc_mapping.py knowledge/synapse/Wiki/{Schema}` (pass the **schema folder**; see tool help).

The audit flags: invalid `ALTER TABLE` targets, **bogus `ALTER COLUMN Tier N` lines**, and **`ALTER COLUMN Col/Name` without backticks**. These caused 2026-03-30 UC deploy failures; see `.specify/specs/003-synapse-knowledge/spec.md` Session 2026-03-30. A full-repo audit may still hit legacy Dealing_dbo files — **gate the schema you deploy**.

### Check 3c: Wiki ↔ ALTER **comment** parity (semantic)

Wrong `COMMENT` text (column-order bugs, drift vs wiki) does not show up in `audit_alter_uc_mapping.py`. Before large deploys, run:

`python tools/audit_wiki_alter_comment_parity.py --under {schema_name}`

Non-zero = Elements vs `ALTER COLUMN ... COMMENT` mismatch — fix wiki or `.alter.sql` per `.cursor/commands/generate-alter-dwh.md` Check 3 and `batch-orchestration.mdc`.

### Check 4: End-of-Run Reporting

Per **`deploy-index-management.mdc` Protocol 6**: every deploy run MUST print a summary that states **Created / Updated / Missing** for `_deploy-index.md`, counts (Deployed / Failed / Skipped stub), and **next step**.

---

## 3. Execution Strategy — Single-Session Python Script

**CRITICAL: DO NOT execute ALTER statements via individual MCP tool calls.** Each MCP call triggers an OAuth handshake that opens a browser tab. For a schema with 200+ objects, that's thousands of browser tabs.

Instead, generate a **temporary Python deployment script** per batch that:

1. Reads the Databricks connection config (host, HTTP path, token/OAuth)
2. Opens ONE `databricks.sql.connect()` session
3. Reads each `.alter.sql` file in the batch
4. Extracts executable statements (skip comment-only lines)
5. Executes each statement sequentially via `cursor.execute(stmt)`
6. Logs success/failure per statement, continues on error
7. Appends a `-- == LAST EXECUTION ==` footer to each `.alter.sql` with timestamp and results
8. Prints a structured execution summary

### Connection Config

Read the Databricks connection skill at `C:\Users\guyman\.cursor\skills\databricks-connection\SKILL.md` for host, HTTP path, and auth method.

### Batch Sizing

- Default: 25 objects per Python script execution
- Each ALTER script has ~N+3 statements (1 table comment + 1 tags + N column comments + N PII tags)
- Expect ~1 minute per 100 statements

---

## 4. Per-Object Flow

For each object:

1. **Read** `{ObjectName}.alter.sql`
2. **Validate** UC target is accessible: `DESCRIBE TABLE {uc_target}` — if it fails, skip and mark Failed
3. **Execute** all ALTER statements sequentially
4. **Record** results: succeeded/failed counts, error details
5. **Update** `_deploy-index.md`: status → `Deployed` (or `Failed` with reason)
6. **Generate** `{ObjectName}.deploy-report.md` with execution summary

### Deploy Report

Each deployed object gets a `.deploy-report.md` (11W Section 13 template):

| Section | Content |
|---------|---------|
| 1. Object Summary | Synapse object, UC target, columns documented, quality score |
| 2. Output Files | List of all generated/deployed files |
| 3. ALTER Execution | Table with succeeded/total counts per component |
| 5. Failures | Per-column failure details (if any) |

**Section 4 (Downstream) is intentionally empty** — downstream propagation is a separate command.

---

## 5. Schema Mode — Batch Processing

### Flow

1. Load `_deploy-index.md`
2. Filter to objects with status `Generated` (from `generate-alter-dwh`)
3. Order by dependency depth (from `_dependency_order.json` if available)
4. Generate temporary Python deployment script for the batch
5. Execute via Shell tool with appropriate `block_until_ms`
6. Parse terminal output for results
7. Update `_deploy-index.md` for each object
8. Delete the temporary Python script
9. Print end-of-batch summary

---

## 6. Dry-Run Mode

When argument is `dry-run`:

1. For each Generated object:
   - Verify UC target exists (`DESCRIBE TABLE`)
   - Verify columns match between ALTER script and UC table
   - Report mismatches (dropped columns, renamed columns, UC-only columns)
2. No ALTER statements executed
3. Output: validation report with pass/fail per object

---

## 7. Status Mode

When argument is `status`:

1. Read `_deploy-index.md` via `deploy-index-management.mdc` Protocol 3
2. Display: objects Deployed/Generated/Pending/Failed
3. No file modifications

---

## 8. Resume Mode

When argument is `resume`:

1. Load `_deploy-index.md`
2. Find objects with status `Generated` (not yet Deployed)
3. Continue from where last batch stopped
4. Same execution flow as Schema mode

---

## 9. Output Files Per Object

| File | Description |
|------|-------------|
| `{ObjectName}.alter.sql` | Updated with `-- == LAST EXECUTION ==` footer |
| `{ObjectName}.deploy-report.md` | Deployment execution summary |

---

## 10. Idempotency

All ALTER statements are idempotent — re-executing sets the same comment/tag value. No harm in re-running. The pipeline re-applies everything to ensure latest descriptions are live.

---

## 11. Rule File References

```
.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc  (Section 12: ALTER Execution)
.cursor/rules/semantic-layer-core/deploy-index-management.mdc
.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc
```

---

## Error Recovery

| Issue | Solution |
|-------|----------|
| Databricks MCP unavailable | **STOP** — deployment cannot proceed |
| UC target not found | Mark as Failed in `_deploy-index.md`, continue to next object |
| Column not found in UC | Log in deploy report, skip column, continue |
| Permission denied | Log error, mark object as Failed, continue |
| Mid-batch crash | Run `/deploy-alter-dwh {Schema} resume` |
| OAuth browser tab | Expected: ONE tab for the Python script session. If multiple → something is wrong, kill and retry |
