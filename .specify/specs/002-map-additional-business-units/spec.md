# Feature Specification: Map Additional Business Unit Schemas

**Feature Branch**: `002-map-additional-business-units`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Extend Bonnie's production schema mapping methodology beyond the trading platform to all other eToro business unit schemas.

## User Scenarios & Testing

### User Story 1 - Inventory All Production Schemas (Priority: P1)

As a data knowledge engineer, I need a complete list of all business unit schemas in the production SQL Server environment, so that I know the full scope of what needs mapping.

**Why this priority**: Can't map what we don't know exists. The inventory defines the work scope for this phase.

**Independent Test**: Query the production SQL Server metadata to list all schemas and their object counts. Cross-reference with known business units.

**Acceptance Scenarios**:

1. **Given** access to production SQL Server metadata, **When** I query for all schemas, **Then** I receive a complete list with object counts (tables, views, functions, SPs) per schema
2. **Given** the schema list, **When** I cross-reference with known business units, **Then** each schema is assigned to a business unit or flagged as "unassigned"

---

### User Story 2 - Map Schema Objects Using Bonnie's Methodology (Priority: P1)

As a data knowledge engineer, I need to apply the same rigorous mapping methodology Bonnie used (tables, views, functions, relationships, keys, derived keys, column context) to each new business unit schema.

**Why this priority**: Consistency with the trading platform mapping ensures the canonical schema works across all domains.

**Independent Test**: Fully map one non-trading schema and validate all output conforms to the canonical metadata schema from Phase 1.

**Acceptance Scenarios**:

1. **Given** a business unit schema, **When** I apply the mapping methodology, **Then** all tables, views, and functions are cataloged with columns, types, and descriptions
2. **Given** a mapped schema, **When** I run relationship discovery, **Then** explicit PKs/FKs are captured and derived keys are flagged separately
3. **Given** a mapped schema, **When** I run sampling-based dictionary discovery, **Then** columns with implicit lookup patterns are identified and documented

---

### Edge Cases

- What happens when a schema has no explicit foreign keys (common in some business units)?
- How do we handle schemas with thousands of objects -- do we prioritize?
- What if a business unit schema overlaps with the trading platform (shared tables)?

## Requirements

### Functional Requirements

- **FR-001**: System MUST enumerate all production SQL Server schemas with object counts
- **FR-002**: System MUST map each schema's tables, views, functions, and stored procedures to the canonical metadata schema
- **FR-003**: System MUST discover explicit relationships (PK/FK) and derived relationships via sampling
- **FR-004**: System MUST assign each schema to a business domain
- **FR-005**: System MUST produce output identical in format to Bonnie's trading platform output

### Key Entities

- **BusinessUnit**: An organizational unit that owns one or more schemas (e.g., Payments, Risk, Compliance)
- **ProductionSchema**: A SQL Server schema belonging to a business unit, containing tables/views/functions

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of production schemas are inventoried with object counts
- **SC-002**: All schemas are assigned to a business domain
- **SC-003**: At least 3 non-trading schemas are fully mapped using the canonical metadata schema
- **SC-004**: Mapped schemas pass validation against the Phase 1 canonical schema with zero format errors
