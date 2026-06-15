---
object_fqn: main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 4
row_count: null
generated_at: '2026-05-19T12:13:03Z'
upstreams:
- UserApiDB.Customer.ExtendedUserFieldValidation
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md
  source_database: UserApiDB
  source_schema: Customer
  source_table: ExtendedUserFieldValidation
  source_repo: DB_Schema
  datalake_path: Bronze/UserApiDB/Customer/ExtendedUserFieldValidation
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_userapidb_customer_extendeduserfieldvalidation

> Bronze ingest in `main.bi_db` (1:1 passthrough of `UserApiDB.Customer.ExtendedUserFieldValidation`). 4 of 4 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 4 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 31 00:52:52 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `UserApiDB.Customer.ExtendedUserFieldValidation` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md`.

- Lake path: `Bronze/UserApiDB/Customer/ExtendedUserFieldValidation`
- Copy strategy: `Override`
- Source database: `UserApiDB` (`DB_Schema`)
- Source schema/table: `Customer.ExtendedUserFieldValidation`
- 4 of 4 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Part of composite PK. Global Customer ID (Tier 1 — inherited from UserApiDB.Customer.ExtendedUserFieldValidation). |
| 1 | CountryID | INT | YES | Part of composite PK. Country context for validation (Tier 1 — inherited from UserApiDB.Customer.ExtendedUserFieldValidation). |
| 2 | FieldID | INT | YES | Part of composite PK. Extended field identifier. Maps to Dictionary.ExtendedUserField (Tier 1 — inherited from UserApiDB.Customer.ExtendedUserFieldValidation). |
| 3 | IsValid | BOOLEAN | YES | Whether the field value passed validation. NULL=not yet validated, 1=valid, 0=invalid (Tier 1 — inherited from UserApiDB.Customer.ExtendedUserFieldValidation). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `UserApiDB.Customer.ExtendedUserFieldValidation` | Primary | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md` |

### 4.2 Pipeline ASCII Diagram

```
UserApiDB.Customer.ExtendedUserFieldValidation
        │
        ▼
main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation   ←── this object
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
| GCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.ExtendedUserFieldValidation) |
| CountryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.ExtendedUserFieldValidation) |
| FieldID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.ExtendedUserFieldValidation) |
| IsValid | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.ExtendedUserFieldValidation) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 4/4 | Source: bronze_tier1_inheritance*
