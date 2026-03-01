# Feature Specification: Resolve Column Metadata

**Feature Branch**: `005-resolve-column-metadata`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Take all gathered metadata from specs 001-004 and resolve column identity across layers, then generate consistent base descriptions formatted for UC consumption. This spec covers column identity matching and description generation; lineage narratives are handled by spec 006. The actual push to Unity Catalog is a separate future spec.

## User Scenarios & Testing

### User Story 1 - Resolve Column Identity Across Layers (Priority: P1)

As a data knowledge engineer, I need to match columns across production, lake, and UC representations of the same data, so that metadata gathered at one layer can be propagated to all layers.

**Why this priority**: The same column appears in multiple places (production table, lake parquet, UC table). Without resolving identity, metadata stays siloed.

**Independent Test**: Take one production table, find its lake and UC equivalents, and match columns by name and type across all three.

**Acceptance Scenarios**:

1. **Given** a production table with 20 columns, **When** I find its lake/UC equivalents, **Then** I can match at least 90% of columns across layers by name
2. **Given** columns with name mismatches across layers, **When** I apply fuzzy matching and type comparison, **Then** I can resolve at least 80% of remaining mismatches

---

### User Story 2 - Generate Consistent Descriptions (Priority: P1)

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
- What if existing UC descriptions conflict with our generated ones? → Resolved: auto-override, log, clash file for semantic diffs

## Requirements

### Functional Requirements

- **FR-001**: System MUST match columns across all four layers (Production → Synapse → Lake → UC) by name and type
- **FR-002**: System MUST generate descriptions following the constitution's authority hierarchy (upstream wiki → Synapse wiki → live data → metadata); lower-layer transformations are appended as context, not overrides
- **FR-003**: System MUST ensure description consistency for the same column across objects
- **FR-004**: System MUST enforce the 1024-character limit for all UC descriptions
- **FR-005**: System MUST auto-override existing UC descriptions with generated ones, log where UC already had content, and produce a clash file when the existing description is semantically different (not just wording variation)

### Key Entities

- **ColumnMapping**: A resolved identity linking the same column across Production, Synapse, Lake, and UC
- **ResolvedDescription**: A description generated from upstream metadata, formatted for UC consumption

## Clarifications

### Session 2026-03-01

- Q: What does "propagate" mean — generate AND push, or generate files only? → A: Generate description files only; actual UC push is a separate downstream action.
- Q: Which layers are in scope for column matching? → A: All four: Production → Synapse → Lake → UC.
- Q: How to determine which source wins for a column description? → A: Follow constitution authority hierarchy (upstream wiki → Synapse code/wiki → live data → metadata); lower layers append transformation context.
- Q: Boundary between spec 005 and spec 006? → A: 005 = column identity matching + base description propagation; 006 = lineage narrative (how a column transforms across layers). Two distinct outputs.
- Q: How to handle conflicts with existing UC descriptions? → A: Auto-override with generated descriptions. Log where UC already had content. When there is a genuine semantic clash (not just wording), create a clash file with full details. See project-notes.md for post-POC thinking on UC as a user feedback channel.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Column identity is resolved for at least 90% of columns across layers
- **SC-002**: 100% of generated descriptions are under 1024 characters
- **SC-003**: Description consistency is verified for columns appearing in 3+ objects
- **SC-004**: Existing UC descriptions are overridden; semantic clashes are captured in a clash file with full context
