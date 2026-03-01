# Quickstart: Data Knowledge Platform

## Prerequisites

1. **Cursor IDE** with MCP connections configured:
   - `synapse_sql` — Azure Synapse Analytics (read-only queries)
   - `databricks_sql` — Databricks Unity Catalog
   - Atlassian MCP — Jira/Confluence access

2. **Local repos cloned**:
   - `Databricks_Knowledge` (this repo)
   - `DB_Schema` (upstream production wiki source)

3. **Config**: Verify `.specify/Configs/dwh-semantic-doc-config.json` has correct paths to upstream wiki sources

## POC: Document One Synapse Table

### Step 1: Run the pipeline on Dim_Position

```
/dwh-semantic-doc DWH_dbo.Dim_Position
```

This executes all 14 phases and produces `knowledge/synapse/Wiki/DWH_dbo/Dim_Position.md`.

### Step 2: Verify output

- Check that all `*ID` columns have resolved lookup values
- Check that lineage traces back to `Trade.PositionTbl` in the upstream wiki
- Check that the Query Advisory section has practical examples

### Step 3: Test with AI

Ask the Databricks AI assistant:
- "What does StatusID=2 mean in Dim_Position?"
- "How should I query open positions?"
- "Where does Dim_Position data come from?"

## Spec Execution Order

```
001 → 002 → 003 → 004 → 005 → 006 → 007
```

Each spec's output lives under `knowledge/`. See `plan.md` for the full dependency graph.
