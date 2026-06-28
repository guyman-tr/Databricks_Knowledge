# Databricks_Knowledge

Private knowledge/documentation repo for eToro's data platform. It generates and maintains
**semantic documentation / wikis** for Synapse DWH and Unity Catalog (UC) objects, plus the
tooling, lineage, and ALTER scripts that go with them.

## What's here

- `knowledge/` — generated wiki output: per-object `.md`, `.lineage.md`, `.review-needed.md`,
  `.status.json`, and `.alter.sql` files (Synapse DWH + UC `*_output` schemas).
- `tools/` — Python helpers (e.g. `dbx_query.py` for Databricks SQL, lineage/propagation scripts).
- `Data_Skills_Automation/`, `apps/` — watchers and skill-suggestion apps.
- `.claude/commands/` — slash commands (migrated from `.cursor/commands/`).
- Skills live **globally** in `~/.claude/skills/` (not in this repo): `dwh-semantic-doc`,
  `uc-pipeline-doc`, `uc-domain-doc`, `semantic-layer-core`, plus task skills like
  `skills-push`, `uc-deploy-comments`, `wiki-review`, etc.

## Tech stack

- **Python 3.11** — `databricks-sql-connector`, `databricks-sdk`.
- **PowerShell 5.1** — pipeline orchestration.
- **MCP servers** (configured globally in `~/.claude/settings.json`): `synapse_sql`,
  `synapse_prod_sql`, `databricks_sql`, `opsdb_sql`; plus the `dataplatform` HTTP MCP and Atlassian MCP.
- Spec-driven development (spec-kit) — see `.claude/commands/speckit.*`.

## Workflows

The numbered documentation pipelines are now Claude Code **skills** (progressive disclosure —
an execution card stays loaded, phase rules load on demand):

- **`dwh-semantic-doc`** — Synapse/DWH object documentation (structure → sampling → lineage →
  tiers → UC deploy).
- **`uc-pipeline-doc`** — pure-UC pipeline object documentation.
- **`uc-domain-doc`** — UC domain-level documentation.
- **`semantic-layer-core`** — shared conventions (repo-first access, batch orchestration,
  context handoff, index/deploy management).

---

## Always-on rules

### MCP Latency Signal (NON-NEGOTIABLE)

Live DB tools (Synapse/Databricks MCP) can hang for minutes. The user must always know when one is in use.

1. **Before the first MCP tool call** in a reply (or before a batch of MCP calls for one request),
   output a short explicit line, e.g. *"Running a live query via Databricks MCP — if nothing follows
   in ~10–15s, check Settings → MCP (server may be disconnected)."* Same for `synapse_sql` /
   `synapse_prod_sql`.
2. **If an MCP tool errors** (missing tool, timeout, connection failure), in the **same turn** tell
   the user to open the MCP/Tools panel and confirm the server is green — don't just retry silently.
3. **Don't** chain many sequential MCP SQL calls without a one-line progress note between steps, or
   switch to a single Python `databricks.sql` / batch script for heavy work.
4. **Databricks MCP failures:** after **one** failed/missing `databricks_sql` call, run
   `python tools/dbx_query.py "<sql>"` from this repo via shell (same auth as MCP). Don't loop on MCP alone.
5. For long-running statements returning `statement_id`, use `poll_sql_result` if available, else `dbx_query.py`.

### Constitution IX: Repo First, MCP Second (NON-NEGOTIABLE)

**NEVER seek from the database what you can get from the repo.**

- The DataPlatform SSDT repo (`DataPlatform\SynapseSQLPool1\sql_dp_prod_we\`) has ALL DDLs for
  Synapse objects (tables, SPs, views for `DWH_dbo`).
- The DB_Schema SSDT repo has ALL production DDLs and upstream wikis.
- Synapse MCP is **ONLY** for live data queries (`SELECT TOP N`, `COUNT(*)`, `GROUP BY`).
- Full enforcement table: load the **`semantic-layer-core`** skill (`repo-first-access` reference).

---

## ⚠️ DataPlatform is production — read-only by default

`..\DataPlatform` is the production DE repo. Do **not** write to it as a side effect of work here.
Changes to DataPlatform must be explicitly requested and land via the **`skills-push`** skill (opens a PR).
See `~/.claude/CLAUDE.md` for the full guardrail.
