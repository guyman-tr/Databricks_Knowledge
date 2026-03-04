# Data Knowledge Platform

AI-driven semantic documentation for the Synapse DWH layer. A 14-phase Cursor Agent pipeline that reads table structures, samples live data, traces ETL stored procedures, searches Atlassian, and produces analyst-ready wiki documentation — then lets domain experts interactively review and correct the output.

## Workspace Setup

This repo is designed to run inside **Cursor IDE**. The agent rules (`.cursor/rules/`) and skills (`.cursor/skills/`) drive the pipeline — there is no standalone CLI.

### Required Workspace Folders

Open a **multi-root workspace** in Cursor with these three repos:

| Folder | Repo | Purpose |
|--------|------|---------|
| `Databricks_Knowledge` | This repo | Pipeline rules, knowledge output, glossary |
| `DB_Schema` | Production SSDT repo | Upstream semantic wikis, DDL files, FK references |
| `DataPlatform/SynapseSQLPool1` | Synapse Dataplatform repo | SP, view, function, and table definitions for the DWH layer |

The pipeline reads SP/view code directly from `DataPlatform` files (repo-first, DB-fallback). It also inherits upstream column descriptions from `DB_Schema` wiki files. Without these folders in the workspace, the agent will fall back to querying `sys.sql_modules` — which works but gives less context and may be behind the latest committed code.

### Required MCP Servers

Two MCP servers must be configured in Cursor (`.cursor/mcp.json` or global settings):

| MCP Server | Purpose | Used By |
|------------|---------|---------|
| `synapse_sql` | Query the Synapse DWH (read-only sampling, metadata, distributions) | Phases 1–3, 5, 13–14 |
| `databricks_sql` | Query Databricks Unity Catalog (future lineage sync) | Downstream phases |

The `synapse_sql` MCP should point at the **staging Synapse pool** (`sql_dp_stg_we_BI_no_retention`) to avoid impacting production workloads.

> **Alternative:** If MCP is unavailable, the repo includes `synapse_connect.py` for direct `pyodbc` connections with Azure AD interactive auth. The pipeline rules reference MCP by default.

### Atlassian Integration

Phase 10 (Atlassian Knowledge Scan) uses the Cursor Atlassian plugin to search Jira and Confluence for business context. This requires being logged in to Atlassian through Cursor's built-in integration. No separate MCP needed.

## Pipeline Overview

The pipeline is encoded as Cursor Agent rules in `.cursor/rules/dwh-semantic-doc/`. To document a table, run the `dwh-semantic-doc` command (or ask the agent to run all phases on a target table).

### Phases

| # | Phase | Mode | Description |
|---|-------|------|-------------|
| 1 | Structure Analysis | Auto (MCP) | Column types, nullability, keys from `INFORMATION_SCHEMA` |
| 2 | Live Data Sampling | Auto (MCP) | `TOP 100` sample + NULL/distinct counts |
| 3 | Distribution Analysis | Auto (MCP) | Value frequencies, enum detection, Synapse distribution strategy |
| 4 | Lookup Resolution | Auto (Repo + MCP) | Resolve `*ID` columns to `Dim_*` / `Dictionary_*` tables |
| 5 | JOIN Analysis | Auto (Repo) | Trace JOINs in SPs/views to discover implicit relationships |
| 6 | Business Logic Discovery | Auto | Column groups, hierarchies, flag semantics |
| 7 | View Dependency Scan | Auto (Repo) | Map all views referencing the table |
| 8 | Procedure Reference Scan | Auto (Repo) | Find all SPs that read/write the table |
| 9 | Procedure Logic Extraction | Auto (Repo) | Deep-read top 10 SPs for column assignments and business rules |
| 9B | ETL Orchestration Analysis | Auto (Repo) | Refresh schedules, SP execution order, ETL dependencies |
| 10 | Atlassian Knowledge Scan | Auto (Atlassian) | Search Jira/Confluence for business context |
| 11 | Generate Documentation | Auto | Produce the wiki `.md` + mandatory `.review-needed.md` sidecar |
| 12 | Cross-Object Enrichment | Auto | Sync shared columns with previously documented tables |
| 13 | Production Lineage Mapping | Auto | Trace back to production sources via Generic Pipeline / ETL SPs |
| 14 | Query Advisory Metadata | Auto | Distribution keys, recommended query patterns, freshness notes |
| — | **Interactive Review** | **Human** | Domain expert walks through flagged items, corrects, approves, dismisses |

### Interactive Review

After the pipeline completes, use the **wiki-review** skill:

- `"review Fact_CustomerAction"` — walks through all flagged items one by one
- `"correct HistoryID"` — fix a single column
- `"approve IsReal"` — promote to Tier 5 (domain-confirmed)
- `"dismiss IsPlug"` — mark as deprecated/not applicable

Corrections are written to both the wiki and the `.review-needed.md` sidecar, and domain terms are added to `knowledge/glossary.md`.

## Output Structure

```
knowledge/
├── glossary.md                          # Cross-table domain terms (Tier 5)
├── canonical-schema.md                  # Standard output schema
├── dwh-semantic-doc-presentation.md     # Process overview (NotebookLM deck source)
└── synapse/
    └── Wiki/
        └── DWH_dbo/
            └── Tables/
                ├── DWH_dbo.Dim_Position.md                # Wiki documentation
                ├── DWH_dbo.Dim_Position.review-needed.md  # Review sidecar
                ├── DWH_dbo.Dim_Position.alter.sql         # ★ Databricks ALTER script
                ├── DWH_dbo.Fact_CustomerAction.md
                ├── DWH_dbo.Fact_CustomerAction.review-needed.md
                └── DWH_dbo.Fact_CustomerAction.alter.sql  # ★ Databricks ALTER script
```

Each documented table produces **three files**:
- **Databricks ALTER script (`.alter.sql`)** — **THE primary output.** Contains `ALTER TABLE ... SET TBLPROPERTIES` and `ALTER COLUMN ... COMMENT` statements ready to execute against Unity Catalog. Every description fits within UC's 1024-character limit. This is the metadata that powers the Databricks AI assistant.
- **Wiki (`.md`)** — Full semantic documentation: tagline, column descriptions with confidence tiers, relationships, common JOINs, business logic, gotchas, and query patterns. Intermediate artifact that feeds the ALTER script.
- **Review sidecar (`.review-needed.md`)** — Tracks unverified items, reviewer corrections, and open questions. Persists across reruns so domain expert feedback is never lost.

## Confidence Tiers

Every column description carries a confidence tier:

| Tier | Source | Authority |
|------|--------|-----------|
| 5 | Domain expert / reviewer correction | Absolute — overrides everything |
| 1 | Upstream wiki (verbatim from DB_Schema) | Highest — already code-validated |
| 2 | Synapse SP code / CASE patterns | High — direct code evidence |
| 3 | Live data distribution analysis | Medium — empirical but context-free |
| 4 | Column name inference | Low — flagged `[UNVERIFIED]` |

## Utility Scripts

| Script | Purpose |
|--------|---------|
| `synapse_connect.py` | Reusable pyodbc connection with Azure AD auth (WAM + device code fallback) |
| `synapse_queries.py` | Batch query runner for multi-phase data collection |
| `phase*.py` | One-off scratch scripts from development runs (not part of the pipeline) |
