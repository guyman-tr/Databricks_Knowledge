---
object_fqn: main.bi_db.bronze_userapidb_asic_testresults
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_userapidb_asic_testresults
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:13:03Z'
upstreams:
- UserApiDB.ASIC.TestResults
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md
  source_database: UserApiDB
  source_schema: ASIC
  source_table: TestResults
  source_repo: DB_Schema
  datalake_path: Bronze/UserApiDB/ASIC/TestResults
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 6
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_userapidb_asic_testresults

> Bronze ingest in `main.bi_db` (1:1 passthrough of `UserApiDB.ASIC.TestResults`). 6 of 6 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_userapidb_asic_testresults` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 6 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Sep 07 18:14:27 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `UserApiDB.ASIC.TestResults` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md`.

- Lake path: `Bronze/UserApiDB/ASIC/TestResults`
- Copy strategy: `Override`
- Source database: `UserApiDB` (`DB_Schema`)
- Source schema/table: `ASIC.TestResults`
- 6 of 6 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TestId | INT | YES | Primary key. Auto-generated unique identifier for each test attempt (Tier 1 — inherited from UserApiDB.ASIC.TestResults). |
| 1 | GCID | INT | YES | Global Customer ID. Identifies which user took the test. Indexed descending for fast per-user lookups (Tier 1 — inherited from UserApiDB.ASIC.TestResults). |
| 2 | Success | BOOLEAN | YES | Whether the user passed the ASIC classification test. 1 = passed, 0 = failed (Tier 1 — inherited from UserApiDB.ASIC.TestResults). |
| 3 | Score | INT | YES | Numeric score achieved on the test. May be NULL if scoring is not applicable (Tier 1 — inherited from UserApiDB.ASIC.TestResults). |
| 4 | OccurredAt | TIMESTAMP | YES | When the test was taken. Used for audit trails and ordering results (Tier 1 — inherited from UserApiDB.ASIC.TestResults). |
| 5 | Deleted | BOOLEAN | YES | Soft-delete flag. 0 = active, 1 = deleted. All active queries filter WHERE Deleted = 0 (Tier 1 — inherited from UserApiDB.ASIC.TestResults). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `UserApiDB.ASIC.TestResults` | Primary | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md` |

### 4.2 Pipeline ASCII Diagram

```
UserApiDB.ASIC.TestResults
        │
        ▼
main.bi_db.bronze_userapidb_asic_testresults   ←── this object
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
| TestId | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.ASIC.TestResults) |
| GCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.ASIC.TestResults) |
| Success | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.ASIC.TestResults) |
| Score | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.ASIC.TestResults) |
| OccurredAt | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.ASIC.TestResults) |
| Deleted | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.ASIC.TestResults) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 6 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: bronze_tier1_inheritance*
