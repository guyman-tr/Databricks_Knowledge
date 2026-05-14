# Naming Convention - Full Rules Reference

**Author:** Pini Krisher
**Scope:** All Tables and Views created under the `etoro_kpi`, `etoro_kpi_bronze`, and `etoro_kpi_bronze_stg` schemas (including staging, intermediate, fact, dimension, and KPI layers).

---

## 1. Naming Convention (Domain-First)

### 1.1 Guiding Principle
Objects must be named **domain-first** to ensure that all related assets appear side-by-side in:
- Databricks autocomplete
- Catalog / data portal
- Schema browsing

This significantly improves discoverability and scalability as domains grow.

### 1.2 General Rules
- **lowercase only**
- `_` as separator
- No temporary or ambiguous names (`temp`, `final2`, `new`, etc.)
- Name must clearly express:
  - Business domain
  - Modeling layer
  - Business entity
  - Grain (where applicable)

### 1.3 Naming Structure (Mandatory)

```
<domain>_<layer>_<entity>[_<purpose_or_grain>]
```

### 1.4 Domains (Mandatory)
The domain represents the **business area**, not the technical source.

| Domain | Description |
|---|---|
| `trading` | Trading platform activity |
| `risk` | Risk management |
| `marketing` | Marketing and acquisition |
| `finance` | Financial reporting |
| `user` | User/customer data |
| `compliance` | Regulatory compliance |
| `growth` | Growth metrics |
| `calendar` | Date/time reference |
| `operations` | Operational data |

**Rule:** Shared entities (e.g., users, calendar, geo) must still have a domain (e.g., `user_dim_user`, `calendar_dim_date`).

> **New domains:** If the user provides a domain not in this list, accept it. Note it as a candidate for addition to the standard list.

### 1.5 Layers (Mandatory)

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

### 1.6 Grain Suffix (Mandatory where relevant)
Grain must be explicit and placed **last**.

Common grains:
- `daily`, `weekly`, `monthly`
- `snapshot`, `event`
- `user`, `account`, `instrument`

### 1.7 Examples (Domain-First)

| Name | Domain | Layer | Entity | Grain |
|---|---|---|---|---|
| `trading_stg_orders` | trading | stg | orders | — |
| `trading_int_user_exposure_daily` | trading | int | user_exposure | daily |
| `user_dim_user` | user | dim | user | — |
| `trading_fct_volume_user_daily` | trading | fct | volume_user | daily |
| `marketing_kpi_arpu_country_monthly` | marketing | kpi | arpu_country | monthly |
| `trading_kpi_active_users_daily` | trading | kpi | active_users | daily |
| `trading_vw_kpi_active_users_daily` | trading | vw | kpi_active_users | daily |

### 1.8 Naming Rules (Strict)
- Domain is **not optional**
- Do **not** encode layer inside the domain (e.g., `trading_kpi_kpi_users` is WRONG)
- Do **not** mix multiple domains in one object name
- No temp/ambiguous names

---

## 2. Tags (Mandatory Metadata)
Every object must include tags to support ownership, governance, and discovery.

### 2.1 Mandatory Tags

| Tag | Example Values | Required |
|---|---|---|
| `owner` | data-platform, bi, risk-analytics | YES |
| `refresh_frequency` | hourly, daily, weekly, ad-hoc | YES |
| `sla` | D+1 10:00, T+2h | YES |
| `source_system` | Synapse, cosmos, etorodb | YES |
| `pii` | none, indirect, direct | YES |
| `certified` | gold, silver, bronze | YES |

### 2.2 Optional Tags

| Tag | Example Values | Notes |
|---|---|---|
| `domain` | trading, marketing, risk | Auto-filled from name |
| `layer` | stg, int, dim, fct, kpi, vw | Auto-filled from name |
| `data_classification` | public, internal, confidential | Recommended |

---

## 3. Table / View Description (Required)
Every table or view must include a description.

### 3.1 Required Content
- **Purpose** — what this object represents
- **Grain** — what a single row represents
- **Business Logic** — key definitions and filters

### 3.2 Template
```sql
COMMENT 'Purpose: <what this object represents>. Grain: <what a single row represents>. Business Logic: <key definitions and filters>.'
```

---

## 4. Column Standards & Documentation

### 4.1 Column Naming Rules

| Pattern | Convention | Example |
|---|---|---|
| Primary/foreign keys | `*_id` | `user_id`, `instrument_id` |
| Booleans | `is_*` | `is_active`, `is_funded` |
| Timestamps | `*_at` | `created_at`, `updated_at` |
| Dates | `*_date` | `trade_date`, `registration_date` |

### 4.2 Column Descriptions
All metrics, flags, and keys — anything with business meaning — must be explained.

If part of KPI metrics, must include:
- **Business definition**
- **Units** (USD, %, count, etc.)

---

## 5. Lineage (Must Be Visible in Portal)

### 5.1 Lineage Requirements
- Use **fully qualified names**: `catalog.schema.table`
- Any change must be checked in the lineage TAB
- Production objects must **not** depend on:
  - Temp views
  - Unregistered objects
  - Unity Catalog external objects
- Pipelines (DLT / Jobs) must be referenced via:
  - `pipeline` tag, or
  - Object description

### 5.2 No-Exceptions Rule
Objects that do not comply:
- **Must not be created in `etoro_kpi`, `etoro_kpi_bronze`, or `etoro_kpi_bronze_stg`**
- Dictionaries can be outside these schemas
- Tables under the view can be outside these schemas, but **must be in PROD schemas**

---

## 6. Pre-Publish Checklist

Before creating any object in `etoro_kpi`, `etoro_kpi_bronze`, or `etoro_kpi_bronze_stg`, verify:

- [ ] Domain-first naming convention applied
- [ ] Mandatory tags exist (`owner`, `refresh_frequency`, `sla`, `source_system`, `pii`, `certified`)
- [ ] Table/view description added (Purpose, Grain, Business Logic)
- [ ] Key columns documented
- [ ] Lineage visible in portal (fully qualified names, no temp dependencies)

---

## 7. CREATE Statement Template

```sql
CREATE OR REPLACE VIEW main.etoro_kpi.<domain>_<layer>_<entity>[_<grain>]
(
    column_1 COMMENT '<business definition, units>',
    column_2 COMMENT '<business definition, units>'
)
COMMENT 'Purpose: <...>. Grain: <...>. Business Logic: <...>.'
TBLPROPERTIES (
    'owner' = '<team>',
    'domain' = '<domain>',
    'layer' = '<layer>',
    'refresh_frequency' = '<frequency>',
    'sla' = '<sla>',
    'source_system' = '<source>',
    'pii' = '<none|indirect|direct>',
    'certified' = '<gold|silver|bronze>'
)
AS
SELECT ...
FROM main.<schema>.<source_table>  -- fully qualified!
```
