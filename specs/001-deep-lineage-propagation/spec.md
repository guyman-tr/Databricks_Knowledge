# Feature Specification: Deep Lineage Column Propagation

**Feature Branch**: `001-deep-lineage-propagation`  
**Created**: 2026-03-15  
**Status**: Draft  
**Input**: User description: "Revisit UC metadata propagation to trace EVERY column downstream through the full lineage tree — including renamed columns — with memory-safe batching."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Full Lineage Tree Propagation (Priority: P1)

When a source table (e.g., `BI_DB_CIDFirstDates`) is documented, the system traces every documented column through the entire Unity Catalog lineage graph — not just objects with similar names. A column like `CID` that appears in hundreds of downstream tables, views, and aggregations across all catalogs and schemas receives the same rich description everywhere it appears with an identical name and identical semantic meaning.

**Why this priority**: This is the core intent of the feature. Without it, metadata propagation only reaches 6 objects (as seen in the CIDFirstDates example) instead of the potentially hundreds that reference the same columns. Analysts querying any downstream object get no context on what `CID`, `FirstDepositDate`, or `Verified` mean.

**Independent Test**: Run propagation for one documented table. Compare the count of downstream objects discovered by the current name-pattern approach vs. the new lineage-tree approach. The new approach should discover significantly more objects.

**Acceptance Scenarios**:

1. **Given** a documented table with 139 columns and known UC lineage, **When** the propagation runs, **Then** every downstream object reachable via `system.access.column_lineage` (direct and transitive) receives column comments for all matching columns.
2. **Given** a column `CID` that appears in 200+ downstream objects across multiple schemas, **When** propagation runs, **Then** all 200+ objects receive the `CID` description — not just the 6 objects whose names match `%cidfirstdates%`.
3. **Given** a downstream object that is 3+ hops away from the source (e.g., source table → view → materialized table → reporting view), **When** propagation runs, **Then** the column description still propagates to the final object.

---

### User Story 2 - Renamed Column Detection and Propagation (Priority: P2)

When a column is renamed downstream but retains the same semantic value (e.g., `FirstDepositDate` in the source becomes `FTDDate` in a downstream view), the system detects the rename via lineage metadata and propagates the description with an explanatory note about the rename origin.

**Why this priority**: Renamed columns are invisible to the current name-matching approach. They represent a significant gap in metadata coverage — analysts see `FTDDate` with no description and have no idea it's `FirstDepositDate` from the source table.

**Independent Test**: Identify a known renamed column in the lineage graph. Run propagation and verify the downstream column receives a description referencing the original column name.

**Acceptance Scenarios**:

1. **Given** `FirstDepositDate` in the source is exposed as `FTDDate` in a downstream view via `SELECT FirstDepositDate AS FTDDate`, **When** propagation runs, **Then** `FTDDate` receives a description like: "Same as FirstDepositDate: First successful deposit date. From Dim_Customer.FirstDepositDate via Fact_BillingDeposit. (Propagated from BI_DB_CIDFirstDates.FirstDepositDate)"
2. **Given** a column renamed in one hop and then renamed again in a second hop (e.g., `FirstDepositDate` → `FTDDate` → `ftd`), **When** propagation runs, **Then** the final column `ftd` still traces back to `FirstDepositDate` and receives a description with the full rename chain.
3. **Given** a column that is NOT renamed but is a computed transformation (e.g., `YEAR(FirstDepositDate) AS FTDYear`), **When** propagation runs, **Then** this column is NOT propagated verbatim — it is flagged for manual review since it is a derived value, not a rename.

---

### User Story 3 - Memory-Safe Batched Processing (Priority: P1)

The lineage tree for a major table can span hundreds or thousands of downstream objects. The system processes this tree in batches to avoid memory exhaustion, Cursor crashes, and MCP timeout issues. The tree is discovered first (lightweight metadata queries), then processed in controlled chunks.

**Why this priority**: Equal to P1 because without memory safety, the feature literally cannot run on large tables — Cursor crashes (as has already happened). The feature is useless if it can't handle production-scale lineage trees.

**Independent Test**: Run propagation on the largest known table (e.g., `BI_DB_CIDFirstDates` which touches hundreds of downstream objects). The process completes without crashing, even if it takes multiple batches.

**Acceptance Scenarios**:

1. **Given** a source table with 500+ downstream objects in its lineage tree, **When** propagation runs, **Then** the system processes objects in batches (configurable, default 30 objects per batch) without exceeding memory limits.
2. **Given** a propagation run that is interrupted mid-batch (crash or user cancel), **When** the run is restarted, **Then** it resumes from where it left off by reading the progress log, not re-processing already-completed objects.
3. **Given** the full lineage tree discovery phase, **When** it queries `system.access.column_lineage`, **Then** it paginates results and stores the tree structure to disk before beginning any ALTER execution — separating discovery from execution.

---

### User Story 4 - Propagation Scope Report (Priority: P3)

Before executing any ALTER statements, the system produces a "propagation scope report" showing the full tree — how many objects, how many columns, estimated statement count, and any renamed columns detected. This lets the operator review the blast radius before committing.

**Why this priority**: Operational safety. When a single table can trigger thousands of ALTER statements across hundreds of objects, the operator needs visibility before execution.

**Independent Test**: Run the discovery phase only (dry-run mode) and verify the scope report is generated without executing any ALTER statements.

**Acceptance Scenarios**:

1. **Given** a completed lineage tree discovery, **When** the scope report is generated, **Then** it lists: total downstream objects, objects by type (TABLE/VIEW/MVW), total column matches, renamed column matches, estimated ALTER statement count, and any objects that will be skipped (with reasons).
2. **Given** a scope report showing 2,000+ ALTER statements, **When** the operator reviews it, **Then** they can choose to proceed, limit to specific schemas, or abort.

---

### Edge Cases

- What happens when a column appears in a circular lineage reference (view A references view B which references view A)?
- How does the system handle columns that exist in `system.access.column_lineage` but the downstream object has been dropped?
- What happens when `system.access.column_lineage` is unavailable or has incomplete data (not all workloads logged)?
- How does the system handle a downstream column that inherits from MULTIPLE source columns (e.g., `COALESCE(a.CID, b.CID) AS CID`)?
- What happens when the same downstream object is reachable via multiple paths in the lineage tree (deduplication)?
- What happens when two source tables document the same column differently? → Resolved: bottom-up processing order means the Tier 1 root description is written first and all downstream inheritors converge on the same source.

## Clarifications

### Session 2026-03-15

- Q: When two source tables propagate different descriptions for the same column in the same downstream object, which wins? → A: Bottom-up lineage order. The most upstream source (Tier 1 production table, e.g., `Customer.Customer`) is documented first. Its description propagates into `Dim_Customer`, then onward to `BI_DB_CIDFirstDates` and beyond. Because the pipeline builds bottom-up, the authoritative Tier 1 description is already in place before downstream tables run — descriptions converge naturally from the shared root.
- Q: Should lineage and name-pattern discovery run together or is lineage-only sufficient? → A: Union of both for now — lineage is primary, name-pattern supplements gaps where lineage data is incomplete. This is still a semi-manual POC on a local VM, not a production pipeline. The architectural vision is a full bottom-up dependency map across the entire Synapse object tree, at which point lineage-only may suffice. For now, maximize coverage.
- Q: When a downstream column already has a description (from a previous run or manual entry), what happens? → A: Always overwrite. The latest propagation run wins. Corrections belong at the source level via the Tier 5 review sidecar, not as manual overrides on downstream objects. The pipeline is idempotent and bottom-up, so the latest run carries the most authoritative description.
- Q: Should there be a depth/object cap for lineage traversal? → A: No depth or object cap — traverse everything. Batching (FR-004) handles scale. Ultra-ubiquitous columns (etr_ymd, etr_ym, etr_y, UpdateDate, and others appearing in 500+ objects) are BLACKLISTED from the per-table pipeline entirely. They are propagated separately in their own dedicated one-time broadcast batch — not as a side effect of documenting any individual table. The main pipeline focuses on business-meaningful columns that benefit from lineage tracing. Data-driven analysis (see `column_frequency.csv`) shows ~70 columns at 100+ occurrences; those above a configurable threshold go on the blacklist.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST traverse the full lineage tree using `system.access.column_lineage` recursively — not just direct children, but children of children, to arbitrary depth.
- **FR-002**: System MUST match columns by exact name (case-insensitive) for "identical column" propagation and by lineage source-target mapping for "renamed column" propagation.
- **FR-003**: System MUST separate the propagation into two distinct phases: (a) **Discovery** — build the full tree and write it to disk, (b) **Execution** — process the tree in batches and execute ALTER statements.
- **FR-004**: System MUST process downstream objects in configurable batches (default 30 objects per batch, overridable via `--batch-size` CLI argument) to prevent memory exhaustion.
- **FR-005**: System MUST detect renamed columns via `system.access.column_lineage` source/target column name mappings and propagate descriptions with a rename annotation.
- **FR-006**: System MUST deduplicate downstream objects reachable via multiple lineage paths — each object is processed exactly once.
- **FR-007**: System MUST handle circular references by tracking visited nodes and terminating traversal when a cycle is detected.
- **FR-008**: System MUST produce a propagation scope report before execution showing the full blast radius (object count, column count, rename count, estimated statements).
- **FR-009**: System MUST support resumable execution — if interrupted, it can resume from the last completed batch by reading a progress log.
- **FR-010**: System MUST distinguish between "identical column" propagation (same name, verbatim description) and "renamed column" propagation (different name, description with rename context).
- **FR-011**: System MUST NOT propagate to columns that are computed transformations of the source (e.g., `YEAR(col)`, `col * 100`) — only renames (aliasing) qualify for propagation. Computed transformations that fail the rename heuristic MUST be recorded in the scope report under a "skipped — computed transformation" section for operator review.
- **FR-012**: System MUST run BOTH lineage-based discovery AND name-pattern + column-cross-match discovery, then deduplicate the union. Lineage is the primary method; name-pattern supplements gaps where lineage data is incomplete. This dual approach maximizes coverage during the POC phase while the architectural vision (full bottom-up dependency map) matures toward lineage-only.
- **FR-013**: System MUST always overwrite existing column descriptions on downstream objects — the latest propagation run wins. Corrections to descriptions belong at the source level (Tier 5 review sidecar), not as manual overrides on downstream objects.
- **FR-014**: System MUST maintain a configurable blacklist of ETL infrastructure columns (e.g., `etr_ymd`, `etr_ym`, `etr_y`, `UpdateDate`, `CreatedDate`, `FileName`, `_fivetran_synced`, `_row`, `__MEETS_DROP_EXPECTATIONS`) that are EXCLUDED from per-table lineage propagation. These are columns whose meaning is trivial and universal — they add noise to the per-table pipeline without business value. They are propagated separately in a dedicated one-time broadcast batch. The blacklist is curated semantically, NOT by frequency threshold alone — high-frequency columns with context-dependent meaning (e.g., `Name`, `Date`, `Amount`, `Id`) stay in the per-table pipeline. Universal FK identifiers (e.g., `CID`, `InstrumentID`, `PositionID`) also stay in the per-table pipeline — their descriptions are richer and context-specific, and bottom-up processing order handles convergence naturally.
- **FR-015**: The broadcast batch for blacklisted columns is a standalone operation, independent of the per-table documentation pipeline. It runs once (or on-demand) and applies trivial canonical descriptions to every instance of each blacklisted column across the catalog.
- **FR-016**: System MUST process source tables in bottom-up lineage order — production source tables (Tier 1) first, then Dim/Fact tables that consume them, then BI/reporting tables built on those. This ensures the most authoritative (most upstream) description is written first, and downstream propagation inherits from the shared root. When multiple sources document the same column, descriptions converge naturally because they all originate from the same Tier 1 ancestor. The processing order is derived from the SSDT dependency graph in the DataPlatform repo (not UC lineage, which cannot see Synapse-internal ETL), stored as `_dependency_order.json` and regenerated on demand.

### Key Entities

- **Lineage Tree**: The directed acyclic graph (with possible cycles) of all downstream objects reachable from a source table's columns via UC lineage. Stored as a JSON or Markdown file on disk after discovery.
- **ColumnMatch**: A single column mapping between source and downstream, tracking identical or renamed matches. Contains: source column, target column, match type (`identical`/`renamed`), rename chain, description to propagate, confidence tier.
- **Propagation Batch**: A chunk of the lineage tree (N objects) processed in a single pass. Contains: list of objects, their column mappings, and execution status.
- **Scope Report**: A pre-execution summary showing the full propagation footprint — object counts, column counts, renames detected, estimated ALTER statements.
- **Progress Log**: A file tracking which batches have been completed, enabling resumable execution after interruption.
- **Blacklist**: A config-driven list of ultra-ubiquitous column names (e.g., etr_ymd, etr_ym, etr_y, UpdateDate) excluded from per-table propagation. Propagated separately in a standalone broadcast batch.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a table like `BI_DB_CIDFirstDates`, downstream propagation reaches at least 10x more objects than the current name-pattern approach (e.g., from 6 objects to 60+).
- **SC-002**: Renamed columns (e.g., `FirstDepositDate` → `FTDDate`) are detected and documented with rename context in 100% of cases where lineage data exists.
- **SC-003**: The propagation completes without Cursor memory crashes for tables with up to 1,000 downstream objects.
- **SC-004**: An interrupted propagation run can be resumed within 30 seconds by reading the progress log — no re-discovery or re-processing of completed batches.
- **SC-005**: The scope report accurately predicts the number of ALTER statements within 5% of the actual execution count.
- **SC-006**: End-to-end propagation time for a 500-object tree is under 30 minutes (including discovery, scope report, and batched execution).
