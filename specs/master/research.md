# Research: Data Knowledge Platform

**Date**: 2026-03-01

## R1: Upstream Wiki File Format

**Decision**: Upstream wikis follow the sql-semantic-doc Phase 11 template (Markdown with structured sections: Business Meaning, Business Logic, Elements, Relationships, Lineage, etc.)
**Rationale**: The DB_Schema pipeline already produces these files. Spec 001 consumes them as-is. The canonical schema IS the Phase 11 template — not a JSON Schema.
**Alternatives considered**: JSON Schema for canonical format → rejected (documented convention is simpler and already exists).

## R2: Column Identity Matching Strategy

**Decision**: Match by name first (exact), then fuzzy match (case-insensitive, underscore normalization), then type comparison for remaining ambiguities.
**Rationale**: The Generic Pipeline preserves column names from production → lake. Synapse SPs may rename columns (e.g., `PositionID` → `PosID`), but this is rare. Name matching handles 90%+ of cases.
**Alternatives considered**: Schema-level matching only → rejected (misses renamed columns). ML-based matching → rejected (overkill for POC).

## R3: UC Description Format Within 1024 Characters

**Decision**: Two output formats generated for evaluation: (1) descriptions-only (base meaning from spec 005), (2) full-with-lineage (meaning + lineage chain from spec 006). Post-POC decision on which to use as the UC description.
**Rationale**: Without real data, we can't know which format fits. Generating both lets us compare readability and character budget.
**Alternatives considered**: Single format only → rejected (risk of choosing wrong format without data).

## R4: PII Inference Approach

**Decision**: Two-tier system: `direct` (column IS PII — matched against known PII column lists from Confluence pages 12044435462 and 11908645178) and `indirect` (column can JOIN to a table with direct PII — e.g., GCID, CID, CustomerID).
**Rationale**: Confluence already maintains PII column mappings. Column names are consistent enough for pattern matching. JOIN-based indirect PII is discoverable from the lineage chain.
**Alternatives considered**: ML-based PII detection → rejected (pattern matching sufficient given known column naming conventions).

## R5: Domain Package Content

**Decision**: Markdown files in domain-organized folders. Single source wiki file in BU/schema folder; domain package contains an index.md with routing metadata (keywords, object names, concept aliases) and references to wiki files by path.
**Rationale**: No file duplication avoids content drift. Markdown is consistent with the entire pipeline output. Routing metadata enables a future agent spec to wire up without re-analyzing.
**Alternatives considered**: JSON manifests → deferred to post-POC (see project-notes.md). Full file duplication per domain → rejected (drift risk).

## R6: Synapse MCP Query Safety

**Decision**: All Synapse queries go through `execute_sql_read_only`. Row limits enforced per mcp-query-rules.mdc. No DDL/DML via the pipeline.
**Rationale**: Pipeline is read-only by design. MCP query rules already codified in `.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc`.
**Alternatives considered**: Direct pyodbc connection → rejected (MCP provides consistent interface with safety guardrails).

## R7: Pipeline Re-run Behavior

**Decision**: Full regeneration of the wiki file when triggered by change. Previous version preserved in git history for diffing. Not scheduled — triggered by upstream wiki updates, new SPs discovered, or manual invocation.
**Rationale**: Consistent with DB_Schema pipeline model. Full regeneration is simpler than incremental merge and git provides the diff for free.
**Alternatives considered**: Incremental merge → rejected (complex and error-prone). Scheduled runs → rejected (wasteful when changes are infrequent).

## No Outstanding Unknowns

All NEEDS CLARIFICATION items have been resolved through the spec clarification sessions.
