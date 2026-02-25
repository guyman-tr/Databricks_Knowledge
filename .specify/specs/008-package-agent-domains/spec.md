# Feature Specification: Package Agent Domains

**Feature Branch**: `008-package-agent-domains`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Define logical domains, package each as a self-contained knowledge artifact, build cross-domain routing logic, and deploy to the Databricks AI assistant.

## User Scenarios & Testing

### User Story 1 - Define Domain Boundaries (Priority: P1)

As a data knowledge engineer, I need to define the logical domains that organize all knowledge (Trading, Payments, Risk, Revenue, Customer, Compliance, etc.), so that the agent knows where to look for answers.

**Why this priority**: Domain boundaries are the routing mechanism. Without them, the agent has no way to scope its search.

**Independent Test**: Define domain boundaries and validate that every mapped object from Phases 2-6 falls into exactly one domain (or has explicit cross-domain edges).

**Acceptance Scenarios**:

1. **Given** all mapped objects, **When** I assign domain labels, **Then** 100% of objects belong to at least one domain
2. **Given** domain definitions, **When** I check for orphans, **Then** no object is unassigned
3. **Given** objects that span domains (e.g., a customer table used in both Trading and Payments), **When** I label them, **Then** they have a primary domain and explicit cross-domain references

---

### User Story 2 - Package Domains as Knowledge Artifacts (Priority: P1)

As a data knowledge engineer, I need each domain packaged as a self-contained artifact that the Databricks assistant can load and query independently.

**Why this priority**: Self-contained packages enable the agent to load only relevant context, staying within token limits.

**Independent Test**: Package the Trading domain and verify the Databricks assistant can answer 3 test questions using only that package.

**Acceptance Scenarios**:

1. **Given** a domain package, **When** the agent loads it, **Then** it contains all objects, columns, relationships, lineage, and descriptions for that domain
2. **Given** a domain package, **When** a user asks "what tables are in Trading?", **Then** the agent returns a complete, accurate list
3. **Given** a domain package, **When** a user asks about a specific column's lineage, **Then** the agent traces it using only the package's contents

---

### User Story 3 - Build Cross-Domain Routing (Priority: P2)

As a data knowledge engineer, I need the agent to route user questions to the right domain(s) and handle questions that span multiple domains seamlessly.

**Why this priority**: Users don't think in domains. They ask questions like "how is revenue calculated?" which might touch Trading, Payments, and Revenue domains.

**Independent Test**: Ask 5 cross-domain questions and verify the agent correctly identifies and queries all relevant domains.

**Acceptance Scenarios**:

1. **Given** a single-domain question (e.g., "what is the positions table?"), **When** the agent processes it, **Then** it routes to the Trading domain and answers correctly
2. **Given** a cross-domain question (e.g., "how does a deposit become revenue?"), **When** the agent processes it, **Then** it queries Payments and Revenue domains and synthesizes an answer
3. **Given** an ambiguous question (e.g., "show me customer data"), **When** the agent processes it, **Then** it either asks for clarification or shows results from all relevant domains

---

### Edge Cases

- What happens when a question doesn't match any domain?
- How do we handle domains with very few objects vs domains with thousands?
- What if domain boundaries change as new schemas are mapped?

## Requirements

### Functional Requirements

- **FR-001**: System MUST define domain boundaries covering all mapped objects
- **FR-002**: System MUST package each domain as a self-contained knowledge artifact (JSON/YAML)
- **FR-003**: System MUST include a routing index that maps keywords/concepts to domains
- **FR-004**: System MUST handle cross-domain queries by identifying all relevant domains
- **FR-005**: System MUST define a contract for how the Databricks assistant consumes domain packages
- **FR-006**: System MUST include test questions with expected answers for each domain

### Key Entities

- **Domain**: A logical grouping (Trading, Payments, Risk, Revenue, Customer, Compliance, etc.)
- **DomainPackage**: A self-contained artifact containing all knowledge for one domain
- **RoutingIndex**: A mapping from keywords/concepts/object names to domains
- **TestQuestion**: A question with expected answer used to validate agent behavior

## Success Criteria

### Measurable Outcomes

- **SC-001**: All mapped objects are assigned to a domain with zero orphans
- **SC-002**: At least 5 domains are packaged as self-contained artifacts
- **SC-003**: Each domain package includes at least 3 test questions with expected answers
- **SC-004**: The agent correctly answers at least 80% of test questions (single-domain and cross-domain)
- **SC-005**: Cross-domain routing correctly identifies all relevant domains for at least 70% of multi-domain test questions
