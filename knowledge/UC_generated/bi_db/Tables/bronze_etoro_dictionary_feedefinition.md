---
object_fqn: main.bi_db.bronze_etoro_dictionary_feedefinition
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_dictionary_feedefinition
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 2
row_count: null
generated_at: '2026-05-19T12:12:44Z'
upstreams:
- etoro.Dictionary.FeeDefinition
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md
  source_database: etoro
  source_schema: Dictionary
  source_table: FeeDefinition
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Dictionary/FeeDefinition
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_dictionary_feedefinition

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Dictionary.FeeDefinition`). 2 of 2 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_dictionary_feedefinition` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 2 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Nov 28 07:12:38 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Dictionary.FeeDefinition` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md`.

- Lake path: `Bronze/etoro/Dictionary/FeeDefinition`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Dictionary.FeeDefinition`
- 2 of 2 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FeeID | INT | YES | Fee billing frequency: **0**=No Fee (exempt from overnight charges), **1**=Daily Fee (charged each trading day), **2**=Weekly Fee (charged once per week). Referenced by Trade.InstrumentMetaData.FeeID and Trade.ExchangeInstrumentFeeDefinition (Tier 1 — inherited from etoro.Dictionary.FeeDefinition). |
| 1 | FeeDescription | STRING | YES | Human-readable fee frequency label: "No Fee", "Daily Fee", "Weekly Fee". Used in instrument configuration UIs and reporting (Tier 1 — inherited from etoro.Dictionary.FeeDefinition). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Dictionary.FeeDefinition` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Dictionary.FeeDefinition
        │
        ▼
main.bi_db.bronze_etoro_dictionary_feedefinition   ←── this object
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
| FeeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.FeeDefinition) |
| FeeDescription | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.FeeDefinition) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 2 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 2/2 | Source: bronze_tier1_inheritance*
