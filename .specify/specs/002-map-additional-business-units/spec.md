# Feature Specification: Map Additional Business Unit Schemas

**Feature Branch**: `002-map-additional-business-units`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Extend the production schema mapping methodology (sql-semantic-doc pipeline) beyond the trading platform to all other eToro business unit schemas.

## User Scenarios & Testing

### User Story 1 - Inventory All Production Schemas (Priority: P1)

As a data knowledge engineer, I need a complete list of all business unit schemas in the production SQL Server environment, so that I know the full scope of what needs mapping.

**Why this priority**: Can't map what we don't know exists. The inventory defines the work scope for this phase.

**Independent Test**: Query the production SQL Server metadata to list all schemas and their object counts. Cross-reference with known business units.

**Acceptance Scenarios**:

1. **Given** access to production SQL Server metadata, **When** I query for all schemas, **Then** I receive a complete list with object counts (tables, views, functions, SPs) per schema
2. **Given** the schema list, **When** I cross-reference with known business units, **Then** each schema is assigned to a business unit or flagged as "unassigned"

---

### User Story 2 - Map Schema Objects Using the Production Pipeline Methodology (Priority: P1)

As a data knowledge engineer, I need to apply the same rigorous mapping methodology used for the trading platform (tables, views, functions, relationships, keys, derived keys, column context) to each new business unit schema.

**Why this priority**: Consistency with the trading platform mapping ensures the canonical schema works across all domains.

**Independent Test**: Fully map one non-trading schema and validate all output conforms to the canonical metadata schema from Phase 1.

**Acceptance Scenarios**:

1. **Given** a business unit schema, **When** I apply the mapping methodology, **Then** all tables, views, and functions are cataloged with columns, types, and descriptions
2. **Given** a mapped schema, **When** I run relationship discovery, **Then** explicit PKs/FKs are captured and derived keys are flagged separately
3. **Given** a mapped schema, **When** I run sampling-based dictionary discovery, **Then** columns with implicit lookup patterns are identified and documented

---

### Edge Cases

- What happens when a schema has no explicit foreign keys (common in some business units)?
- How do we handle schemas with thousands of objects? → Only map objects with downstream presence in Synapse/lake. Use the Generic Pipeline mapping view to identify which production tables are exported.
- What if a business unit schema overlaps with the trading platform (shared tables)? → Source schema owns the DataObject (one wiki file). The object is tagged with all Domains that reference it. No duplication across Domain packages.

## Clarifications

### Session 2026-03-01

- Q: What is the relationship between BusinessUnit and Domain? → A: Many-to-many with clean separation. BusinessUnit/Schema is technical ownership (where an object physically lives — 1:1, a fact). Domain is a business-concept routing layer that spans schemas (1:many tagging). Examples: "Payments" domain spans eMoney + Trade schemas (deposits, inter-transfers). "Broker-Dealer" domain spans Trading + Dealing schemas (order → execution flow). A DataObject lives in one schema but can be tagged with multiple Domains.
- Q: For large schemas, does "fully mapped" mean every object or a prioritized subset? → A: Prioritize by downstream usage. Only map production objects that appear in Synapse DWH or lake. No need to map the entire production database — only what Synapse consumes.
- Q: When a shared table (e.g., Dictionary.Country) is used by multiple Domains, who owns the DataObject? → A: Source schema owns it. One DataObject per physical table, tagged with all Domains that reference it. No duplication.
- Q: Should newly mapped BU wikis become tier 1 authority sources in dwh-semantic-doc-config.json? → A: Yes, automatically. Each completed BU wiki is added to the config as a tier 1 upstream source, same authority as the trading platform wiki.

## Requirements

### Functional Requirements

- **FR-001**: System MUST enumerate all production SQL Server schemas with object counts
- **FR-002**: System MUST map each schema's tables, views, functions, and stored procedures **that have downstream presence in Synapse DWH or the data lake** to the canonical metadata schema. Production objects with no downstream usage are out of scope.
- **FR-003**: System MUST discover explicit relationships (PK/FK) and derived relationships via sampling
- **FR-004**: System MUST assign each schema to a BusinessUnit (technical ownership, 1:1) AND tag each DataObject with one or more Domains (business-concept routing, many-to-many). A Domain spans multiple BU schemas by nature (e.g., "Payments" spans eMoney + Trade; "Broker-Dealer" spans Trading + Dealing).
- **FR-005**: System MUST produce output identical in format to the trading platform wiki output
- **FR-006**: Upon completion, each newly mapped BU wiki MUST be added to `dwh-semantic-doc-config.json` as a tier 1 upstream knowledge source, making it automatically discoverable by the Synapse DWH documentation pipeline (spec 003)

### Key Entities

- **BusinessUnit**: An organizational unit that owns one or more production schemas (e.g., eMoney, Trading, Dealing). This is technical ownership — where objects physically live.
- **ProductionSchema**: A SQL Server schema belonging to exactly one BusinessUnit, containing tables/views/functions.
- **Domain**: A business-concept routing layer that spans multiple BU schemas. Examples: "Payments" (eMoney + Trade), "Broker-Dealer" (Trading + Dealing). A DataObject can participate in multiple Domains. The agent uses Domains, not schemas, for query routing.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of production schemas are inventoried with object counts
- **SC-002**: All schemas are assigned to a BusinessUnit (ownership) and every mapped DataObject is tagged with at least one Domain (routing)
- **SC-003**: At least 3 non-trading schemas have all Synapse/lake-consumed objects mapped using the canonical metadata schema
- **SC-004**: Mapped schemas pass validation against the Phase 1 canonical schema with zero format errors
