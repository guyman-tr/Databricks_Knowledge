# build-wiki-bidb-batch

You are running the DWH Semantic Documentation pipeline for schema BI_DB_dbo.

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

2. **Plan batch** -- Read `knowledge/synapse/Wiki/BI_DB_dbo/_index.md`. Find all objects with status "Pending". Pick the next batch per batch-orchestration rules (up to DEFAULT_BATCH_SIZE objects, ordered by priority).

3. **Execute pipeline** -- For each object in the batch, run the full pipeline as defined in the execution card (Phases 1 through 11, then Phase 16 adversarial evaluation). Load phase-specific rules on demand. Generate FOUR files per object (all mandatory):
   - `.lineage.md` (column lineage -- written first by Phase 10B)
   - `.md` (main wiki)
   - `.review-needed.md` (review sidecar)
   - `.alter.sql` (ALTER script with table comment + column comments + tags)
   After writing all 4 files:
   - Verify ALTER COLUMN count matches wiki element count.
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
- **Upstream wikis**: `C:\Users\guyman\Documents\github\DB_Schema\` and `knowledge/synapse/Wiki/DWH_dbo/`
- **OpsDB priority file**: `.specify/Configs/opsdb-objects-status.json`
- **MCP**: Synapse SQL is available via MCP tool `mcp__synapse_sql__execute_sql_read_only`
- **Atlassian**: Available via MCP tool `mcp__atlassian__*`

## Schema argument

Schema: BI_DB_dbo
