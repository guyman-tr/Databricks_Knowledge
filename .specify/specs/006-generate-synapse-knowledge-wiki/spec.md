# Feature Specification: Generate Synapse Knowledge Wiki

**Feature Branch**: `006-generate-synapse-knowledge-wiki`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Replicate Bonnie's wiki generation approach for all Synapse schemas, producing both human-readable and machine-readable knowledge files that incorporate schema relationships, SP/function usage, transformation logic, and cross-references to PRDs/BRDs/JIRA.

## User Scenarios & Testing

### User Story 1 - Generate Wiki Per Synapse Schema (Priority: P1)

As a data knowledge engineer, I need a structured knowledge file for each Synapse schema that documents all its objects, relationships, and how they're used in ETL processes.

**Why this priority**: The wiki is the comprehensive reference that feeds Phase 8 domain packaging.

**Independent Test**: Generate a wiki file for the `bi_db` schema and validate it covers all objects, relationships, and SP references.

**Acceptance Scenarios**:

1. **Given** mapped Synapse schema metadata from Phase 3, **When** I generate a wiki file, **Then** it includes all tables, views, SPs, and functions with their descriptions and relationships
2. **Given** a wiki file, **When** I review its SP section, **Then** each SP shows: what it reads, what it writes, what transformations it performs, and its refresh schedule

---

### User Story 2 - Cross-Reference With External Documents (Priority: P2)

As a data knowledge engineer, I need the wiki to reference relevant PRDs, BRDs, and JIRA tickets where available, so that business context accompanies technical metadata.

**Why this priority**: Business context makes the knowledge useful beyond just technical documentation.

**Independent Test**: For one schema, find at least 2 related PRDs/BRDs/JIRA tickets and link them in the wiki.

**Acceptance Scenarios**:

1. **Given** a Synapse schema, **When** related PRDs/BRDs exist, **Then** they are referenced in the wiki with title, link, and relevance summary
2. **Given** no external documents exist for a schema, **When** the wiki is generated, **Then** the section is omitted rather than left empty

---

### User Story 3 - Dual Format: Human + Machine Readable (Priority: P2)

As a data knowledge engineer, I need the wiki output in both markdown (human) and structured JSON/YAML (machine), so that the same knowledge serves both Bonnie's QA use case and our agent use case.

**Why this priority**: The constitution mandates agent-first, but Bonnie's team also needs human-readable output.

**Independent Test**: Generate both formats for one schema and verify the JSON contains all information present in the markdown.

**Acceptance Scenarios**:

1. **Given** a schema wiki, **When** I export as markdown, **Then** it reads naturally with clear headings, tables, and descriptions
2. **Given** a schema wiki, **When** I export as structured data, **Then** it is valid JSON/YAML parseable by the agent without transformation

---

### Edge Cases

- What about schemas with 500+ objects -- how do we keep the wiki navigable?
- How do we handle SPs that span multiple schemas?
- What if PRD/BRD links are stale or broken?

## Requirements

### Functional Requirements

- **FR-001**: System MUST generate one wiki file per Synapse schema
- **FR-002**: System MUST include all objects, relationships, and ETL references per schema
- **FR-003**: System MUST cross-reference PRDs, BRDs, and JIRA tickets where available
- **FR-004**: System MUST output in both human-readable (markdown) and machine-readable (JSON) formats
- **FR-005**: System MUST merge metadata from Phases 1-5 into a cohesive narrative per schema

### Key Entities

- **SchemaWiki**: A comprehensive knowledge document for one Synapse schema
- **ExternalReference**: A link to a PRD, BRD, or JIRA ticket with context on its relevance

## Success Criteria

### Measurable Outcomes

- **SC-001**: Wiki files are generated for all Synapse schemas mapped in Phase 3
- **SC-002**: Each wiki file covers 100% of objects in its schema
- **SC-003**: At least 3 schemas have cross-references to external documents
- **SC-004**: Machine-readable output validates as proper JSON/YAML
