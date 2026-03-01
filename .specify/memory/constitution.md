<!--
Sync Impact Report — v1.1.1 → v1.2.0 (MINOR)

Version change: 1.1.1 → 1.2.0
Bump rationale: Material change to Principle II source authority hierarchy —
  upstream semantic wiki elevated from tier 4 to tier 1.

Modified principles:
  - II. Code Is King: Source authority hierarchy reordered.
    OLD: 1=Live code, 2=Live data, 3=Metadata, 4=Upstream wiki, 5=Confluence, 6=Human
    NEW: 1=Upstream wiki, 2=Live code, 3=Live data, 4=Metadata, 5=Confluence, 6=Human
    Rationale: The upstream wiki has already undergone the full code-is-king
    pipeline on production sources. We inherit that work as the authoritative
    starting point. Synapse code wins only for DWH-specific logic.

Added sections: none
Removed sections: none

Pipeline rules requiring updates:
  - 10-atlassian-knowledge-scan.mdc  ✅ updated (reproduced hierarchy reordered)
  - 11-generate-documentation.mdc   ✅ updated (inline hierarchy reordered)
  - 04-lookup-resolution.mdc        ✅ updated (resolution strategy: wiki first)
  - fk-lookup-reference.mdc         ✅ updated (resolution priority: wiki first)
  - 12-cross-object-enrichment.mdc  ✅ no update needed (enrichment approach unchanged)
  - 13-production-lineage-mapping.mdc ✅ no update needed (lineage approach unchanged)

Specs requiring updates:
  - 003-synapse-knowledge/spec.md    ✅ updated (Layer 1 → "Authoritative Starting Point")

Templates requiring updates:
  - plan-template.md        ✅ no update needed (generic Constitution Check)
  - spec-template.md        ✅ no update needed
  - tasks-template.md       ✅ no update needed
  - checklist-template.md   ✅ no update needed
  - agent-file-template.md  ✅ no update needed

Follow-up TODOs: none
-->

# Data Knowledge Platform Constitution

## Core Principles

### I. Agent-First Knowledge (NON-NEGOTIABLE)
Every knowledge artifact produced by this project must be machine-readable and consumable by the Databricks AI assistant. Human readability is a bonus, not the goal. If a piece of knowledge can't be programmatically parsed, routed, and served by an agent, it doesn't ship.

### II. Code Is King (NON-NEGOTIABLE)
When information from different sources conflicts, the hierarchy is absolute. The production pipeline's constitution (DB_Schema, Section XII) establishes the principle: JOIN analysis beats explicit FKs beats naming heuristics -- because "the application code reveals the TRUE relationships." This DWH pipeline inherits that principle and extends it: the upstream semantic wiki IS the output of that strict production analysis, so it starts as the authoritative baseline for everything we document here.

**Source authority hierarchy (higher wins):**

1. **Upstream semantic wikis** (production wiki, previously generated docs) -- already validated through the full code-is-king pipeline on production sources; this is our starting point, not a fallback. The upstream wiki has already done JOIN analysis, procedure logic extraction, live data sampling, application code tracing, and cross-object enrichment on the production layer. We inherit that work.
2. **Live code** (Synapse SP definitions, view definitions, function bodies in `sys.sql_modules`) -- Synapse-layer ground truth for ETL transformations and DWH-specific logic
3. **Live data** (sampling results, actual enum values, row patterns) -- empirical evidence from the DWH layer
4. **Metadata views** (`INFORMATION_SCHEMA`, `sys.*`, distribution properties) -- structural truth
5. **Confluence / Jira** (business documentation) -- intent and context, frequently stale
6. **Human descriptions** (column comments, verbal explanations) -- lowest weight

**Why upstream wiki is #1:** We are not recreating production knowledge -- we start from the Synapse DWH layer. The upstream wiki has already gone through an even stricter code-is-king analysis on the production source code (SSDT repos, C# application code, live production data). Synapse SPs primarily import and transform data FROM those production sources. When a Synapse column is a passthrough from production, the upstream wiki's deep semantic analysis is more authoritative than anything we can re-derive from Synapse ETL code.

**When Synapse code wins over upstream wiki:** Synapse live code (tier 2) is authoritative for DWH-specific logic: new derived columns, ETL transformations, aggregation logic, and any business rules that exist ONLY in the DWH layer. If a Synapse SP adds a computed column that doesn't exist in production, the SP definition is the sole authority.

**Recency tiebreaker:** Within the same tier, newer evidence outweighs older. A Confluence page from 2025 outweighs one from 2021. A wiki file regenerated last week outweighs one from six months ago. Always prefer the freshest source at a given tier.

**Collision resolution in output:** If Phase 2 (sampling) discovers values that contradict Phase 10 (Atlassian), the sampled values are authoritative. The Atlassian source is cited as "historical context" with its date, so analysts can see the evolution. Undocumented values discovered via code or data are flagged for investigation, not silently dropped. If Synapse live data reveals enum values not in the upstream wiki, both sources are valid -- the wiki provides the known mappings and the new values are flagged for investigation upstream.

### III. Accuracy Over Coverage
It is better to have 50 objects with correct, verified metadata than 500 with guesses. Every column description, relationship, and lineage trace must be validated against the actual data or code. When uncertain, mark it explicitly rather than fabricating.

### IV. Incremental Delivery
The project spans 7 specifications across production SQL Server, Synapse DWH, Data Lake, and Unity Catalog. Each phase delivers independently usable output. No phase should block on perfection of a prior phase -- deliver what's ready, iterate on what's not.

### V. Canonical Metadata Schema
All knowledge -- regardless of source layer (production, Synapse, lake, UC) -- must conform to a single, agreed-upon metadata schema. This schema defines what a "known object" looks like: name, schema, type, columns, relationships, lineage, description, domain, tags. Deviations require explicit justification.

### VI. Lineage Is First-Class
Every object and column must trace back to its upstream source(s). Lineage is not optional metadata -- it is the backbone of the knowledge system. The agent needs lineage to answer "where does this data come from?" and "what transformations happened?"

### VII. Domain Boundaries
Knowledge is organized into domains (Trading, Payments, Risk, Revenue, etc.). Each domain is self-contained with its own knowledge package. Cross-domain relationships are explicit edges, not implicit assumptions. The agent uses domain boundaries for routing.

### VIII. Don't Rebuild What Exists
Existing upstream knowledge sources — such as semantic wikis generated for production schemas — are consumed as-is. We extend the methodology to new schemas and layers; we don't re-derive what has already been mapped. Upstream sources are declared in `dwh-semantic-doc-config.json` and referenced by path during lineage tracing and lookup resolution.

## Data Stack Scope

This project covers the full eToro data path:
- **Production SQL Server**: Source of truth for business data (multiple business unit schemas)
- **Data Lake**: Raw exports via the Generic Pipeline (hourly/daily)
- **Synapse DWH**: Incremental imports with ETL transformations (SPs, functions, views)
- **Unity Catalog (Databricks)**: Target catalog where metadata, descriptions, and tags are published

Knowledge flows downstream: Production -> Lake -> Synapse -> Unity Catalog. Metadata flows upstream: we gather knowledge at every layer and propagate it back to UC.

## Quality Gates

- No spec proceeds to implementation without validation against the canonical metadata schema
- Column descriptions must fit Unity Catalog's 1024-character limit
- Every domain package must include at least 3 test questions with expected agent responses
- Gap analysis (what's NOT in the lake) is as important as mapping what IS

## Governance

This constitution governs all phases of the Data Knowledge Platform. Amendments require documentation and agreement between project contributors. The canonical metadata schema (Phase 1 output) becomes binding once ratified.

**Version**: 1.2.0 | **Ratified**: 2026-02-25 | **Last Amended**: 2026-03-01
