---
id: uc-naming-conventions
name: "UC Naming Conventions & Synapse↔Databricks FQN Mapping"
description: |
  Cross-cutting utility skill. Resolves Synapse-style object names (e.g.
  `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms`) to Unity Catalog fully-qualified
  names (e.g. `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`)
  and vice-versa. Use whenever a wiki / SP / legacy reference uses a Synapse
  name and you need the queryable UC FQN, or you encounter a `_Not_Migrated`
  object and need the right routing. Load IN ADDITION to whichever
  super-domain skill the question belongs to — this skill does not own data,
  it owns the naming-rule lookup.
triggers:
  - UC FQN
  - fully qualified name
  - Synapse to UC
  - Synapse to Databricks
  - naming convention
  - BI_DB_dbo
  - DWH_dbo
  - eMoney_dbo
  - EXW_dbo
  - EXW_Wallet
  - eMoney_Tribe
  - FiatDwhDB
  - _Not_Migrated
  - synapse_only
  - gold_sql_dp_prod_we
  - bronze_fiatdwhdb
  - bronze_walletdb
  - Unity Catalog mapping
  - which catalog
  - which schema
  - v_mimo_tradingplatform
  - v_mimo_emoneyplatform
required_tables:
  - main.information_schema.tables
  - main.information_schema.columns
  - main.information_schema.views
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-10"
---

# UC Naming Conventions & Synapse↔Databricks FQN Mapping

The eToro data platform has two parallel naming worlds:

- **Synapse** (legacy DWH) uses `<schema>.<object>` (e.g. `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms`). Wiki pages, stored procedures, and operational documentation all use Synapse names.
- **Unity Catalog** (Databricks, current) uses `<catalog>.<schema>.<object>` (e.g. `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`). All analytical SQL run from Databricks Genie / notebooks / DBSQL must use UC FQNs.

This skill is the **translation layer** between the two worlds.

## When to Use

- A wiki page or SP references a Synapse object and you need to query it from Databricks → translate to UC FQN here first.
- You encounter `_Not_Migrated` in an `alter.sql` or skill front-matter `synapse_only_objects:` list and need to know what to tell the user.
- A skill says "deploy this to Synapse" or "run against Synapse" and you need to know whether the object exists in UC at all.
- You need to validate a translated UC FQN against `information_schema` before running SQL.

This skill is a **utility** — load it alongside the super-domain skill that owns the data, not instead of it.

## Scope

In scope: name-mapping rules, status flags (deployed / `_Not_Migrated` / `synapse_only` / `deprecated`), the UC FQN convention for every major Synapse schema, the per-platform MIMO view name quirks, and the rule for routing Synapse-only objects.

Out of scope: any business definition of an object (route to the owning super-domain), SQL syntax beyond name resolution, lineage / dependency graphs (those live in `knowledge/synapse/Wiki/` and `_join_graph.json`).

Last verified: 2026-05-10

## Critical Warnings

1. **Tier 1 — Always emit the UC FQN when generating SQL for Databricks.** A query like `SELECT * FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` will fail on Databricks (Synapse syntax is not valid in UC). The Synapse name is for **cross-reference with wiki documentation only**.
2. **Tier 1 — `_Not_Migrated` / `synapse_only` objects cannot be queried from Databricks.** If a skill marks an object this way, do NOT fabricate a UC FQN for it. Tell the user the object is Synapse-only and offer alternatives: (a) reformulate using the UC-deployed equivalent, or (b) run the query against Synapse directly via the synapse_prod_sql / synapse_sql MCP, or pyodbc.
3. **Tier 2 — Per-platform MIMO objects are VIEWS, not tables.** The naming has a quirk: `BI_DB_DDR_Fact_MIMO_<Platform>_Platform` → UC `main.etoro_kpi_prep.v_mimo_<platform>platform`. **No underscore** between the platform-name and `platform` for `tradingplatform` / `emoneyplatform`; **underscore is present** for `options_platform`. Verify against `information_schema` before assuming.
4. **Tier 2 — Some objects live in multiple UC schemas.** `eMoney_dbo.<X>` typically lands in `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_<x_lower>` for analyst-facing tables, but some operational `eMoney_dbo` objects mirror to `main.emoney.gold_*`. When uncertain, query `main.information_schema.tables WHERE table_name LIKE '%<x_lower>%'`.
5. **Tier 3 — `EXW_Wallet.<X>` and `EXW_Dictionary.<X>` map to `main.wallet.bronze_walletdb_*`** (production-replicated bronze), **NOT to a DWH-curated mirror.** These are unenriched bronze tables; treat schema and column semantics with care, and prefer DWH-curated downstream views where available.

## Synapse → UC FQN — the canonical mapping rules

| Synapse path | UC FQN pattern | Notes |
|---|---|---|
| `BI_DB_dbo.<X>` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_<x_lower>` | TABLE. Most analytical facts and dims. |
| `DWH_dbo.<X>` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_<x_lower>` | TABLE. Includes `Dim_Customer`, `Fact_CustomerAction`, `Fact_Position`, etc. PII-masked variants live in `main.dwh.*_masked`; PII originals in `main.pii_data.*`. |
| `eMoney_dbo.<X>` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_<x_lower>` *(analyst-facing)* | TABLE. Some operational eMoney objects mirror to `main.emoney.gold_*` instead — check the map for the specific table. |
| `EXW_dbo.<X>` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_<x_lower>` *(when migrated)* | TABLE. Many `EXW_dbo` tables are `_Not_Migrated` — verify in `information_schema` before assuming. |
| `EXW_Wallet.<X>` | `main.wallet.bronze_walletdb_wallet_<x_lower>` | TABLE. Production-replicated bronze, not DWH-curated. Same for `EXW_Dictionary.<X>` → `main.wallet.bronze_walletdb_dictionary_<x_lower>`. |
| `eMoney_Tribe.<X>` | `main.emoney.bronze_fiatdwhdb_tribe_<x_lower>` | TABLE. Treezor XML audit envelopes. Some names contain hyphens — wrap in backticks in SQL: `` `bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937` ``. |
| `FiatDwhDB.dbo.<X>` | `main.emoney.bronze_fiatdwhdb_dbo_<x_lower>` *(mostly)* | TABLE. Treezor operational fiat mirror. A handful land in `main.bi_db.bronze_fiatdwhdb_dbo_*` — check the map. |
| `BI_DB_DDR_Fact_MIMO_<Platform>_Platform` | `main.etoro_kpi_prep.v_mimo_<platform>platform` *(VIEW)* | **VIEW, not TABLE.** Quirks: `tradingplatform` / `emoneyplatform` have NO underscore; `options_platform` HAS the underscore. Verify in `information_schema.views`. |
| `etoro_kpi.<view>` | `main.etoro_kpi.<view>` | VIEW. KPI-layer curated views; pass-through schema. |
| `etoro_kpi_prep.<view>` | `main.etoro_kpi_prep.<view>` | VIEW. Stage-layer atomic views (e.g. `v_revenue_*`, `v_population_*`). Pass-through schema. |

## Status flags

When a skill front-matter lists `synapse_only_objects:` or you see `_Not_Migrated` in an `alter.sql`:

| Status | What it means | What to do |
|---|---|---|
| **deployed** | Object exists in UC and is queryable from Databricks | Use the UC FQN; no action needed. |
| **_Not_Migrated** | `alter.sql` exists but the object is intentionally not propagated to UC | Tell the user; offer Synapse-direct fallback. |
| **synapse_only** | Object lives only in Synapse (wiki or alter.sql may or may not exist) | Tell the user; offer Synapse-direct fallback. |
| **deprecated** | Object exists somewhere but is being retired | Use the documented replacement (the skill or wiki should name it). |

## Synapse-direct fallback — how to run against Synapse

When a question genuinely needs a `synapse_only` object:

1. Tell the user the object is Synapse-only.
2. Offer two paths:
   - **(a)** Reformulate the question using a UC-deployed equivalent (preferred — sometimes a downstream `etoro_kpi_prep.v_*` view exposes the same data).
   - **(b)** Run against Synapse directly via the `synapse_prod_sql` / `synapse_sql` MCP servers, or via pyodbc.
3. If picking (b), the connection skill is `~/.cursor/skills/synapse-connection/SKILL.md`.

## How to verify a translated FQN

Before running a generated UC FQN in production SQL, verify it exists:

```sql
SELECT table_catalog, table_schema, table_name, table_type
FROM main.information_schema.tables
WHERE LOWER(table_name) LIKE '%<x_lower>%'
ORDER BY table_schema, table_name;
```

Filter on the lower-cased object name (UC always lower-cases). If multiple matches, prefer the one in the canonical schema for the source Synapse schema (per the mapping table above).

## Cross-references

- `knowledge/skills/_uc_object_map.md` — every skill-referenced object resolved to UC FQN with status and source.
- `knowledge/skills/_uc_object_map.action_required.md` — the ~17 refs that cannot be queried in Databricks.
- `knowledge/skills/_CHECKPOINT_A.md` — provenance and discovery audit trail.
