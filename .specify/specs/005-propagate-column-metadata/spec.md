# Feature Specification: Propagate Column Metadata

**Feature Branch**: `005-propagate-column-metadata`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Take all gathered metadata from Phases 1-4 and propagate column descriptions, types, relationships, and context to all lake and Unity Catalog objects, ensuring consistency across layers.

## User Scenarios & Testing

### User Story 1 - Resolve Column Identity Across Layers (Priority: P1)

As a data knowledge engineer, I need to match columns across production, lake, and UC representations of the same data, so that metadata gathered at one layer can be propagated to all layers.

**Why this priority**: The same column appears in multiple places (production table, lake parquet, UC table). Without resolving identity, metadata stays siloed.

**Independent Test**: Take one production table, find its lake and UC equivalents, and match columns by name and type across all three.

**Acceptance Scenarios**:

1. **Given** a production table with 20 columns, **When** I find its lake/UC equivalents, **Then** I can match at least 90% of columns across layers by name
2. **Given** columns with name mismatches across layers, **When** I apply fuzzy matching and type comparison, **Then** I can resolve at least 80% of remaining mismatches

---

### User Story 2 - Propagate Descriptions Consistently (Priority: P1)

As a data knowledge engineer, I need the same column appearing in multiple objects to have a consistent description everywhere, so that the agent gives consistent answers regardless of which object a user asks about.

**Why this priority**: Inconsistent descriptions undermine trust in the knowledge system.

**Independent Test**: Take a column that appears in 5+ objects and verify it has the same core description in each, adapted for context.

**Acceptance Scenarios**:

1. **Given** a column appearing in multiple objects, **When** I propagate its description, **Then** the core meaning is identical across all occurrences
2. **Given** a column with layer-specific context (e.g., aggregated in Synapse), **When** I write its description, **Then** the layer-specific transformation is appended to the base description

---

### User Story 3 - Enforce UC Description Limits (Priority: P2)

As a data knowledge engineer, I need all descriptions to fit within Unity Catalog's 1024-character limit, so that they can be programmatically pushed without truncation.

**Why this priority**: Descriptions that don't fit can't be pushed. This constraint shapes the entire description format.

**Independent Test**: Generate descriptions for 50 columns and verify all are under 1024 characters.

**Acceptance Scenarios**:

1. **Given** a column with rich metadata, **When** I generate its UC description, **Then** it is under 1024 characters
2. **Given** a column where the full context exceeds 1024 characters, **When** I compress it, **Then** the most critical information (type, meaning, primary source) is preserved

---

### Edge Cases

- What happens when a column exists in UC but has no production equivalent (derived columns)?
- How do we handle columns that changed names between layers?
- What if existing UC descriptions conflict with our generated ones?

## Requirements

### Functional Requirements

- **FR-001**: System MUST match columns across production, lake, and UC layers by name and type
- **FR-002**: System MUST propagate descriptions from the richest source to all representations
- **FR-003**: System MUST ensure description consistency for the same column across objects
- **FR-004**: System MUST enforce the 1024-character limit for all UC descriptions
- **FR-005**: System MUST flag conflicts between existing UC descriptions and generated ones

### Key Entities

- **ColumnMapping**: A resolved identity linking the same column across production, lake, and UC
- **PropagatedDescription**: A description generated from upstream metadata, formatted for UC

## Success Criteria

### Measurable Outcomes

- **SC-001**: Column identity is resolved for at least 90% of columns across layers
- **SC-002**: 100% of generated descriptions are under 1024 characters
- **SC-003**: Description consistency is verified for columns appearing in 3+ objects
- **SC-004**: Conflicts with existing UC descriptions are flagged for human review
