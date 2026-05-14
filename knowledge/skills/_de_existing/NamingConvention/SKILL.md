# NamingConvention Skill

## Description
Databricks data layer naming conventions and object creation standards. Covers two distinct naming systems:
1. **Persistent tables in `de_output` / `bi_output`** — name derived from ADLS storage path
2. **Semantic layer objects in `etoro_kpi*`** — name derived from domain/layer/entity convention

## Scope
- Creating persistent EXTERNAL tables in `de_output` / `de_output_stg` (and `bi_output` / `bi_output_stg`)
- Naming views, functions, and objects in `etoro_kpi`, `etoro_kpi_prep`, `etoro_kpi_prep_stg` schemas
- Interactive object name builder with guided prompts
- Enforcing mandatory tags, descriptions, column standards, and lineage rules
- **Mandatory `UpdateDate` column** for all persistent tables

---

## Part A: Persistent Table Creation (DE_OUTPUT)

Use this when the user needs a **persistent EXTERNAL table** backed by ADLS storage. The user will typically say things like "I need a table for X", "create a persistent table", "store this as a table", etc.

### The Rule: Table Name = Flattened ADLS Path

The UC table name is mechanically derived from the ADLS storage path. No creativity, no interpretation.

### Environments

| Environment | Schema | Storage Account | ADLS Root |
|---|---|---|---|
| **STG** | `main.de_output_stg` | `stgdpdlwe` | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/DE_OUTPUT/` |
| **PROD** | `main.de_output` | `dldataplatformprodwe` | `abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/` |

### Path-to-Name Conversion

```
ADLS path:  DE_OUTPUT/{Segment1}/{Segment2}/.../{SegmentN}/
UC name:    de_output_{segment1}_{segment2}_..._{segmentn}
```

Rules:
- Lowercase everything in the UC name
- Replace `/` with `_`
- Replace `-` and `.` with `_`
- ADLS path segments use `Title_Case` (each word capitalized, underscores within segments preserved)
- The `DE_OUTPUT` prefix in the path becomes `de_output_` prefix in the table name

### Real Examples

| ADLS Path (after root) | UC Table Name |
|---|---|
| `DE_OUTPUT/AllSuccess` | `de_output_allsuccess` |
| `DE_OUTPUT/Databricks_Metrics/Usage_Metrics` | `de_output_databricks_metrics_usage_metrics` |
| `DE_OUTPUT/Gold/Dealing/DealingStreaming/...` | `de_output_gold_dealing_dealingstreaming_...` |
| `DE_OUTPUT/Monitoring/Datalake/DDR_Monitoring_Table` | `de_output_monitoring_datalake_ddr_monitoring_table` |

### Interaction Flow for Persistent Tables

When the user asks to create a persistent table:

**Step 1: Determine the logical path.** Ask: *"Where in DE_OUTPUT should this live? e.g., `KPI/Revenue/Trading_Daily`"*
- If the user gives a flat name like "revenue_trading", suggest a path structure: `KPI/Revenue/Trading_Daily`
- Segments should be `Title_Case` (capitalize first letter of each word)

**Step 2: Generate both environments.** Produce the full CREATE TABLE for STG and PROD:

```sql
-- ===================== STG =====================
CREATE TABLE IF NOT EXISTS main.de_output_stg.de_output_{flattened_path}
USING DELTA
LOCATION 'abfss://analysis@stgdpdlwe.dfs.core.windows.net/DE_OUTPUT/{Path}/{Segments}/'
AS
SELECT ...,
  current_timestamp() AS UpdateDate;   -- MANDATORY

-- ===================== PROD =====================
-- CHANGE schema to de_output + storage to dldataplatformprodwe
CREATE TABLE IF NOT EXISTS main.de_output.de_output_{flattened_path}
USING DELTA
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/{Path}/{Segments}/'
AS
SELECT ...,
  current_timestamp() AS UpdateDate;   -- MANDATORY
```

**Step 3: If the user needs a notebook job**, also generate the Python write pattern:

```python
storage_account = "stgdpdlwe"  # CHANGE to "dldataplatformprodwe" for PROD
schema = "de_output_stg"       # CHANGE to "de_output" for PROD
path = f"abfss://analysis@{storage_account}.dfs.core.windows.net/DE_OUTPUT/{Path}/{Segments}/"

def get_table_name(path: str) -> str:
    """Derive UC table name from ADLS path. Standard eToro convention."""
    index = 4 if 'external-sources' in path else 3
    parts = path.split('/')[index:-1] if path.endswith('/') else path.split('/')[index:]
    return '_'.join(parts).replace('-', '_').replace('.', '_').lower()

table_name = get_table_name(path)

# MANDATORY: Add UpdateDate before writing
from pyspark.sql import functions as F
df = df.withColumn('UpdateDate', F.current_timestamp())

df.write.saveAsTable(f"{schema}.{table_name}", format="delta", mode="overwrite", path=path)
```

### SQL Helper (for ad-hoc validation)

```sql
SELECT * FROM main.bi_dealing_stg.get_valid_table_name('your_table_name')
```

---

## Part A.2: BI_OUTPUT Tables (Same Convention, Different Root)

Same path-to-name rule, different root path and schemas:

| Environment | Schema | Storage Account |
|---|---|---|
| **STG** | `main.bi_output_stg` | `stgdpdlwe` |
| **PROD** | `main.bi_output` | `dldataplatformprodwe` |

Example for `BI_OUTPUT/Finance/Crs`:
- STG: `main.bi_output_stg.bi_output_finance_crs` at `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/Finance/Crs`
- PROD: `main.bi_output.bi_output_finance_crs` at `abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/BI_OUTPUT/Finance/Crs`

Note: You cannot add a new domain folder under BI_OUTPUT without prior approval from the Tech team. DE_OUTPUT is more flexible.

---

## Part A.3: Mandatory UpdateDate Column

**ALL persistent tables** in `de_output`, `de_output_stg`, `bi_output`, `bi_output_stg` **MUST** include an `UpdateDate` column.

### Specification

| Property | Value |
|---|---|
| Column name | `UpdateDate` (PascalCase — matches existing convention across all bi_output tables) |
| Data type | `TIMESTAMP` |
| Value | `current_timestamp()` — set at write time, NOT a source column |
| Nullable | No — every row must have a value |

### How it works by write pattern

**Full overwrite** (`mode="overwrite"` / `CREATE OR REPLACE`): All rows get the same `UpdateDate` — the moment the job wrote the table.

**Incremental append** (`mode="append"` / `INSERT INTO`): Each batch gets its own `UpdateDate` — lets you identify which rows came from which run.

**Merge/upsert** (`MERGE INTO`): Updated/inserted rows get `current_timestamp()` via the WHEN MATCHED / WHEN NOT MATCHED clause.

### SQL patterns

```sql
-- Full overwrite (CTAS)
CREATE OR REPLACE TABLE main.de_output_stg.de_output_xxx AS
SELECT *, current_timestamp() AS UpdateDate
FROM ...;

-- INSERT INTO
INSERT INTO main.de_output.de_output_xxx
SELECT *, current_timestamp() AS UpdateDate
FROM ...;

-- MERGE
MERGE INTO main.de_output.de_output_xxx t
USING source s ON t.id = s.id
WHEN MATCHED THEN UPDATE SET *, UpdateDate = current_timestamp()
WHEN NOT MATCHED THEN INSERT (*, UpdateDate) VALUES (s.*, current_timestamp());
```

### Python patterns

```python
from pyspark.sql import functions as F

# Before any write:
df = df.withColumn('UpdateDate', F.current_timestamp())

# Then write normally:
df.write.saveAsTable(..., mode="overwrite", path=...)
```

### Agent behavior

When reviewing or generating code that writes to persistent tables (`de_output*`, `bi_output*`):
1. **Check** if `UpdateDate` is included in the SELECT/write columns
2. **If missing**: proactively offer to add it — show the specific line to insert
3. **During code review**: flag as WARNING with auto-fix suggestion
4. **During table creation**: always include `UpdateDate` in the generated SQL/Python

---

## Part B: View Naming (BI-Customer SQL Conventions)

### Standard Views
```
v_<domain>_<view_name>
```
Example: `v_dealing_dashboard_cid`, `v_mimo_allplatforms`

### Genie Views (published to Genie spaces)
```
vg_<genie_name>_<view_name>         -- regular genie view
mvg_<genie_name>_<view_name>        -- metric genie view
```
Example: `vg_ddr_revenue`, `vg_customer_daily_snapshot`

---

## Part C: Semantic Layer Objects (etoro_kpi*)

Use this when creating views, functions, or KPI objects in the semantic layer schemas.

### Target Schemas

| Schema | Purpose |
|---|---|
| `etoro_kpi` | Foundational semantic objects -- available to all consumers |
| `etoro_kpi_prep` | Helper objects for the semantic GA layer |
| `etoro_kpi_prep_stg` | Development / work-in-progress staging |

### Interaction Flow

When this skill is activated (user references @NamingConvention), start an **interactive conversation** to build the object name and metadata. Follow these steps:

#### Step 1: Ask for Domain
Present the user with known domains as selectable options. If they type something new, accept it and note it should be added to the list going forward.

**Known domains:**
- `trading`
- `risk`
- `marketing`
- `finance`
- `user`
- `compliance`
- `growth`
- `calendar`
- `operations`

Prompt: *"What business domain does this object belong to?"*
Show the list above. Accept free-text for new domains.

#### Step 2: Ask for Layer
Present layer options:

| Layer | Suffix | Description |
|---|---|---|
| Staging | `stg` | Lightly transformed source data |
| Intermediate | `int` | Business logic, joins, calculations |
| Dimension | `dim` | Dimension tables |
| Fact | `fct` | Fact tables |
| KPI | `kpi` | Final KPI objects |
| View | `vw` | Views |
| Table Value Function | `tvf` | Table value functions |
| Scalar Function | `sf` | Scalar functions |
| User Defined Function | `udf` | User defined functions |

Prompt: *"What layer is this object?"*

#### Step 3: Ask for Entity
Prompt: *"What is the business entity? (e.g., orders, user_exposure, active_users, volume, arpu)"*

#### Step 4: Ask for Grain (if applicable)
Prompt: *"What is the grain? (e.g., daily, weekly, monthly, snapshot, event, user, account, instrument -- or skip if not applicable)"*

#### Step 5: Generate the Name
Assemble: `<domain>_<layer>_<entity>[_<grain>]`

All lowercase, underscore separated. Validate against the strict rules:
- Domain is NOT optional
- Do NOT encode layer inside the domain (e.g., `trading_kpi_kpi_users` is WRONG)
- Do NOT mix multiple domains in one object name
- No temp/ambiguous names (temp, final2, new, etc.)

Present the generated name and ask for confirmation.

#### Step 6: Generate Required Metadata
After the name is confirmed, generate:

1. **Ask for target schema** -- which schema should this object live in:
   - `etoro_kpi` -- main KPI schema (default)
   - `etoro_kpi_prep` -- prep/helper layer
   - `etoro_kpi_prep_stg` -- development staging

2. **Mandatory tags** (prompt the user for values):
   - `owner` -- e.g., data-platform, bi, risk-analytics
   - `refresh_frequency` -- hourly, daily, weekly, ad-hoc
   - `sla` -- e.g., D+1 10:00, T+2h
   - `source_system` -- Synapse, cosmos, etorodb
   - `pii` -- none, indirect, direct
   - `certified` -- gold, silver, bronze

3. **Optional tags:**
   - `domain` -- (auto-filled from Step 1)
   - `layer` -- (auto-filled from Step 2)
   - `data_classification` -- public, internal, confidential

4. **Table/View description** (generate a template):
   - Purpose: what this object represents
   - Grain: what a single row represents
   - Business Logic: key definitions and filters

#### Step 7: Generate the CREATE statement
Generate the full CREATE TABLE/VIEW/FUNCTION statement with:
- Fully qualified name: `main.<chosen_schema>.<generated_name>`
- COMMENT with the description
- TBLPROPERTIES with all tags
- Column comments for metrics, flags, and keys
- **`UpdateDate TIMESTAMP` column** (for persistent tables only, not views)

#### Step 8: Pre-Publish Checklist
Before finalizing, verify:
- [ ] Domain-first naming convention applied
- [ ] Mandatory tags exist
- [ ] Table/view description added
- [ ] Key columns documented
- [ ] Lineage visible (fully qualified names used)
- [ ] **`UpdateDate` column present** (persistent tables only)

---

## Naming Rules Quick Reference

### General Rules
- lowercase only
- `_` as separator
- No temporary or ambiguous names (temp, final2, new, etc.)
- Name must clearly express: business domain, modeling layer, business entity, grain (where applicable)

### Semantic Layer Structure
```
<domain>_<layer>_<entity>[_<purpose_or_grain>]
```

### Persistent Table Structure
```
de_output_{flattened_adls_path_lowercase}
```

### Examples -- Semantic Layer
- `trading_stg_orders`
- `trading_int_user_exposure_daily`
- `user_dim_user`
- `trading_fct_volume_user_daily`
- `marketing_kpi_arpu_country_monthly`

### Examples -- Persistent Tables
- `de_output_kpi_revenue_trading_daily`
- `de_output_kpi_ftd_funnel`
- `bi_output_finance_crs`

### Column Naming Rules
- Primary/foreign keys: `*_id`
- Booleans: `is_*`
- Timestamps: `*_at`
- Dates: `*_date`
- **Last updated: `UpdateDate` (TIMESTAMP)** -- mandatory for all persistent tables

### Lineage Requirements
- Use fully qualified names: `catalog.schema.table`
- Production objects must NOT depend on: temp views, unregistered objects, external objects
- Pipelines (DLT/Jobs) must be referenced via pipeline tag or object description

### KPI Column Documentation Requirements
All KPI metrics must include:
- Business definition
- Units (USD, %, count, etc.)
