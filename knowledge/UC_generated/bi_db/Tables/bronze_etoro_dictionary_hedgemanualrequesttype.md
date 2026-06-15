---
object_fqn: main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 2
row_count: null
generated_at: '2026-05-19T12:12:44Z'
upstreams:
- etoro.Dictionary.HedgeManualRequestType
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md
  source_database: etoro
  source_schema: Dictionary
  source_table: HedgeManualRequestType
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Dictionary/HedgeManualRequestType
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

# bronze_etoro_dictionary_hedgemanualrequesttype

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Dictionary.HedgeManualRequestType`). 2 of 2 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 2 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Sep 11 13:15:57 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Dictionary.HedgeManualRequestType` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md`.

- Lake path: `Bronze/etoro/Dictionary/HedgeManualRequestType`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Dictionary.HedgeManualRequestType`
- 2 of 2 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RequestTypeID | INT | YES | Primary key identifying the manual request type. 0=Custom Request, 1=Set Hedge Exposure, 2=Settle Requested Exposure, 3=SetTradeExposure, 4=Manual Exposure, 5=Custom Update Queued, 6=Clear Queued, 7=Move Netting. Stored in Hedge.ManualOrderExecutionLog for audit (Tier 1 — inherited from etoro.Dictionary.HedgeManualRequestType). |
| 1 | Name | STRING | YES | Human-readable label for the request type. Displayed in manual hedge operation logs and audit reports (Tier 1 — inherited from etoro.Dictionary.HedgeManualRequestType). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Dictionary.HedgeManualRequestType` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Dictionary.HedgeManualRequestType
        │
        ▼
main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype   ←── this object
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
| RequestTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.HedgeManualRequestType) |
| Name | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.HedgeManualRequestType) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 2 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 2/2 | Source: bronze_tier1_inheritance*
