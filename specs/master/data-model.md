# Data Model: Data Knowledge Platform

**Date**: 2026-03-01

## Core Entities

### DataObject
A table, view, function, or stored procedure at a specific layer. Each layer instance is a **separate** DataObject.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Object name (e.g., `Dim_Position`) |
| schema | string | Schema name (e.g., `DWH_dbo`) |
| layer | enum | `production` / `synapse` / `lake` / `uc` |
| object_type | enum | `table` / `view` / `function` / `stored_procedure` |
| columns | Column[] | List of columns |
| relationships | Relationship[] | Explicit and derived relationships |
| lineage_upstream | LineageEdge[] | Links to upstream DataObjects |
| lineage_downstream | LineageEdge[] | Links to downstream DataObjects |
| description | string | Business meaning |
| business_unit | string | Owning BU/schema (1:1) |
| domains | string[] | Routing tags (many-to-many) |
| tags | UCTagSet | Mandatory UC tags |
| source_wiki_path | string? | Path to the wiki file for this object |

**Identity**: `{layer}.{schema}.{name}` is unique.

### Column
A field within a DataObject.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Column name |
| type | string | Data type (e.g., `int`, `varchar(50)`) |
| nullable | boolean | Whether column allows NULLs |
| description | string | Business meaning (≤1024 chars for UC) |
| lineage_sources | ColumnLineageSource[] | Upstream column(s) this derives from |
| pii | enum | `direct` / `indirect` / `none` |
| is_distribution_key | boolean | Synapse distribution key |
| lookup_values | LookupValue[]? | Resolved enum/ID values |
| source_attribution | SourceAttribution | Which source contributed this description |

### Relationship
A connection between DataObjects or columns.

| Field | Type | Description |
|-------|------|-------------|
| from_object | string | Source DataObject identity |
| from_column | string | Source column name |
| to_object | string | Target DataObject identity |
| to_column | string | Target column name |
| type | enum | `explicit_fk` / `derived_join` / `inferred_naming` |
| confidence | enum | `high` / `medium` / `low` |
| discovered_by | string | Which phase discovered this (e.g., `phase_05_join`) |

### LineageEdge
A cross-layer connection between DataObjects.

| Field | Type | Description |
|-------|------|-------------|
| source | string | Upstream DataObject identity |
| target | string | Downstream DataObject identity |
| transformation | string | How data transforms (e.g., "imported via Generic Pipeline", "aggregated by SP_Load_Dim_Position") |
| lineage_type | enum | `passthrough` / `transformed` / `derived` |

### ColumnLineageSource
Upstream source for a single column.

| Field | Type | Description |
|-------|------|-------------|
| source_object | string | Source DataObject identity |
| source_column | string | Source column name |
| transformation | string | How the value transforms (e.g., "direct copy", "SUM aggregation", "COALESCE fallback") |
| is_derived | boolean | True if no direct upstream (e.g., GETDATE(), hardcoded) |
| derived_expression | string? | The expression, if derived (e.g., "GETDATE()") |

### ColumnMapping (Spec 005)
Resolved identity linking the same column across layers.

| Field | Type | Description |
|-------|------|-------------|
| canonical_name | string | The agreed column name |
| instances | ColumnInstance[] | One per layer where this column exists |
| base_description | string | Authoritative description (from highest-tier source) |
| match_method | enum | `exact_name` / `fuzzy_name` / `type_match` / `manual` |

### ColumnInstance
One layer's representation of a mapped column.

| Field | Type | Description |
|-------|------|-------------|
| layer | enum | `production` / `synapse` / `lake` / `uc` |
| object_identity | string | DataObject identity |
| column_name | string | Name in this layer (may differ) |
| type | string | Data type in this layer |

### Domain (Spec 007)
A logical grouping for agent routing.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Domain name (e.g., `trading`, `payments`) |
| keywords | string[] | Routing keywords and concept aliases |
| objects | string[] | DataObject identities belonging to this domain |
| folder_path | string | Path to domain package folder |

### UCTagSet (Spec 007)
Mandatory tags per Confluence "Databricks AI Agent - Data layer Rules".

| Field | Type | Description |
|-------|------|-------------|
| owner | string | BU/schema ownership (inferred) |
| domain | string | Business domain (inferred from Phase 13) |
| layer | string | Data layer: `stg`/`int`/`dim`/`fct`/`kpi`/`vw` (inferred from naming) |
| refresh_frequency | string | `hourly`/`daily`/`weekly`/`ad-hoc` (inferred from ETL orchestration) |
| sla | string? | SLA target (manual — not inferrable) |
| source_system | string | `Synapse`/`etorodb`/etc. (inferred from lineage) |
| data_classification | string? | `public`/`internal`/`confidential` (heuristic) |
| pii | string | `none`/`indirect`/`direct` (inferred from column analysis) |
| certified | string? | `gold`/`silver`/`bronze` (manual — not inferrable) |

### SourceAttribution (Spec 001)
Tracks which knowledge source contributed each metadata element.

| Field | Type | Description |
|-------|------|-------------|
| source | string | Which source (e.g., `upstream_wiki`, `synapse_sp`, `live_sampling`) |
| authority_tier | int | 1-6 per constitution hierarchy |
| contributed_at | string | When this metadata was captured |

## Entity Relationships

```text
DataObject 1──* Column
DataObject *──* Domain          (many-to-many via domain tags)
DataObject 1──1 BusinessUnit    (ownership)
DataObject *──* DataObject      (via LineageEdge)
Column     *──* Column          (via ColumnLineageSource)
Column     1──* LookupValue
Column     1──1 SourceAttribution
ColumnMapping 1──* ColumnInstance
Domain     1──1 DomainPackage   (folder on disk)
DataObject 1──1 UCTagSet
```

## State Transitions

### Pipeline Execution per Object
```
not_documented → phase_01_structure → phase_02_sampling → ... → phase_14_advisory → documented
```
Each phase is idempotent. Full regeneration on re-run.

### Column Description Lifecycle
```
no_description → upstream_wiki_inherited → synapse_enriched → uc_formatted → pushed (future spec)
```
