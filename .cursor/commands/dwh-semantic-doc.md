---
description: Generate semantic documentation for Synapse DWH objects using phased analysis with live data, relationship discovery, production lineage tracing, and query advisory generation
---

# DWH Semantic Documentation (Query Brain)

**Spec Reference**: `/.specify/specs/003-synapse-knowledge/spec.md`
**Config Reference**: `/.specify/Configs/dwh-semantic-doc-config.json`
**Upstream Knowledge**: Configured in the config file under `upstream_knowledge_sources` — read-only references to previously generated semantic wikis for production schemas.

## Purpose

Generate comprehensive, analyst-facing semantic documentation for Synapse DWH objects by combining metadata analysis, live data sampling, relationship discovery, ETL logic extraction, production lineage tracing, Atlassian knowledge validation, and query advisory generation. The output enables an AI assistant to answer analyst queries with expert-level understanding.

## User Input

```text
$ARGUMENTS
```

---

## Step 0: Pre-Flight MCP Connection Check (MANDATORY)

**Before ANYTHING else, verify the Synapse MCP connection is working.**

### Check 1: Synapse MCP

Run a simple test query via the Synapse MCP connection:
```sql
SELECT 1 AS ConnectionTest
```
- If this returns `1` -> PASS
- If this fails -> **STOP IMMEDIATELY**:

> **BLOCKED: Synapse MCP is not connected.** Please check your MCP configuration (see `.cursor/skills/synapse-connection/SKILL.md`) and restart Cursor. No documentation will be generated.

### Check 2: Atlassian MCP

Run a test search:
```
search({ query: "test" })
```
- If this returns results (even empty) -> PASS
- If this returns ANY error -> **STOP IMMEDIATELY**:

> **BLOCKED: Atlassian MCP is not working.** Please re-authorize and restart Cursor. No documentation will be generated without Jira+Confluence knowledge.

### Check 3: Databricks / Unity Catalog Connection

Verify connectivity to Unity Catalog — required for ALTER script UC target validation:

**Option A — Databricks MCP** (preferred):
```sql
SELECT 1 AS ConnectionTest
```
via `user-databricks_sql-execute_sql_read_only`

**Option B — Python connector** (fallback if MCP errored):
```python
from databricks import sql
conn = sql.connect(
    server_hostname="adb-5142916747090026.6.azuredatabricks.net",
    http_path="/sql/1.0/warehouses/208214768b0e0308",
    auth_type="databricks-oauth"
)
cursor = conn.cursor()
cursor.execute("SELECT 1")
print(cursor.fetchone())
```

- If either returns `1` -> PASS — set `uc_available = true`
- If both fail -> **WARN** (not blocking, but ALTER script will use unvalidated UC target):

> **WARNING: Databricks/UC not available.** ALTER scripts will be generated with `-- UNVALIDATED UC TARGET` header. UC names are inferred, not verified — run the validation step separately once connectivity is restored.

### Check 4: Upstream Knowledge Sources

Read the config file (`/.specify/Configs/dwh-semantic-doc-config.json`) and for each entry in `upstream_knowledge_sources`, verify the wiki is accessible:
```
Read: {repo_path}/{wiki_path}/{index_file}
```
- If file exists -> PASS
- If not found -> **WARN** (not blocking, but lineage phases will be limited):

> **WARNING: Upstream knowledge source '{name}' not found at {repo_path}.** Production lineage tracing will be limited. Clone or pull the repository for full functionality.

### Check 5: Org Standards (Confluence — fetch ONCE per batch)

Fetch the org-level data layer rules from Confluence **once per batch run** (not per table). Cache the result for all subsequent phases.

```
getConfluencePage({ cloudId: "etoro-jira.atlassian.net", pageId: "13960052801", contentFormat: "markdown" })
```
- If this returns the page body -> PASS — cache as `org_standards` for use in Phase 11 (tag generation, naming validation)
- If this fails -> **WARN** (not blocking): Use hardcoded tag defaults from the speckit. Note in output that org standards were not refreshed.

The page defines mandatory tags (`owner`, `domain`, `layer`, `refresh_frequency`, `sla`, `source_system`, `pii`, `certified`), naming conventions (domain-first for `etoro_kpi`), and description requirements. Phase 11 uses this to ensure ALTER script tags comply with org standards.

**Gate: Checks 1 and 2 must PASS. Checks 3, 4, and 5 are advisory.**

---

## Step 1: Gather Scope

If `$ARGUMENTS` does not contain all required information, ask the user:

### Question 1: Documentation Scope

> **What scope of documentation?**
>
> 1. **Single Object** - Document one specific object (e.g., `DWH_dbo.Dim_Position`)
> 2. **Schema** - Document all objects in a schema (e.g., `DWH_dbo`)
> 3. **Enrich Existing Docs** - Run cross-object knowledge sync on existing docs

### Question 2: Object/Schema Name

Based on scope:
- **Single Object**: Ask for `[Schema].[ObjectName]`
- **Schema**: Ask for schema name
- **Enrich**: Skip to Phase 12

---

## Step 2: Resolve Object Details

For each object to document:

1. **Classify object type** by querying Synapse metadata:
   ```sql
   SELECT type_desc FROM sys.objects
   WHERE name = '{ObjectName}' AND SCHEMA_NAME(schema_id) = '{Schema}'
   ```

2. **Set output path**:
   - Tables: `knowledge/synapse/Wiki/{Schema}/Tables/{ObjectName}.md`
   - Views: `knowledge/synapse/Wiki/{Schema}/Views/{ObjectName}.md`
   - Stored Procedures: `knowledge/synapse/Wiki/{Schema}/Stored Procedures/{ObjectName}.md`
   - Functions: `knowledge/synapse/Wiki/{Schema}/Functions/{ObjectName}.md`

3. **Select pipeline** based on object type:
   - **Tables**: All phases (1-15)
   - **Views**: Phases 1, 2, 5, 7, 8, 10, 11, 14
   - **Stored Procedures**: Phases 1, 5, 8, 9, 10, 11
   - **Functions**: Phases 1, 2, 5, 7, 8, 10, 11

---

## Step 3: Initialize Phase Checklist

```markdown
## Documentation Checklist - [Schema].[ObjectName]
Started: [timestamp]
Object Type: [Table/View/Procedure/Function]

- [ ] Phase 1: Structure Analysis
- [ ] Phase 2: Live Data Sampling
- [ ] Phase 3: Distribution Analysis
- [ ] Phase 4: Lookup Resolution
- [ ] Phase 5: JOIN Analysis
- [ ] Phase 6: Business Logic Discovery
- [ ] Phase 7: View Dependency Scan
- [ ] Phase 8: Procedure Reference Scan
- [ ] Phase 9: Procedure Logic Extraction
- [ ] Phase 9B: ETL Orchestration Analysis
- [ ] Phase 10: Atlassian Knowledge Scan
- [ ] Phase 11: Documentation Generated
- [ ] Phase 12: Cross-Object Enrichment
- [ ] Phase 13: Production Lineage Mapping
- [ ] Phase 14: Query Advisory Metadata
- [ ] Phase 15: UC Lineage Injection

Status: 0/15
```

---

## Phase Execution

Execute ALL applicable phases sequentially. Each phase MUST load its rule file from `.cursor/rules/dwh-semantic-doc/`.

### Phase 1: Structure Analysis
**Load**: `.cursor/rules/dwh-semantic-doc/01-structure-analysis.mdc`

### Phase 2: Live Data Sampling
**Load**: `.cursor/rules/dwh-semantic-doc/02-live-data-sampling.mdc`
**Also Load**: `.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc`

### Phase 3: Distribution Analysis
**Load**: `.cursor/rules/dwh-semantic-doc/03-distribution-analysis.mdc`

### Phase 4: Lookup Resolution
**Load**: `.cursor/rules/dwh-semantic-doc/04-lookup-resolution.mdc`
**Also Load**: `.cursor/rules/dwh-semantic-doc/fk-lookup-reference.mdc`

### Phase 5: JOIN Analysis
**Load**: `.cursor/rules/dwh-semantic-doc/05-join-analysis.mdc`

### Phase 6: Business Logic Discovery
**Load**: `.cursor/rules/dwh-semantic-doc/06-business-logic-discovery.mdc`

### Phase 7: View Dependency Scan
**Load**: `.cursor/rules/dwh-semantic-doc/07-view-dependency-scan.mdc`

### Phase 8: Procedure Reference Scan
**Load**: `.cursor/rules/dwh-semantic-doc/08-procedure-reference-scan.mdc`

### Phase 9: Procedure Logic Extraction
**Load**: `.cursor/rules/dwh-semantic-doc/09-procedure-logic-extraction.mdc`

### Phase 9B: ETL Orchestration Analysis
**Load**: `.cursor/rules/dwh-semantic-doc/09b-etl-orchestration-analysis.mdc`

### Phase 10: Atlassian Knowledge Scan
**Load**: `.cursor/rules/dwh-semantic-doc/10-atlassian-knowledge-scan.mdc`

### Phase 11: Generate Documentation
**Load**: `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc`
**Also Load**: `.cursor/rules/dwh-semantic-doc/12-cross-object-enrichment.mdc` (Mechanism 1: Pre-Read)

Write MD file to: `knowledge/synapse/Wiki/{Schema}/{ObjectType}/{ObjectName}.md`

### Phase 12: Cross-Object Enrichment
**Load**: `.cursor/rules/dwh-semantic-doc/12-cross-object-enrichment.mdc`

### Phase 13: Production Lineage Mapping
**Load**: `.cursor/rules/dwh-semantic-doc/13-production-lineage-mapping.mdc`

### Phase 14: Query Advisory Metadata
**Load**: `.cursor/rules/dwh-semantic-doc/14-query-advisory-metadata.mdc`

### Phase 15: UC Lineage Injection
**Load**: `.cursor/rules/dwh-semantic-doc/15-uc-lineage-injection.mdc`
**Requires**: Databricks Python SDK (`databricks-sdk`), `CREATE EXTERNAL METADATA` privilege on metastore

---

## Verification Gate

```markdown
## Documentation Checklist - [Schema].[ObjectName]
Completed: [timestamp]

- [x] Phase 1: Structure Analysis
- [x] Phase 2: Live Data Sampling
- [x] Phase 3: Distribution Analysis
- [x] Phase 4: Lookup Resolution
- [x] Phase 5: JOIN Analysis
- [x] Phase 6: Business Logic Discovery
- [x] Phase 7: View Dependency Scan
- [x] Phase 8: Procedure Reference Scan
- [x] Phase 9: Procedure Logic Extraction
- [x] Phase 9B: ETL Orchestration Analysis
- [x] Phase 10: Atlassian Knowledge Scan
- [x] Phase 11: Documentation Generated
- [x] Phase 12: Cross-Object Enrichment
- [x] Phase 13: Production Lineage Mapping
- [x] Phase 14: Query Advisory Metadata
- [x] Phase 15: UC Lineage Injection

Status: COMPLETE
```

---

## Error Recovery

| Issue | Solution |
|-------|----------|
| Synapse query timeout | Skip query, note "Large table - query timed out", try smaller scope |
| Table not found | Document from metadata only |
| No lookup table in Synapse | Fall back to upstream production wiki |
| Upstream knowledge source missing | Skip lineage phases, warn user |
| Synapse MCP not connected | **STOP** - No docs generated |
| Atlassian MCP error | **STOP** - No docs generated |
| sys.sql_modules returns NULL | Object may be external table or encrypted -- note and continue |
