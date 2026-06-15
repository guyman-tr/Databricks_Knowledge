---
object_fqn: main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:47Z'
upstreams:
- etoro.Hedge.InstrumentGroupsMapping
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md
  source_database: etoro
  source_schema: Hedge
  source_table: InstrumentGroupsMapping
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/InstrumentGroupsMapping
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

# bronze_etoro_hedge_instrumentgroupsmapping

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.InstrumentGroupsMapping`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Jul 31 14:16:27 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.InstrumentGroupsMapping` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md`.

- Lake path: `Bronze/etoro/Hedge/InstrumentGroupsMapping`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.InstrumentGroupsMapping`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | INT | YES | The instrument being assigned to a group. References Trade.Instrument(InstrumentID). Part of the composite PK. Futures instruments appear in the 200000+ ID range (Tier 2 — inherited from etoro.Hedge.InstrumentGroupsMapping). |
| 1 | GroupID | INT | YES | The group this instrument belongs to. Explicit FK to Hedge.InstrumentGroups(GroupID). Part of the composite PK. Values correspond to the 6 defined groups: 1=Futures, 100=Virtu US, 101=Virtu EU, 102=Virtu APAC, 201=OMS-Virtu EU, 202=OMS-Virtu US (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping). |
| 2 | DbLoginName | STRING | YES | Computed audit column. SQL Server login executing the DML (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping). |
| 3 | AppLoginName | STRING | YES | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping). |
| 4 | SysStartTime | TIMESTAMP | YES | Temporal period start. UTC timestamp when this row version became active (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping). |
| 5 | SysEndTime | TIMESTAMP | YES | Temporal period end. 9999-12-31 for current rows. History in History.InstrumentGroupsMapping (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping). |
| 6 | IsActive | BOOLEAN | YES | Whether this group membership is currently enforced. 1=active (instrument is in the group, routing rules apply), 0=inactive (instrument removed from group, rules no longer apply). Indexed for efficient WHERE IsActive=1 filtering. DEFAULT 1 (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.InstrumentGroupsMapping` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.InstrumentGroupsMapping
        │
        ▼
main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping   ←── this object
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
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping) |
| GroupID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping) |
| IsActive | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentGroupsMapping) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
