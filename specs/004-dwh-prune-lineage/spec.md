# Feature Specification: DWH Prune & Lineage Fix

**Feature Branch**: `004-dwh-prune-lineage`  
**Created**: 2026-03-16  
**Status**: Draft  
**Input**: Prune garbage/test/backup tables from DWH documentation scope and fix lineage to use the Generic Pipeline mapping view for authoritative production source tracing with Tier 1 column inheritance.

## Problem Statement

Two critical issues with the current DWH wiki build pipeline:

1. **No pruning**: The DWH_dbo schema has 379 objects, but ~85 of them are backups, test artifacts, partition fragments, replication checks, SWITCH staging tables, and developer experiments. Processing these wastes time and pollutes the knowledge base.

2. **Broken lineage**: All 38 documented objects have **zero Tier 1 columns**. The pipeline guesses production sources instead of looking them up in the Generic Pipeline mapping view (`main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables`). It also never reads the upstream production wikis in `DB_Schema/etoro/Wiki/` (526 documented tables) to inherit column descriptions. This means every column description is Tier 2 (guessed) or Tier 4 (unverified) when authoritative Tier 1 data is available.

### Root Cause Analysis

- **Pruning**: No blacklist mechanism exists. Every object in the SSDT repo or dependency graph is treated as a documentation target.

- **Lineage**: Phase 10A Step 1 (Generic Pipeline mapping view query) is explicitly skipped during wiki build with the comment "requires Databricks which is not available." But the Databricks MCP IS configured and available (`dwh-semantic-doc-config.json` → `lineage.generic_pipeline_mapping.mcp_tool: "databricks_sql"`). Phase 10A Step 3 (upstream wiki lookup) is also skipped, so production wiki column descriptions are never inherited.

## User Scenarios & Testing

### User Story 1 — Permanent Blacklist Prevents Junk Tables from Being Documented (Priority: P1)

As a data knowledge engineer, I need garbage tables (backups, tests, partition fragments, SWITCH staging, replication checks) permanently excluded from the documentation pipeline so batch slots are used only on real business tables.

**Why this priority**: Without this, every batch wastes 20-30% of its capacity on junk tables, and the wiki becomes cluttered with useless entries.

**Independent Test**: Run `/build-wiki-dwh DWH_dbo` after applying the blacklist. Verify that none of the 85 blacklisted tables appear in the batch plan or get queued. Verify `_index.md` shows them as `Blacklisted` and they are excluded from the `total_objects` count for progress percentage.

**Acceptance Scenarios**:

1. **Given** a blacklist file exists at `knowledge/synapse/Wiki/DWH_dbo/_blacklist.json`, **When** the pipeline runs batch planning, **Then** all blacklisted objects are excluded from batch segmentation and shown as `Blacklisted` in `_index.md`
2. **Given** a table is added to the blacklist after it was already documented, **When** the pipeline runs, **Then** the existing wiki files are not deleted but the table is excluded from future batches and enrichment
3. **Given** a table is removed from the blacklist, **When** the pipeline runs, **Then** it returns to `Pending` status and is included in future batch planning

---

### User Story 2 — Lineage Uses Generic Pipeline Mapping View (Priority: P1)

As a data knowledge engineer, I need every DWH table's production source identified via the Generic Pipeline mapping view, not guessed from column names.

**Why this priority**: This is the foundation for Tier 1 column inheritance. Without knowing the exact production source, we can't look up the upstream wiki.

**Independent Test**: Document `Dim_ActionType` with the fixed pipeline. Verify the lineage chain shows `etoro.Dictionary.ActionType` (from the mapping view), not "Dictionary.ActionType (inferred)". Verify the `.lineage.md` file contains `CopyStrategy: Override`, `FrequencyMinute: 1440`, `DatalakePath: Bronze/etoro/Dictionary/ActionType/`.

**Acceptance Scenarios**:

1. **Given** the Databricks MCP is available, **When** Phase 10A runs for a DWH table, **Then** the mapping view is queried to find the exact production source (DatabaseName, SchemaName, TableName)
2. **Given** the mapping view returns a match, **When** the lineage chain is built, **Then** it includes CopyStrategy, FrequencyMinute, DatalakePath, UnityCatalogTableName, and ServerName from the mapping view
3. **Given** the mapping view has no match for a table, **When** Phase 10A runs, **Then** it falls back to SP-code-based lineage (current behavior) and flags the table as "No Generic Pipeline match"

---

### User Story 3 — Column Descriptions Inherited from Upstream Production Wikis (Priority: P1)

As a data knowledge engineer, I need DWH column descriptions to inherit from the upstream production wiki (DB_Schema) when the columns are passthrough copies, so they get Tier 1 confidence instead of Tier 2 guesses.

**Why this priority**: This is the highest-value output of fixing lineage. Columns like `ActionTypeID` should carry the rich, code-backed description from the production wiki ("Primary key identifying the activity type. 0=NULL/Unknown, 1=Registration Real...") instead of a generic Tier 2 guess ("Action type identifier").

**Independent Test**: Document `Dim_ActionType` with the fixed pipeline. Verify that `ActionTypeID` and `Name` columns have Tier 1 descriptions inherited from `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ActionType.md`. The description should include the enum value map from the production wiki.

**Acceptance Scenarios**:

1. **Given** the mapping view identifies `etoro.Dictionary.ActionType` as the source, **When** Phase 10A Step 3 runs, **Then** it looks up `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ActionType.md` and reads the column descriptions
2. **Given** an upstream wiki exists and a DWH column is a passthrough (same name, same type), **When** Phase 11 generates the Elements table, **Then** the column description is inherited verbatim and tagged as `(Tier 1 — upstream wiki)`
3. **Given** a DWH column exists in the upstream wiki but has been renamed or transformed, **When** Phase 11 generates documentation, **Then** the description is adapted (not verbatim) and tagged as `(Tier 2 — adapted from upstream)`
4. **Given** no upstream wiki exists for the production source, **When** Phase 11 generates documentation, **Then** columns fall back to Tier 2/Tier 4 as before

---

### User Story 4 — Re-Document Existing Objects with Fixed Lineage (Priority: P2)

As a data knowledge engineer, I need to regenerate the 38 already-documented objects using the fixed lineage pipeline so they benefit from Tier 1 column descriptions.

**Why this priority**: The existing docs are all Tier 2/4. Once the lineage fix is in place, they should be regenerated.

**Independent Test**: Run `/build-wiki-dwh DWH_dbo` with the staleness override (force regeneration). Verify that previously Tier 2 columns now show Tier 1 where upstream wiki data exists.

**Acceptance Scenarios**:

1. **Given** objects have status `Done` in `_index.md`, **When** the operator runs with a force-regenerate flag or resets objects to Pending, **Then** they are re-documented using the fixed lineage pipeline
2. **Given** an object is regenerated, **When** the new wiki file is compared to the old one, **Then** passthrough columns have Tier 1 descriptions and the lineage chain includes Generic Pipeline metadata

---

### Edge Cases

- What happens when the mapping view is down or the Databricks MCP is unavailable? → Graceful degradation: skip Step 1, warn, proceed with SP-code lineage only (current behavior). Tag all columns as Tier 2 minimum.
- What happens when a DWH table name doesn't match any production table in the mapping view? → Some DWH tables are ETL-derived (no 1:1 production source). These get lineage from SP code analysis only. Flag as "No Generic Pipeline match" in the lineage file.
- What happens when the upstream wiki has a column that doesn't exist in DWH? → Ignore it (column was dropped during ETL).
- What happens when a DWH column doesn't exist in the upstream wiki? → Tag as Tier 2 (DWH-added column, likely ETL-computed or joined from secondary source).
- What happens when a blacklisted table has existing wiki files? → Leave them. Don't delete documentation, just exclude from future processing.

## Requirements

### Functional Requirements

- **FR-001**: System MUST support a permanent blacklist file (`_blacklist.json`) per schema that excludes tables from batch planning and documentation
- **FR-002**: Blacklist file MUST support categorized entries with reason codes (backup, test, junk, switch, partition, replication, validation, poc)
- **FR-003**: Pipeline MUST query the Generic Pipeline mapping view via Databricks MCP during Phase 10A Step 1 for every table being documented
- **FR-004**: Pipeline MUST look up the upstream production wiki in `DB_Schema/etoro/Wiki/` using the production source identified by the mapping view
- **FR-005**: Pipeline MUST inherit column descriptions from upstream wiki as Tier 1 when the column is a passthrough (same name)
- **FR-006**: Pipeline MUST tag inherited descriptions with `(Tier 1 — upstream wiki)` in the Elements table
- **FR-007**: Blacklisted objects MUST show as `Blacklisted — {reason}` in `_index.md` and be excluded from documented/pending counts
- **FR-008**: Pipeline MUST gracefully degrade if Databricks MCP is unavailable — skip mapping view query, warn, proceed with SP-code lineage
- **FR-009**: The lineage `.lineage.md` file MUST include Generic Pipeline metadata (CopyStrategy, FrequencyMinute, DatalakePath, UC table) when available

### Key Entities

- **Blacklist Entry**: Table name, reason category, date added, optional notes
- **Generic Pipeline Mapping**: Production source (database, schema, table) → lake path → UC bronze table → DWH target
- **Upstream Wiki Reference**: Path to production wiki file, column descriptions, confidence tier

## Success Criteria

### Measurable Outcomes

- **SC-001**: After applying the blacklist, the DWH_dbo documentation target count drops from 379 to ~292 (85 pruned + 2 already skipped)
- **SC-002**: After fixing lineage, at least 50% of columns in newly documented tables have Tier 1 descriptions (inherited from upstream wiki)
- **SC-003**: Every documented table with a Generic Pipeline mapping shows the exact production source table, not "inferred" or "likely"
- **SC-004**: Batch completion rate improves — no time wasted on backup/test/junk tables
