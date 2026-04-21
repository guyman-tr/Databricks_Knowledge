# build-wiki-dwh-batch

You are running the DWH Semantic Documentation pipeline for a Synapse DWH schema.
**Wiki-only mode** — generate documentation files only. ALTER scripts are generated separately later via `/generate-alter-dwh`.

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

2. **Use the schema** specified in the "Schema argument" section at the bottom of this prompt. Do NOT process objects from other schemas.

3. **Plan batch** -- Read `knowledge/synapse/Wiki/{Schema}/_index.md`. Find all objects with status "Pending". Pick the next batch per batch-orchestration rules (use schema-specific batch size from BATCH_SIZE_OVERRIDES). Cross-schema dependencies are NOT documentation targets -- they are read-only context sources (Tier 4).

4. **Execute pipeline** -- For each object in the batch, run the full pipeline as defined in the execution card (Phases 1 through 11, then Phase 16 adversarial evaluation). Load phase-specific rules on demand. Generate THREE files per object:
   - `.lineage.md` (column lineage -- written first by Phase 10B)
   - `.md` (main wiki)
   - `.review-needed.md` (review sidecar)

   **Do NOT generate `.alter.sql` files.** ALTER scripts are created in a separate pass via `/generate-alter-dwh` after wiki quality is reviewed and approved.

   After writing all 3 files:
   - Verify cross-object consistency: for every column with lineage to a production source that is ALSO documented in an existing wiki (especially DWH_dbo dimension tables like Dim_Position, Dim_Customer, Dim_Mirror), the description and tier MUST match verbatim. Same source = same description. No paraphrasing.
   - Do NOT proceed to the next object until all checks pass.
   - Then run Phase 16 (adversarial evaluation). If evaluator scores < 7.5, re-run Phase 11 with feedback (max 1 retry).

5. **Finalize** -- After completing all objects:
   - Bulk-update `_index.md` with results
   - Write `_batch_context.json` for cross-batch knowledge
   - Print the end-of-batch banner
   - **STOP** -- do not start the next batch (ONE BATCH PER SESSION rule)

## Key resources

- **SSDT DDL files**: `C:\Users\guyman\Documents\github\DataPlatform\` (repo-first for structure)
- **Upstream wikis (dynamic)**: Load `knowledge/synapse/Wiki/_upstream_wiki_routing.json` for Tier 1 repo locations. Includes DB_Schema, ExperianceDBs, CryptoDBs, BankingDBs, ComplianceDBs, PaymentsDBs and more.
- **DWH upstream wikis**: `knowledge/synapse/Wiki/DWH_dbo/` (for cross-schema references)
- **Dependency graph**: `knowledge/synapse/Wiki/_dependency_order.json`
- **Generic pipeline mapping**: `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`
- **MCP Synapse**: `mcp__synapse_sql__execute_sql_read_only` (live data sampling, distribution)
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC metadata verification)

## Batch size reference

| Schema | Batch Size |
|--------|-----------|
| DWH_dbo | 4 |
| BI_DB_dbo | 3 |
| Dealing_dbo | 4 |
| EXW_dbo | 3 |
| eMoney_dbo | 4 |
| Default | 3 |
