# Implementation Plan: Data Knowledge Platform

**Branch**: `master` | **Date**: 2026-03-01 | **Spec**: `.specify/specs/001-007`
**Input**: 7 feature specifications spanning production knowledge integration through domain packaging for the Databricks AI assistant.

## Summary

Build a layered knowledge pipeline that inherits validated production semantic wikis, extends them through Synapse DWH analysis, resolves column identity across all four data layers (Production → Synapse → Lake → UC), produces lineage descriptions, and packages everything into domain-organized knowledge artifacts with UC-compliant tags. The pipeline is file-based (Markdown in git), with UC push as a separate future spec.

## Technical Context

**Language/Version**: PowerShell 5.1 (pipeline orchestration), Cursor rules `.mdc` (phase logic), Markdown (output)
**Primary Dependencies**: Synapse MCP (live SQL queries), Databricks MCP (UC metadata), Atlassian MCP (Jira/Confluence context), git (version control + diff history)
**Storage**: File-based — Markdown wiki files in `knowledge/` folder, JSON config in `.specify/Configs/`
**Testing**: Agent test questions per domain package (SC from spec 007), golden file comparison for description format
**Target Platform**: Windows (Cursor IDE), Databricks workspace (final consumption)
**Project Type**: Knowledge pipeline / semantic documentation system
**Performance Goals**: N/A — batch pipeline, not real-time. Single table documentation takes ~5-10 minutes (14 phases).
**Constraints**: UC 1024-char description limit, agent token limits for domain packages, Synapse MCP query safety rules (no writes, row limits)
**Scale/Scope**: ~5 BU schemas, ~100s tables per schema, ~10k+ columns total. POC: 1 table (`Dim_Position`), then expand.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Agent-First Knowledge | ✅ PASS | All outputs are Markdown consumed by Databricks AI assistant |
| II. Code Is King | ✅ PASS | Authority hierarchy defined (v1.2.0): upstream wiki → Synapse code → live data → metadata → Confluence → human |
| III. Accuracy Over Coverage | ✅ PASS | POC starts with 1 table; quality gates enforce validation |
| IV. Incremental Delivery | ✅ PASS | 7 specs deliver independently; each produces usable output |
| V. Canonical Metadata Schema | ✅ PASS | Spec 001 defines schema as documented convention (Phase 11 template) |
| VI. Lineage Is First-Class | ✅ PASS | Spec 006 dedicated to lineage; Phase 13 traces production sources |
| VII. Domain Boundaries | ✅ PASS | Spec 007 packages by domain; many-to-many model from spec 002 |
| VIII. Don't Rebuild What Exists | ✅ PASS | Upstream wikis consumed read-only as tier 1 authority |

All gates pass. No violations to justify.

## Project Structure

### Documentation

```text
.specify/
├── memory/
│   ├── constitution.md          # Project governance (v1.2.0)
│   └── project-notes.md         # POC → full project reminders
├── Configs/
│   └── dwh-semantic-doc-config.json  # Upstream sources + target schemas
├── specs/
│   ├── 001-integrate-trading-platform-knowledge/
│   ├── 002-map-additional-business-units/
│   ├── 003-synapse-knowledge/
│   ├── 004-audit-lake-coverage/
│   ├── 005-resolve-column-metadata/
│   ├── 006-build-column-lineage-descriptions/
│   └── 007-package-agent-domains/
specs/master/
├── plan.md                      # This file
├── research.md                  # Phase 0 output
└── data-model.md                # Phase 1 output
```

### Pipeline Rules (execution logic)

```text
.cursor/rules/dwh-semantic-doc/
├── 01-structure-analysis.mdc
├── 02-live-data-sampling.mdc
├── 03-distribution-analysis.mdc
├── 04-lookup-resolution.mdc
├── 05-join-analysis.mdc
├── 06-business-logic-discovery.mdc
├── 07-view-dependency-scan.mdc
├── 08-procedure-reference-scan.mdc
├── 09-procedure-logic-extraction.mdc
├── 09b-etl-orchestration-analysis.mdc
├── 10-atlassian-knowledge-scan.mdc
├── 11-generate-documentation.mdc
├── 12-cross-object-enrichment.mdc
├── 13-production-lineage-mapping.mdc
├── 14-query-advisory-metadata.mdc
├── fk-lookup-reference.mdc
└── mcp-query-rules.mdc
```

### Knowledge Output (generated artifacts)

```text
knowledge/
├── synapse/
│   └── Wiki/
│       ├── DWH_dbo/                # Per-schema folders
│       │   ├── Dim_Position.md     # Individual object wikis
│       │   └── ...
│       └── BI_DB_dbo/
│           └── ...
├── coverage/
│   └── coverage-matrix.md         # Spec 004 output
├── columns/
│   ├── mappings/                   # Spec 005: column identity resolution
│   │   └── column-mappings.md
│   ├── descriptions/               # Spec 005: base descriptions
│   │   └── descriptions-only.md
│   └── lineage/                    # Spec 006: lineage descriptions
│       └── full-with-lineage.md
└── domains/
    ├── trading/                    # Spec 007: domain packages
    │   ├── index.md                # Domain summary + routing metadata
    │   └── (references to wiki files by path)
    ├── payments/
    ├── risk/
    └── ...
```

**Structure Decision**: File-based Markdown in git. Each spec's output goes to a dedicated subfolder under `knowledge/`. Domain packages reference source wiki files by path (no duplication). The `.cursor/rules/` folder contains the pipeline execution logic as Cursor rules.

## Execution Order & Dependencies

```text
Spec 001 ──→ Spec 002 ──→ Spec 003 ──→ Spec 004
  (schema)    (BU wikis)   (Synapse)    (lake audit)
                               │
                               ▼
                          Spec 005 ──→ Spec 006 ──→ Spec 007
                        (col resolve)  (lineage)   (domains+tags)
```

- **001** is prerequisite for all (defines canonical schema)
- **002** can run in parallel with 003 (independent BU mapping)
- **003** depends on 001 + upstream wikis from 002
- **004** can run after 003 (needs Synapse object inventory)
- **005** depends on 001-004 (needs all metadata gathered)
- **006** depends on 005 (takes base descriptions as input)
- **007** depends on 001-006 (final assembly)

## Complexity Tracking

No constitution violations to justify.
