---
object_fqn: main.bi_db.bronze_fiktivo_dictionary_positionassettype
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dictionary_positionassettype
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 2
row_count: null
generated_at: '2026-05-19T12:12:59Z'
upstreams:
- fiktivo.Dictionary.PositionAssetType
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md
  source_database: fiktivo
  source_schema: Dictionary
  source_table: PositionAssetType
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/Dictionary/PositionAssetType
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

# bronze_fiktivo_dictionary_positionassettype

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.Dictionary.PositionAssetType`). 2 of 2 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dictionary_positionassettype` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 2 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 15 05:16:08 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.Dictionary.PositionAssetType` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md`.

- Lake path: `Bronze/fiktivo/Dictionary/PositionAssetType`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `Dictionary.PositionAssetType`
- 2 of 2 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Primary key identifying the asset class. Values: 0=All, 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto, 11=Copy. See [Position Asset Type](../../_glossary.md#position-asset-type) for full definitions. ID=0 serves as a wildcard in filter contexts (Tier 1 — inherited from fiktivo.Dictionary.PositionAssetType). |
| 1 | Name | STRING | YES | Human-readable label for the asset class. Used in commission plan configuration, reporting displays, and admin UIs (Tier 1 — inherited from fiktivo.Dictionary.PositionAssetType). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.Dictionary.PositionAssetType` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.Dictionary.PositionAssetType
        │
        ▼
main.bi_db.bronze_fiktivo_dictionary_positionassettype   ←── this object
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
| ID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.Dictionary.PositionAssetType) |
| Name | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.Dictionary.PositionAssetType) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 2 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 2/2 | Source: bronze_tier1_inheritance*
