# Feature Specification: Integrate Trading Platform Knowledge

**Feature Branch**: `001-integrate-trading-platform-knowledge`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Connect to Bonnie's existing production-layer knowledge for the eToro trading platform and define the canonical metadata schema that all future phases will conform to.

## User Scenarios & Testing

### User Story 1 - Define Canonical Metadata Schema (Priority: P1)

As a data knowledge engineer, I need a single agreed-upon schema that defines what a "known object" looks like across all data layers (production, lake, Synapse, UC), so that every phase of the project produces interoperable knowledge artifacts.

**Why this priority**: Without a shared schema, every phase will produce incompatible output. This is the foundation everything else builds on.

**Independent Test**: Create the schema definition, then validate it can represent at least 5 trading platform objects from Bonnie's existing output without data loss.

**Acceptance Scenarios**:

1. **Given** the schema definition exists, **When** a production table is described using it, **Then** all fields (name, schema, type, columns, relationships, lineage, description, domain, tags) are populated without ambiguity
2. **Given** the schema definition exists, **When** a Synapse view is described using it, **Then** the same schema accommodates DWH-specific attributes (transformation logic, source lineage) without breaking the structure
3. **Given** the schema definition exists, **When** a Unity Catalog table is described using it, **Then** the description field fits within 1024 characters and tags are UC-compatible

---

### User Story 2 - Connect to Bonnie's MCP Output (Priority: P1)

As a data knowledge engineer, I need to programmatically consume the knowledge artifacts Bonnie has already produced for the eToro trading platform, so that I don't rebuild what already exists.

**Why this priority**: Bonnie's work is the proven baseline -- already built for machine consumption (automated QA, agent workflows). Integrating it validates our schema and gives us immediate coverage of the trading platform.

**Independent Test**: Query Bonnie's MCP for a known trading platform table and receive structured metadata that maps cleanly to our canonical schema.

**Acceptance Scenarios**:

1. **Given** Bonnie's MCP is accessible, **When** I request metadata for a known table (e.g., a trading positions table), **Then** I receive structured data including columns, types, relationships, and descriptions
2. **Given** Bonnie's output uses her own format, **When** I map it to our canonical schema, **Then** no critical metadata is lost in translation
3. **Given** Bonnie has mapped derived/inferred keys, **When** I consume her output, **Then** these derived relationships are preserved and distinguishable from explicit FK constraints

---

### User Story 3 - Validate Schema With Real Objects (Priority: P2)

As a data knowledge engineer, I need to validate the canonical schema against a representative sample of objects across multiple layers, so that I can confirm it's flexible enough for the full project scope.

**Why this priority**: Early validation prevents costly schema changes in later phases.

**Independent Test**: Take 3 production objects, 3 Synapse objects, and 3 UC objects and describe each using the schema. Identify any gaps.

**Acceptance Scenarios**:

1. **Given** a sample of 9 objects across layers, **When** each is described using the canonical schema, **Then** at least 8 of 9 fit without requiring schema changes
2. **Given** a gap is found, **When** a schema amendment is proposed, **Then** it is backward-compatible with existing entries

---

### Edge Cases

- What happens when Bonnie's output includes metadata fields we didn't anticipate?
- How do we handle objects that exist in production but have no Synapse or UC representation yet?
- What if Bonnie's MCP is unavailable or returns partial data?

## Requirements

### Functional Requirements

- **FR-001**: System MUST define a canonical metadata schema covering: object name, schema, object type, columns (name, type, nullable, description), relationships (explicit and derived), lineage (upstream sources), description, domain, tags
- **FR-002**: System MUST support consuming Bonnie's MCP output (already machine-readable) and mapping it to the canonical schema
- **FR-003**: System MUST distinguish between explicit constraints (PK/FK) and derived/inferred relationships
- **FR-004**: System MUST handle objects that span multiple layers (e.g., a production table that also exists in the lake and UC)
- **FR-005**: System MUST version the canonical schema so future amendments are tracked

### Key Entities

- **DataObject**: A table, view, function, or stored procedure at any layer. Has columns, relationships, and belongs to a domain.
- **Column**: A field within a DataObject. Has type, nullability, description, lineage, and tags.
- **Relationship**: A connection between two DataObjects or columns. Can be explicit (FK) or derived (inferred from sampling).
- **Domain**: A logical grouping (Trading, Payments, Risk, etc.) that DataObjects belong to.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Canonical schema is defined and documented, covering all required fields
- **SC-002**: At least 10 trading platform objects from Bonnie's output are successfully mapped to the canonical schema
- **SC-003**: Schema validation against 9 cross-layer sample objects passes with no more than 1 schema amendment required
- **SC-004**: Bonnie and project contributors agree the schema is ready for Phase 2+ use
