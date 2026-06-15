---
object_fqn: main.bi_db.bronze_etoro_dictionary_openpositionactiontype
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_dictionary_openpositionactiontype
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 2
row_count: null
generated_at: '2026-05-19T12:12:45Z'
upstreams:
- etoro.Dictionary.OpenPositionActionType
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md
  source_database: etoro
  source_schema: Dictionary
  source_table: OpenPositionActionType
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Dictionary/OpenPositionActionType
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

# bronze_etoro_dictionary_openpositionactiontype

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Dictionary.OpenPositionActionType`). 2 of 2 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_dictionary_openpositionactiontype` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 2 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Jan 02 12:15:26 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Dictionary.OpenPositionActionType` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md`.

- Lake path: `Bronze/etoro/Dictionary/OpenPositionActionType`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Dictionary.OpenPositionActionType`
- 2 of 2 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Identifier for the open trigger (no PK constraint in DDL). -1=Undefined, 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 4=Stock Dividend, 5=Corporate Action, 6=Technical Issue, 7=Operational adjustment, 8=Add Funds, 9=Reinvestment, 10=Admin, 11=Stacking, 12=Promotion, 13=ACATS_IN, 14=ReedemForNFT, 15=Technical, 16=Alignment, 17=Recurring Investment. Stored with every position for permanent attribution. See [Open Position Action Type](_glossary.md#open-position-action-type). (Dictionary.OpenPositionActionType) (Tier 1 — inherited from etoro.Dictionary.OpenPositionActionType). |
| 1 | OpenPositionActionName | STRING | YES | Human-readable label for the open trigger. Used in account statements, trading reports, and back-office displays (Tier 1 — inherited from etoro.Dictionary.OpenPositionActionType). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Dictionary.OpenPositionActionType` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Dictionary.OpenPositionActionType
        │
        ▼
main.bi_db.bronze_etoro_dictionary_openpositionactiontype   ←── this object
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
| ID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.OpenPositionActionType) |
| OpenPositionActionName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.OpenPositionActionType) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 2 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 2/2 | Source: bronze_tier1_inheritance*
