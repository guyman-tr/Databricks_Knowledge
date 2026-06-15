---
object_fqn: main.bi_db.bronze_userapidb_customer_additionalcitizenship
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_userapidb_customer_additionalcitizenship
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:13:03Z'
upstreams:
- UserApiDB.Customer.AdditionalCitizenship
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md
  source_database: UserApiDB
  source_schema: Customer
  source_table: AdditionalCitizenship
  source_repo: DB_Schema
  datalake_path: Bronze/UserApiDB/Customer/AdditionalCitizenship
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_userapidb_customer_additionalcitizenship

> Bronze ingest in `main.bi_db` (1:1 passthrough of `UserApiDB.Customer.AdditionalCitizenship`). 5 of 8 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_userapidb_customer_additionalcitizenship` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Jul 10 13:24:35 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `UserApiDB.Customer.AdditionalCitizenship` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md`.

- Lake path: `Bronze/UserApiDB/Customer/AdditionalCitizenship`
- Copy strategy: `Override`
- Source database: `UserApiDB` (`DB_Schema`)
- Source schema/table: `Customer.AdditionalCitizenship`
- 5 of 8 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AdditionalCitizenshipID | LONG | YES | Primary key. Auto-incrementing surrogate key (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship). |
| 1 | GCID | INT | YES | Global Customer ID. Unique constraint - one additional citizenship per user (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship). |
| 2 | CountryID | INT | YES | The additional citizenship country. Implicit FK to Dictionary.Country. See [Country](_glossary.md#country) (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship). |
| 3 | StartTime | TIMESTAMP | YES | System versioning row start time (GENERATED ALWAYS AS ROW START) (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship). |
| 4 | EndTime | TIMESTAMP | YES | System versioning row end time (GENERATED ALWAYS AS ROW END) (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship). |
| 5 | etr_y | STRING | YES | Source: UserApiDB.Customer.AdditionalCitizenship.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | etr_ym | STRING | YES | Source: UserApiDB.Customer.AdditionalCitizenship.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | etr_ymd | STRING | YES | Source: UserApiDB.Customer.AdditionalCitizenship.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `UserApiDB.Customer.AdditionalCitizenship` | Primary | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` |

### 4.2 Pipeline ASCII Diagram

```
UserApiDB.Customer.AdditionalCitizenship
        │
        ▼
main.bi_db.bronze_userapidb_customer_additionalcitizenship   ←── this object
        │
        ▼
main.bi_output.bi_output_customer_compliance_mas_population
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
| AdditionalCitizenshipID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship) |
| GCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship) |
| CountryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship) |
| StartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship) |
| EndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.Customer.AdditionalCitizenship) |
| etr_y | would inherit from `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
