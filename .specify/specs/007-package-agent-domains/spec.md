# Feature Specification: Package Agent Domains

**Feature Branch**: `007-package-agent-domains`
**Created**: 2026-02-25
**Status**: Draft
**Input**: Define logical domains and package each as a self-contained knowledge artifact with UC tags. This spec produces the knowledge files and tag structure that enable agent routing; the actual Databricks AI assistant wiring is a separate future spec.

## User Scenarios & Testing

### User Story 1 - Define Domain Boundaries (Priority: P1)

As a data knowledge engineer, I need to define the logical domains that organize all knowledge (Trading, Payments, Risk, Revenue, Customer, Compliance, etc.), so that the agent knows where to look for answers.

**Why this priority**: Domain boundaries are the routing mechanism. Without them, the agent has no way to scope its search.

**Independent Test**: Define domain boundaries and validate that every mapped object from specs 001-006 is tagged with at least one domain (many-to-many; source schema = ownership per spec 002).

**Acceptance Scenarios**:

1. **Given** all mapped objects, **When** I assign domain labels, **Then** 100% of objects belong to at least one domain
2. **Given** domain definitions, **When** I check for orphans, **Then** no object is unassigned
3. **Given** objects that span domains (e.g., a customer table used in both Trading and Payments), **When** I label them, **Then** they are tagged with all relevant domains and appear in each domain's package

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

### User Story 3 - Produce Routing Metadata (Priority: P2)

As a data knowledge engineer, I need each domain package to include routing metadata (keywords, object names, concept mappings) so that a future agent spec can wire up question routing without re-analyzing the knowledge.

**Why this priority**: Without routing metadata baked into the packages, the agent spec would have to re-derive domain boundaries from scratch.

**Independent Test**: Inspect a domain package and verify it contains enough metadata for an external routing system to map questions to it.

**Acceptance Scenarios**:

1. **Given** a domain package, **When** I inspect its routing metadata, **Then** it includes keyword lists, object names, and concept aliases for that domain
2. **Given** an object tagged with multiple domains, **When** I check the routing metadata of each domain, **Then** the object appears in all relevant domain packages with cross-references

---

### Edge Cases

- What happens when a question doesn't match any domain?
- How do we handle domains with very few objects vs domains with thousands?
- What if domain boundaries change as new schemas are mapped?

## Requirements

### Functional Requirements

- **FR-001**: System MUST define domain boundaries covering all mapped objects
- **FR-002**: System MUST package each domain as Markdown files in domain-organized folders (e.g., `knowledge/domains/trading/`)
- **FR-003**: System MUST include routing metadata (keywords, concept aliases, object names) in each domain package
- **FR-004**: System MUST tag objects belonging to multiple domains with cross-domain references
- **FR-005**: System MUST produce domain packages in a format consumable by a future agent spec (file-based, self-contained)
- **FR-006**: System MUST include test questions with expected answers for each domain
- **FR-007**: System MUST generate UC tags per the mandatory standard (Confluence: "Databricks AI Agent - Data layer Rules", page 13960052801). Inferrable tags: `owner` (from BU/schema), `domain` (from Phase 10A/10B lineage), `layer` (from naming convention), `refresh_frequency` (from ETL orchestration), `source_system` (from lineage chain), `data_classification` (heuristic). Non-inferrable tags (`sla`, `certified`) left blank for manual assignment.
- **FR-008**: System MUST infer `pii` tag at column level using two tiers: `direct` = column IS PII (name, email, phone, address, DOB, IP, etc. per Confluence PII mapping pages 12044435462 and 11908645178), `indirect` = column can JOIN to a table with direct PII (e.g., GCID, CID, CustomerID). `none` otherwise. The pipeline can infer this from column names, upstream wiki column descriptions, and the known PII column lists in Confluence.
- **FR-009**: Every SKILL.md artifact emitted by this spec (or any skill-producing successor spec) MUST conform to the eToro DataPlatform DE skill-creator schema mirrored at `.specify/memory/skill-schema.md`, per Constitution Principle X (NON-NEGOTIABLE). Conformance includes: (a) frontmatter fields `id`, `name`, `description` (≥30 chars, third-person), `triggers`, `required_tables` (≥1 fully-qualified UC name), `version`, `owner`, `last_validated_at` (ISO date ≤90 days at deployment); (b) required body sections `## When to Use`, `## Scope` (with `In scope:` / `Out of scope:` / `Last verified:` lines), `## Critical Warnings` (numbered list, severity-ordered Tier 1 → Tier 2 → Tier 3); (c) pre-creation overlap check against `/Workspace/.assistant/skills/*` to prevent duplicate triggers / `required_tables` / domain; (d) pre-commit lint via `tools/skills/lint_skill.py` with exit code 0. Cross-domain skills use a `cross-` filename / `id` prefix and list `required_tables` from each super-domain spanned, but otherwise follow the identical schema and CI checks. Workflow scaffolded by `/speckit.skill` (`.cursor/commands/speckit.skill.md`) and `.specify/templates/skill-template.md`.

### Key Entities

- **Domain**: A logical grouping (Trading, Payments, Risk, Revenue, Customer, Compliance, etc.)
- **DomainPackage**: A self-contained artifact containing all knowledge for one domain
- **RoutingIndex**: A mapping from keywords/concepts/object names to domains
- **TestQuestion**: A question with expected answer used to validate agent behavior
- **UCTagSet**: The mandatory tag set from the Databricks AI Agent Data Layer Rules standard, inferred from pipeline outputs where possible

## Clarifications

### Session 2026-03-01

- Q: Is agent routing logic in scope? → A: No. This spec produces domain-organized knowledge files and tags. Agent wiring (Genie, custom agent, prompt engineering) is a separate future spec.
- Q: Single-domain or many-to-many domain assignment? → A: Many-to-many, aligned with spec 002. Objects tagged with all relevant domains; source schema = ownership (BusinessUnit).
- Q: What format for domain packages? → A: Markdown files in domain-organized folders (e.g., knowledge/domains/trading/). Routing metadata and indexing handled by the future agent wiring spec.
- Q: Duplicate wiki files per domain or single source with references? → A: Single source file in BU/schema folder; domain packages reference it (path + summary). No duplication.
- Q: Which upstream specs does 007 consume? → A: All outputs from specs 001-006. This is the final assembly step.

## Success Criteria

### Measurable Outcomes

- **SC-001**: All mapped objects are assigned to a domain with zero orphans
- **SC-002**: At least 5 domains are packaged as self-contained artifacts
- **SC-003**: Each domain package includes at least 3 test questions with expected answers
- **SC-004**: Each domain package contains routing metadata (keywords, object names, concept aliases)
- **SC-005**: Objects tagged with multiple domains appear in all relevant domain packages with cross-references
