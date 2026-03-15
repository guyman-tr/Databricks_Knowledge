# Research: Deep Lineage Column Propagation

**Branch**: `001-deep-lineage-propagation` | **Date**: 2026-03-15

## R1: system.access.column_lineage Schema & Coverage

**Decision**: Use `system.access.column_lineage` as the primary discovery method for recursive downstream traversal.

**Rationale**: The table exists, has 297M rows, and provides exactly the source→target column mapping we need — including renames. It captures lineage from notebooks, jobs, pipelines, dashboards, and DBSQL queries.

**Key schema fields**:

| Field | Use |
|-------|-----|
| `source_table_full_name` | Three-level name of source (e.g., `main.bi_db.gold_...`) |
| `source_column_name` | Source column name |
| `target_table_full_name` | Three-level name of target |
| `target_column_name` | Target column name (differs from source when renamed) |
| `source_type` / `target_type` | TABLE, VIEW, MATERIALIZED_VIEW, STREAMING_TABLE, PATH, METRIC_VIEW |
| `event_time` | When the lineage was recorded — useful for freshness |
| `entity_type` | NOTEBOOK, JOB, PIPELINE, DASHBOARD_V3, DBSQL_QUERY, etc. |

**Coverage gap**: Lineage is recorded when queries/jobs actually run. Objects that haven't been queried recently may have no lineage data. This is why FR-012 mandates the union with name-pattern discovery.

**Scale concern**: 297M rows. Queries must filter tightly on `source_table_full_name` and paginate. A single unfiltered query would be catastrophic.

**Alternatives considered**:
- `system.information_schema.view_table_usage`: Only covers view→table, not transitive
- `SHOW CREATE TABLE` parsing: Brittle, doesn't catch runtime-discovered lineage
- Pure name-pattern search: Already in use, misses objects with different names

## R2: Rename Detection Heuristic

**Decision**: A rename is defined as `source_column_name != target_column_name` AND the target name is a plausible identifier (no operators, no spaces, reasonable length ratio).

**Rationale**: Raw `source_column_name != target_column_name` produces heavy noise. Sample data showed `IsBuy → UnitsNOP-90%` and `Amount → UnitsNOP+50%` — these are computed expressions, not renames. True renames look like `ExecutedQuantity → quantity` or `FirstDepositDate → FTDDate`.

**Heuristic filters**:
1. Target column name must be a valid SQL identifier (alphanumeric + underscore only)
2. Target column name must not contain arithmetic operators (`+`, `-`, `*`, `/`, `%`)
3. Length ratio between source and target should be < 3x (extreme length changes suggest computation)
4. Common prefix/suffix overlap > 30% suggests rename; zero overlap suggests transformation

**Alternatives considered**:
- No rename detection at all: Misses the user's explicit requirement (US2)
- ML-based similarity: Overkill for POC; heuristic is sufficient

## R3: Memory-Safe Architecture

**Decision**: Discovery and execution are handled by a standalone Python script, NOT inline in the AI agent's context. The agent triggers the script, reviews output, and decides whether to proceed.

**Rationale**: The AI agent's context window is the bottleneck that caused previous crashes. A Python script can:
- Query 297M row table with paginated queries
- Build arbitrarily large trees on disk (JSON)
- Process batches sequentially, freeing memory between batches
- Resume from progress logs
- Run for 30+ minutes without context window pressure

**Alternatives considered**:
- Agent-inline discovery: Caused crashes already; 297M row table makes this worse
- Subagent delegation: Better than inline but still bounded by context; Python script is simpler

## R4: Blacklist Composition

**Decision**: Blacklist is a curated list of ETL infrastructure columns, stored in config. Threshold-based auto-detection supplements but does not replace curation.

**Rationale**: Frequency alone is a bad filter (`Name` at 515 is context-dependent). The blacklist must be semantic: only columns whose meaning is trivially universal regardless of context.

**Initial blacklist** (from column_frequency.csv analysis):

| Column | Occurrences | Category |
|--------|-------------|----------|
| `etr_ymd` | 1,475 | ETL partition |
| `etr_ym` | 1,396 | ETL partition |
| `etr_y` | 1,388 | ETL partition |
| `UpdateDate` | 763 | ETL metadata |
| `_fivetran_synced` | 204 | ETL metadata |
| `_row` | 171 | ETL metadata |
| `CreatedDate` | 134 | ETL metadata |
| `Created` | 132 | ETL metadata |
| `FileName` | 299 | ETL metadata |
| `__MEETS_DROP_EXPECTATIONS` | 110 | ETL metadata |

**NOT blacklisted** (context-dependent or business-meaningful):
- `CID` (689), `InstrumentID` (862), `GCID` (405), `PositionID` (255) — universal FKs but with rich context-specific descriptions
- `Name` (515), `Date` (456), `Amount` (214), `Id` (380) — context-dependent meaning

## R5: Synapse Dependency Graph for Bottom-Up Order (FR-016)

**Decision**: Use the SSDT-generated `sql_dp_prod_we_Dependencies.json` from the DataPlatform repo + parse each SP's `.sql` file for write targets. NOT UC lineage.

**Rationale**: UC `system.access.column_lineage` only sees downstream Databricks consumption of gold tables. It cannot see Synapse-internal ETL — the "black hole." The dependency order between Synapse tables (e.g., "Dim_Customer feeds BI_DB_CIDFirstDates") lives entirely in the SP code.

**What we found**:
- `sys.sql_expression_dependencies` exists in Synapse but only tracks views/functions (447 edges). Zero SPs.
- `sys.dm_sql_referenced_entities` / `sys.dm_sql_referencing_entities` — not supported on Synapse dedicated pools.
- The SSDT project (`sql_dp_prod_we.sqlproj`) generates `DependenciesData/sql_dp_prod_we_Dependencies.json` with full dependency graph including SPs (1,907 SP references).
- All 1,280 SPs have readable definitions via the repo.

**Implementation** (`_build_dependency_order.py`):
1. Reads the Dependencies JSON (1,227 objects)
2. For each of the 1,097 SPs, finds and parses its `.sql` file for `INSERT INTO`, `MERGE INTO`, `UPDATE`, `TRUNCATE TABLE` patterns
3. Write targets = output tables; remaining dependencies = input tables
4. Builds a directed graph and runs Kahn's topological sort

**Results**: 2,134 objects, 16,252 edges, depths 0-5:
- Depth 0 (leaf/production sources): 895
- Depth 1: 306 | Depth 2: 706 | Depth 3: 109 | Depth 4: 37 | Depth 5: 5
- Cyclic/unreachable: 76

**Alternatives considered**:
- UC `system.access.column_lineage`: Can't see Synapse-internal ETL
- Synapse `sys.sql_expression_dependencies`: Only views/functions, no SPs
- Manual tier assignment: Doesn't scale to 2,134 objects

## R6: Output File Strategy

**Decision**: Keep one `.downstream.alter.sql` per source table (current pattern). The file just gets larger with deep lineage.

**Rationale**: Independent deployment per source table is the existing pattern and supports incremental rollout. The deploy script already handles large files via sequential execution.

**Alternatives considered**:
- One file per downstream object: Flips the ownership model; harder to trace provenance
- Shared broadcast file: Only for blacklisted columns; main pipeline keeps per-source files
