---
object_fqn: main.bi_db.bronze_usabroker_dictionary_eligibilitystatus
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_usabroker_dictionary_eligibilitystatus
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 2
row_count: null
generated_at: '2026-05-19T12:13:02Z'
upstreams:
- USABroker.Dictionary.EligibilityStatus
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md
  source_database: USABroker
  source_schema: Dictionary
  source_table: EligibilityStatus
  source_repo: ComplianceDBs
  datalake_path: Bronze/USABroker/Dictionary/EligibilityStatus
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 2
  unverified_columns: 0
---

# bronze_usabroker_dictionary_eligibilitystatus

> Bronze ingest in `main.bi_db` (1:1 passthrough of `USABroker.Dictionary.EligibilityStatus`). 0 of 2 columns inherited from Tier 1 source wiki; 2 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_usabroker_dictionary_eligibilitystatus` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 2 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Aug 27 08:13:50 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `USABroker.Dictionary.EligibilityStatus` (`ComplianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md`.

- Lake path: `Bronze/USABroker/Dictionary/EligibilityStatus`
- Copy strategy: `Override`
- Source database: `USABroker` (`ComplianceDBs`)
- Source schema/table: `Dictionary.EligibilityStatus`
- 0 of 2 columns inherited; 2 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | EligibilityStatusID | INT | YES | Source: USABroker.Dictionary.EligibilityStatus.EligibilityStatusID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 1 | Name | STRING | YES | Source: USABroker.Dictionary.EligibilityStatus.Name. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `USABroker.Dictionary.EligibilityStatus` | Primary | `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md` |

### 4.2 Pipeline ASCII Diagram

```
USABroker.Dictionary.EligibilityStatus
        │
        ▼
main.bi_db.bronze_usabroker_dictionary_eligibilitystatus   ←── this object
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
| EligibilityStatusID | would inherit from `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md` but column `EligibilityStatusID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Name | would inherit from `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md` but column `Name` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 2 TN, 0 U | Elements: 2/2 | Source: bronze_tier1_inheritance*
