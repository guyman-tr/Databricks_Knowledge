# generate-alter-dwh-batch

You are running the ALTER script generation pipeline for a Synapse DWH schema.
This runs AFTER wiki documentation is complete and reviewed.

## Instructions

1. **Load rules** -- Read the following files IN ORDER before doing anything else:
   - `.cursor/rules/semantic-layer-core/deploy-index-management.mdc`
   - `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc`
   - `.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc`

2. **Detect schema** -- Determine which schema to process:
   - Check which `_index.md` files exist under `knowledge/synapse/Wiki/`.
   - For each schema with an `_index.md`, check if there are `Done` wiki objects that do NOT yet have a corresponding `.alter.sql` file.
   - Process the schema with the most unprocessed Done objects.

3. **Generate ALTER scripts** -- Use the batch engine:
   ```bash
   python "knowledge/synapse/Wiki/_batch_generate_lib.py" {schema_name}
   ```
   This handles UC target resolution, PII detection, and ALTER script generation in one pass.

4. **Run parity check** -- After generation, verify wiki/ALTER alignment:
   ```bash
   python tools/audit_wiki_alter_comment_parity.py --under {schema_name}
   ```
   Fix any mismatches before marking complete.

5. **Update deploy index** -- Create or update `_deploy-index.md` per `deploy-index-management.mdc`.

6. **Print summary and STOP**.

## Key resources

- **Wiki files**: `knowledge/synapse/Wiki/{Schema}/Tables/*.md`, `Views/*.md`, `Functions/*.md`
- **Batch engine**: `knowledge/synapse/Wiki/_batch_generate_lib.py`
- **Parity audit**: `tools/audit_wiki_alter_comment_parity.py`
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC target resolution)
