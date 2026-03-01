# Feature Specification: Audit Lake Coverage

**Feature Branch**: `004-audit-lake-coverage`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Determine which production objects are exported to the Data Lake via the Generic Pipeline and which are not. Map Unity Catalog registration status for all lake objects. This audit serves three purposes: (1) **Gap analysis** — identify what's NOT flowing downstream, (2) **Target map** — identify all downstream endpoints where metadata needs to be pushed to (specs 005, 007), and (3) **Scope map for the Databricks/Lake knowledge layer** — the lake is not just a passthrough; it has its own notebooks, Spark pipelines, and Delta transformations that will need their own knowledge analysis in a future layer. The complete vision: all knowledge files ultimately live in Databricks agent folders, routing user queries to the right knowledge skills across all layers (production → DWH → lake/Databricks).

## User Scenarios & Testing

### User Story 1 - Inventory Generic Pipeline Exports (Priority: P1)

As a data knowledge engineer, I need to know exactly which production objects the Generic Pipeline exports to the Data Lake, on what schedule (hourly/daily), so that I can identify coverage gaps.

**Why this priority**: Without knowing what's exported, we can't determine what's missing. This is the baseline for gap analysis.

**Independent Test**: List all Generic Pipeline export configurations and compare against the production object inventory from Phase 2.

**Acceptance Scenarios**:

1. **Given** access to Generic Pipeline configuration, **When** I extract all export definitions, **Then** I receive a list of source objects, target lake paths, and refresh schedules
2. **Given** the export list, **When** I cross-reference with the Phase 2 production inventory, **Then** I can identify which production objects have no lake export

---

### User Story 2 - Identify Coverage Gaps (Priority: P1)

As a data knowledge engineer, I need a gap report showing which production objects are NOT in the lake, so that stakeholders can decide whether those gaps matter.

**Why this priority**: Gaps in the lake mean gaps in downstream analytics. Identifying them is essential for completeness.

**Independent Test**: Generate a gap report for one business unit schema and validate the findings against manual knowledge.

**Acceptance Scenarios**:

1. **Given** a production inventory and a lake inventory, **When** I compare them, **Then** I produce a gap report listing every production object with no lake representation
2. **Given** the gap report, **When** I categorize gaps, **Then** each is tagged as: intentionally excluded, not yet configured, or unknown

---

### User Story 3 - Map Unity Catalog Registration (Priority: P2)

As a data knowledge engineer, I need to know which lake objects are registered in Unity Catalog and which are not, so that metadata propagation (Phase 5) targets the right objects.

**Why this priority**: UC registration status determines where we can push descriptions and tags.

**Independent Test**: Query Unity Catalog for all registered tables and compare against the lake object inventory.

**Acceptance Scenarios**:

1. **Given** access to Unity Catalog, **When** I list all registered objects, **Then** I can cross-reference with lake objects to find unregistered items
2. **Given** the coverage matrix, **When** I present it, **Then** it shows for each production object: exists in lake (Y/N), registered in UC (Y/N), refresh schedule

---

### Edge Cases

- What if the Generic Pipeline exports objects that no longer exist in production (orphaned exports)?
- How do we handle objects that are exported but under a different name in the lake?
- What about objects exported to the lake but not through the Generic Pipeline (custom exports)? → Note if discovered but don't actively hunt. Generic Pipeline mapping view is the primary source.

## Clarifications

### Session 2026-03-01

- Q: What format does the coverage matrix output take? → A: Markdown report in `knowledge/` (cross-cutting audit artifact, not a single-object wiki file). Human-readable, git-diffable, and directly consumable by the AI agent.
- Q: Are non-Generic Pipeline exports (custom ADF, manual) in scope? → A: Note but don't hunt. Generic Pipeline mapping view is the primary source. If custom exports are discovered, note them.
- Q: What is the full purpose of the coverage matrix beyond gap analysis? → A: Three purposes: (1) gap analysis, (2) target map for metadata push (specs 005/007), (3) scope map for the future Databricks/Lake knowledge layer — the lake has its own notebooks, Spark pipelines, and Delta transformations that will need knowledge analysis. The complete vision is all knowledge files live in Databricks agent folders for query routing across all layers.

## Requirements

### Functional Requirements

- **FR-001**: System MUST extract all Generic Pipeline export configurations (source, target, schedule)
- **FR-002**: System MUST compare production inventory against lake inventory to identify gaps
- **FR-003**: System MUST query Unity Catalog to determine registration status of lake objects
- **FR-004**: System MUST produce a coverage matrix as a Markdown report in `knowledge/` (e.g., `knowledge/coverage-matrix.md`): production object -> lake status -> UC status -> refresh schedule
- **FR-005**: System MUST categorize gaps (intentional exclusion, not configured, unknown)

### Key Entities

- **PipelineExport**: A Generic Pipeline configuration that exports a production object to the lake
- **CoverageMatrix**: A cross-reference showing each production object's status across lake and UC
- **CoverageGap**: A production object with no lake representation

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of Generic Pipeline exports are inventoried
- **SC-002**: Coverage matrix is produced for all production schemas mapped in Phase 2
- **SC-003**: All gaps are categorized with at least 90% assigned a reason
- **SC-004**: Unity Catalog registration status is determined for all lake objects
