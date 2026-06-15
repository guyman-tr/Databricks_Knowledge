---
object_fqn: main.bi_db.bronze_etoro_dictionary_withdrawtype
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_dictionary_withdrawtype
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 3
row_count: null
generated_at: '2026-05-19T12:12:45Z'
upstreams:
- etoro.Dictionary.WithdrawType
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md
  source_database: etoro
  source_schema: Dictionary
  source_table: WithdrawType
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Dictionary/WithdrawType
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_dictionary_withdrawtype

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Dictionary.WithdrawType`). 3 of 3 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_dictionary_withdrawtype` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 3 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 14:13:49 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Dictionary.WithdrawType` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md`.

- Lake path: `Bronze/etoro/Dictionary/WithdrawType`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Dictionary.WithdrawType`
- 3 of 3 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawTypeID | INT | YES | Unique identifier for the withdrawal classification: 0=Default (standard cashout), 1=Transfer (internal), 2=ApprovedForClosure (closure disbursement). Stored on Billing.Withdraw and checked by 15+ procedures to determine processing path, approval requirements, and reporting categorization (Tier 1 — inherited from etoro.Dictionary.WithdrawType). |
| 1 | WithdrawType | STRING | YES | Short code name for the type: "Default", "Transfer", "ApprovedForClosure". Used as a programmatic identifier in application code and API responses (Tier 1 — inherited from etoro.Dictionary.WithdrawType). |
| 2 | Description | STRING | YES | Human-readable description of the type. Empty for Default (0), "Internal Transfer" for Transfer (1), "Approved for closure" for ApprovedForClosure (2). Used in BackOffice UI and reports (Tier 1 — inherited from etoro.Dictionary.WithdrawType). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Dictionary.WithdrawType` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Dictionary.WithdrawType
        │
        ▼
main.bi_db.bronze_etoro_dictionary_withdrawtype   ←── this object
        │
        ▼
main.bi_output.vg_fact_billingwithdraw_for_genie
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
| WithdrawTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.WithdrawType) |
| WithdrawType | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.WithdrawType) |
| Description | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.WithdrawType) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 3 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 3/3 | Source: bronze_tier1_inheritance*
