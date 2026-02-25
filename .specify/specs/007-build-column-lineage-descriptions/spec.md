# Feature Specification: Build Column Lineage Descriptions

**Feature Branch**: `007-build-column-lineage-descriptions`
**Created**: 2026-02-25
**Status**: Draft
**Input**: For each column in each object, produce a concise description containing first upstream source, last upstream source, and transformation chain -- all within Unity Catalog's 1024-character limit. Generate UC tags from lineage metadata.

## User Scenarios & Testing

### User Story 1 - Generate Column Lineage Chain (Priority: P1)

As a data knowledge engineer, I need each column to have a documented lineage chain showing where the data originated, what transformations it went through, and its immediate parent, so that the agent can explain data provenance.

**Why this priority**: Lineage is a constitutional principle. This is the phase that delivers it at column granularity.

**Independent Test**: Take a revenue column in a bi_db table, trace it back through SPs to its production source, and produce a lineage chain.

**Acceptance Scenarios**:

1. **Given** a column in a Synapse table, **When** I trace its lineage, **Then** I can identify its first upstream source (production table.column)
2. **Given** a column in a Synapse table, **When** I trace its lineage, **Then** I can identify its last upstream source (immediate parent object.column)
3. **Given** a lineage chain, **When** I summarize the transformations, **Then** each intermediate step is described (e.g., "aggregated by date", "filtered to active customers", "joined with currency rates")

---

### User Story 2 - Compress Lineage Into 1024 Characters (Priority: P1)

As a data knowledge engineer, I need the column description (including lineage) to fit within UC's 1024-character limit, so that it can be programmatically pushed.

**Why this priority**: The UC limit is a hard constraint. If we can't fit, we can't deploy.

**Independent Test**: Generate descriptions for 20 columns with complex lineage and verify all fit within 1024 characters.

**Acceptance Scenarios**:

1. **Given** a column with a 3-hop lineage chain, **When** I generate the description, **Then** it includes: meaning, first source, last source, key transformations, all under 1024 characters
2. **Given** a column with a 6+ hop lineage chain, **When** I compress, **Then** intermediate hops are summarized (e.g., "via 4 aggregation steps in bi_db") while first and last sources are preserved verbatim

---

### User Story 3 - Generate UC Tags From Lineage (Priority: P2)

As a data knowledge engineer, I need tags derived from lineage metadata (source system, domain, transformation type, refresh frequency), so that UC objects are discoverable via tag search.

**Why this priority**: Tags enable the agent to filter and route queries to the right domain.

**Independent Test**: Generate tags for 10 columns and verify they include at least: source_system, domain, and refresh_frequency.

**Acceptance Scenarios**:

1. **Given** a column with lineage metadata, **When** I generate tags, **Then** tags include: source_system, domain, data_type_category, refresh_frequency
2. **Given** generated tags, **When** I validate against UC tag format, **Then** all tags are valid UC key-value pairs

---

### Edge Cases

- What happens when lineage can't be traced (e.g., hardcoded values, external imports)?
- How do we handle columns with multiple upstream sources (e.g., COALESCE from 3 tables)?
- What about columns that are computed (no direct upstream, e.g., GETDATE())?

## Requirements

### Functional Requirements

- **FR-001**: System MUST trace lineage for each column to its first and last upstream sources
- **FR-002**: System MUST summarize transformation steps in the lineage chain
- **FR-003**: System MUST generate descriptions under 1024 characters including lineage information
- **FR-004**: System MUST generate UC-compatible tags from lineage metadata
- **FR-005**: System MUST handle columns with untraceable lineage by marking them explicitly

### Key Entities

- **ColumnLineage**: The full chain from first upstream source through transformations to current column
- **CompressedDescription**: A UC-ready description containing meaning + lineage within 1024 chars
- **LineageTag**: A key-value tag derived from lineage metadata

## Success Criteria

### Measurable Outcomes

- **SC-001**: Lineage is traced for at least 70% of columns across all mapped objects
- **SC-002**: 100% of generated descriptions are under 1024 characters
- **SC-003**: Tags are generated for at least 80% of columns with valid UC format
- **SC-004**: Columns with untraceable lineage are explicitly marked (not left blank)
