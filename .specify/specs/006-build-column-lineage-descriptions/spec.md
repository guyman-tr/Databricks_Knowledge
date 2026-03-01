# Feature Specification: Build Column Lineage Descriptions

**Feature Branch**: `006-build-column-lineage-descriptions`
**Created**: 2026-02-25
**Status**: Draft
**Input**: For each column in each object, produce a concise lineage description containing first upstream source, last upstream source, and transformation chain — all within Unity Catalog's 1024-character limit. Generate UC tags from lineage metadata. This spec produces two output formats: (1) descriptions-only (base from spec 005), (2) full combined with lineage context. The final format choice is deferred to post-POC evaluation.

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

---

### Edge Cases

- What happens when lineage can't be traced (e.g., hardcoded values, external imports)? → Resolved: label as "derived: <expression>"
- How do we handle columns with multiple upstream sources (e.g., COALESCE from 3 tables)? → Resolved: list all as multiple lineage parents
- What about columns that are computed (no direct upstream, e.g., GETDATE())?

## Requirements

### Functional Requirements

- **FR-001**: System MUST assemble lineage for each column from upstream wiki outputs (specs 001, 003) to identify first and last upstream sources
- **FR-002**: System MUST summarize transformation steps in the lineage chain
- **FR-003**: System MUST generate descriptions under 1024 characters including lineage information
- **FR-005**: System MUST handle columns with untraceable lineage by marking them explicitly

### Key Entities

- **ColumnLineage**: The full chain from first upstream source through transformations to current column
- **CompressedDescription**: A UC-ready description containing meaning + lineage within 1024 chars
## Clarifications

### Session 2026-03-01

- Q: How do specs 005 and 006 combine their UC descriptions? → A: Both produce separate outputs. Two formats generated: (1) descriptions-only (from 005), (2) full combined with lineage (from 006). Evaluate which fits the 1024-char budget and is intelligible; decide post-POC which to use.
- Q: Where does lineage data come from? → A: Consume from upstream wiki outputs (spec 001 production wiki + spec 003 Synapse wiki). No re-tracing of SP code.
- Q: Should tag generation live in 006 or 007? → A: Move to 007. Tags align with the mandatory tag standard in Confluence ("Databricks AI Agent - Data layer Rules", page 13960052801). Infer what's possible from pipeline outputs. PII tag uses two tiers: direct (column IS PII) and indirect (column JOINs to PII), per Confluence PII mapping pages.
- Q: How to handle columns with multiple upstream sources (COALESCE, CASE)? → A: List all upstream sources as multiple lineage parents.
- Q: How to mark columns with no traceable upstream (GETDATE, hardcoded, identity)? → A: Label as "derived" with the expression (e.g., "derived: GETDATE()"). No fake lineage.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Lineage is traced for at least 70% of columns across all mapped objects
- **SC-002**: 100% of generated descriptions are under 1024 characters
- **SC-004**: Columns with untraceable lineage are explicitly marked (not left blank)
