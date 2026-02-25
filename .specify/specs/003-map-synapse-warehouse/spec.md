# Feature Specification: Map Synapse Data Warehouse

**Feature Branch**: `003-map-synapse-warehouse`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Map all Synapse DWH schemas (dealing, bi_db, exw, emoney, etc.) including stored procedures, functions, views, and ETL transformation logic with full lineage back to production sources.

## User Scenarios & Testing

### User Story 1 - Catalog All Synapse Schemas and Objects (Priority: P1)

As a data knowledge engineer, I need a complete inventory of all Synapse schemas and their objects, so that I know the full scope of the DWH layer.

**Why this priority**: The inventory is the foundation for all downstream mapping work.

**Independent Test**: Query Synapse metadata for schemas `dealing`, `bi_db`, `exw`, `emoney` and list all objects per schema.

**Acceptance Scenarios**:

1. **Given** access to Synapse metadata, **When** I query for all schemas, **Then** I receive a list including at minimum: dealing, bi_db, exw, emoney with all tables, views, SPs, and functions
2. **Given** the object list, **When** I compare against the DataPlatform Git repo, **Then** every SP/function in the repo maps to a Synapse object

---

### User Story 2 - Parse ETL Transformation Logic (Priority: P1)

As a data knowledge engineer, I need to understand what each stored procedure and function does -- what computations, aggregations, and classifications it applies -- so that the knowledge system can explain transformations to agent users.

**Why this priority**: Synapse adds value through transformations. Without understanding the ETL logic, the knowledge layer is incomplete.

**Independent Test**: Parse one complex SP (e.g., a revenue calculation SP in bi_db) and extract: input sources, output targets, transformation summary.

**Acceptance Scenarios**:

1. **Given** a stored procedure, **When** I parse its SQL, **Then** I can identify all source tables/views it reads from
2. **Given** a stored procedure, **When** I parse its SQL, **Then** I can identify all target tables it writes to
3. **Given** a stored procedure, **When** I summarize its logic, **Then** the summary captures the key transformations (aggregations, filters, joins, CASE logic) in plain language

---

### User Story 3 - Trace Lineage: Production to Synapse (Priority: P2)

As a data knowledge engineer, I need to trace each Synapse object back to its production source(s), so that the agent can answer "where does this data come from?"

**Why this priority**: Lineage is a core principle of the constitution. This connects the production layer (Phase 2) to the DWH layer.

**Independent Test**: For a known Synapse table, trace its lineage back through SPs to the lake import and then to the production source.

**Acceptance Scenarios**:

1. **Given** a Synapse table, **When** I trace its lineage, **Then** I can identify the production source table(s) it ultimately derives from
2. **Given** a lineage chain, **When** I record it in the canonical schema, **Then** both the first upstream source and the immediate parent are captured

---

### Edge Cases

- What happens when a Synapse object has no clear production source (derived entirely from other Synapse objects)?
- How do we handle SPs that are in Git but no longer exist in Synapse (deprecated)?
- What about SPs that write to multiple target tables?

## Requirements

### Functional Requirements

- **FR-001**: System MUST enumerate all Synapse schemas with complete object lists
- **FR-002**: System MUST cross-reference Synapse objects with the DataPlatform Git repo source code
- **FR-003**: System MUST parse SP/function SQL to extract source tables, target tables, and transformation summaries
- **FR-004**: System MUST trace lineage from Synapse objects back to production sources via lake imports
- **FR-005**: System MUST record transformation logic in a structured, agent-parseable format

### Key Entities

- **SynapseSchema**: A schema in the Synapse DWH (dealing, bi_db, exw, emoney, etc.)
- **ETLObject**: A stored procedure or function that performs transformations
- **TransformationSummary**: A structured description of what an ETL object does (inputs, outputs, logic)

## Success Criteria

### Measurable Outcomes

- **SC-001**: All Synapse schemas are inventoried with complete object counts
- **SC-002**: At least 80% of SPs/functions have parsed transformation summaries
- **SC-003**: Lineage is traced for at least 50% of Synapse tables back to production sources
- **SC-004**: All output conforms to the Phase 1 canonical metadata schema
