---
object_fqn: main.bi_db.bronze_etoro_hedge_instrumentgroups
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_instrumentgroups
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:47Z'
upstreams:
- etoro.Hedge.InstrumentGroups
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md
  source_database: etoro
  source_schema: Hedge
  source_table: InstrumentGroups
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/InstrumentGroups
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_hedge_instrumentgroups

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.InstrumentGroups`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_instrumentgroups` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Jul 31 14:16:17 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.InstrumentGroups` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md`.

- Lake path: `Bronze/etoro/Hedge/InstrumentGroups`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.InstrumentGroups`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GroupID | INT | YES | Primary key. Manually assigned integer identifying the instrument group. Numbering convention: 1=instrument-type groups, 100-102=Virtu direct path by region, 201-202=OMS/Virtu path by region. NOT IDENTITY - values are explicitly chosen to encode group category. Referenced by Hedge.InstrumentGroupsMapping and Hedge.OrderTypeConfiguration (Tier 1 — inherited from etoro.Hedge.InstrumentGroups). |
| 1 | GroupName | STRING | YES | Human-readable name for the group (e.g., "Futures", "Virtu UnManaged US Flow Direct"). Used in GetInstrumentGroupsMapping output returned to the hedge engine and in admin interfaces (Tier 1 — inherited from etoro.Hedge.InstrumentGroups). |
| 2 | Description | STRING | YES | Optional free-text description of the group's purpose (e.g., "US Names of the Unmanaged Flow into Virtu"). Informational only - not used by any procedure logic. NULL allowed but always populated in practice (Tier 1 — inherited from etoro.Hedge.InstrumentGroups). |
| 3 | DbLoginName | STRING | YES | Computed audit column. SQL Server login executing the DML via `suser_name()` (Tier 1 — inherited from etoro.Hedge.InstrumentGroups). |
| 4 | AppLoginName | STRING | YES | Computed audit column. Application identity from `CONTEXT_INFO()`. NULL when not set (Tier 1 — inherited from etoro.Hedge.InstrumentGroups). |
| 5 | SysStartTime | TIMESTAMP | YES | Temporal period start. UTC timestamp when this row version became active. Original Futures group created 2024-11-06; Virtu/OMS groups added 2025-09-21 (Tier 1 — inherited from etoro.Hedge.InstrumentGroups). |
| 6 | SysEndTime | TIMESTAMP | YES | Temporal period end. 9999-12-31 for all currently active rows. History in History.InstrumentGroups (Tier 1 — inherited from etoro.Hedge.InstrumentGroups). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.InstrumentGroups` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.InstrumentGroups
        │
        ▼
main.bi_db.bronze_etoro_hedge_instrumentgroups   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| GroupID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroups) |
| GroupName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroups) |
| Description | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroups) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroups) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroups) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroups) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroups) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
