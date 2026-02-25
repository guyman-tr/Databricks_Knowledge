# Data Knowledge Platform Constitution

## Core Principles

### I. Agent-First Knowledge (NON-NEGOTIABLE)
Every knowledge artifact produced by this project must be machine-readable and consumable by the Databricks AI assistant. Human readability is a bonus, not the goal. If a piece of knowledge can't be programmatically parsed, routed, and served by an agent, it doesn't ship.

### II. Accuracy Over Coverage
It is better to have 50 objects with correct, verified metadata than 500 with guesses. Every column description, relationship, and lineage trace must be validated against the actual data or code. When uncertain, mark it explicitly rather than fabricating.

### III. Incremental Delivery
The project spans 8 phases across production SQL Server, Synapse DWH, Data Lake, and Unity Catalog. Each phase delivers independently usable output. No phase should block on perfection of a prior phase -- deliver what's ready, iterate on what's not.

### IV. Canonical Metadata Schema
All knowledge -- regardless of source layer (production, Synapse, lake, UC) -- must conform to a single, agreed-upon metadata schema. This schema defines what a "known object" looks like: name, schema, type, columns, relationships, lineage, description, domain, tags. Deviations require explicit justification.

### V. Lineage Is First-Class
Every object and column must trace back to its upstream source(s). Lineage is not optional metadata -- it is the backbone of the knowledge system. The agent needs lineage to answer "where does this data come from?" and "what transformations happened?"

### VI. Domain Boundaries
Knowledge is organized into domains (Trading, Payments, Risk, Revenue, etc.). Each domain is self-contained with its own knowledge package. Cross-domain relationships are explicit edges, not implicit assumptions. The agent uses domain boundaries for routing.

### VII. Don't Rebuild What Exists
Bonnie's production-layer work (trading platform schemas, relationships, column context) is consumed as-is via MCP. We extend her methodology to new schemas and layers -- we don't re-derive what she's already mapped. Same principle applies to any existing metadata sources.

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

**Version**: 1.0.0 | **Ratified**: 2026-02-25 | **Last Amended**: 2026-02-25
