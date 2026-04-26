# build-wiki-bidb-batch

You are running the DWH Semantic Documentation pipeline for schema BI_DB_dbo.
**Wiki-only mode** — generate documentation files only. ALTER scripts are generated separately later via `/generate-alter-dwh`.

## ⛔ MCP PRE-FLIGHT — NON-NEGOTIABLE, CHECK BEFORE ANYTHING ELSE

Before loading rules, before reading the index, before planning anything:

1. **Test Synapse MCP**: Call `mcp__synapse_sql__execute_sql_read_only` with `SELECT 1 AS mcp_preflight`
2. **If it fails or the tool does not exist**: Print `BATCH ABORT: Synapse MCP unavailable` and **EXIT IMMEDIATELY**. Do NOT proceed. Do NOT fall back to "prior batch context data". Do NOT use a "schema practice" of skipping MCP. A wiki without live data sampling is INCOMPLETE and WILL NOT PASS the adversarial evaluator. STOP HERE.
3. **If it succeeds**: Print `MCP PRE-FLIGHT: PASS` and continue to Instructions.

There is NO exception to this rule. No "prior context", no "code-only documentation", no "graceful degradation". MCP down = batch aborted. Period.

---

## Instructions

1. **Load rules** -- Read the following files IN ORDER before doing anything else:
   - `.cursor/rules/semantic-layer-core/repo-first-access.mdc`
   - `.cursor/rules/semantic-layer-core/index-management.mdc`
   - `.cursor/rules/semantic-layer-core/batch-orchestration.mdc`
   - `.cursor/rules/semantic-layer-core/context-handoff.mdc`
   - `.cursor/rules/dwh-semantic-doc/00-execution-card.mdc`
   - `.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc`
   - `.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`
   - `.cursor/rules/dwh-semantic-doc/10.5b-tier1-enforcement.mdc`
   - `.cursor/rules/dwh-semantic-doc/16-adversarial-evaluation.mdc`

2. **Plan batch** -- Read `knowledge/synapse/Wiki/BI_DB_dbo/_index.md`. Read `.specify/Configs/dwh-semantic-doc-config.json` and check `object_blacklist.explicit_blacklist` and `object_blacklist.name_patterns` — any object matching the blacklist is **PERMANENTLY SKIPPED**, regardless of priority, batch context plans, or dependency pull-forward. If `knowledge/synapse/Wiki/BI_DB_dbo/_parity_gate_last_run.txt` exists and starts with `STATUS=FAIL`, **prioritize** fixing wiki/ALTER COMMENT parity (see `_parity_last_report.json` and `python tools/audit_wiki_alter_comment_parity.py --under BI_DB_dbo`) before taking new Pending objects. Then find all objects with status "Pending". Pick the next batch per batch-orchestration rules:
   - **Default batch size = 8 for BI_DB_dbo** (was 4 — doubled to amortize per-batch fixed-overhead tax of ~50K tokens for re-reading 9 rule files + index + config).
   - **Weighted exception**: if ANY object in the candidate batch has > 50 columns, cap batch at 4 (heavy objects need more per-object reasoning budget).
   - **Weighted exception**: if the candidate batch contains a writer-SP-shared cluster (3+ objects refreshed by the same SP), keep them in one batch even if it pushes >8.

3. **Execute pipeline** -- For each object in the batch, run the full pipeline as defined in the execution card (Phases 1 through 11, then Phase 16 adversarial evaluation). Load phase-specific rules on demand. Generate THREE files per object:
   - `.lineage.md` (column lineage -- written first by Phase 10B)
   - `.md` (main wiki)
   - `.review-needed.md` (review sidecar)

   **Do NOT generate `.alter.sql` files.** ALTER scripts are created in a separate pass via `/generate-alter-dwh` after wiki quality is reviewed and approved.

   After writing all 3 files:
   - Verify cross-object consistency: for every column with lineage to a production source that is ALSO documented in an existing wiki (especially DWH_dbo dimension tables like Dim_Position, Dim_Customer, Dim_Mirror), the description and tier MUST match verbatim. Same source = same description. No paraphrasing.
   - Do NOT proceed to the next object until all checks pass.
   - Then run Phase 16 (adversarial evaluation). If evaluator scores < 7.5, re-run Phase 11 with feedback (max 1 retry).

4. **Finalize** -- After completing all objects:
   - Bulk-update `_index.md` with results
   - Write `_batch_context.json` for cross-batch knowledge
   - Print the end-of-batch banner
   - **STOP** -- do not start the next batch (ONE BATCH PER SESSION rule)

## Key resources

- **SSDT DDL files**: `C:\Users\guyman\Documents\github\DataPlatform\` (repo-first for structure)
- **Upstream wikis (dynamic)**: Load `knowledge/synapse/Wiki/_upstream_wiki_routing.json` for Tier 1 repo locations. Includes DB_Schema, ExperianceDBs, CryptoDBs, BankingDBs, ComplianceDBs, PaymentsDBs and more.
- **DWH upstream wikis**: `knowledge/synapse/Wiki/DWH_dbo/` (for cross-schema references)
- **OpsDB priority file**: `.specify/Configs/opsdb-objects-status.json`
- **OpsDB dependencies**: `.specify/Configs/opsdb-procedure-dependencies.json`
- **Generic pipeline mapping**: `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`
- **MCP Synapse**: `mcp__synapse_sql__execute_sql_read_only` (live data sampling, distribution)
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC metadata verification)

## Schema argument

Schema: BI_DB_dbo
