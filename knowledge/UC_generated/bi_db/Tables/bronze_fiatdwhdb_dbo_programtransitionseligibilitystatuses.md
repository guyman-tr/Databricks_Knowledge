---
object_fqn: main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:52Z'
upstreams:
- FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md
  source_database: FiatDwhDB
  source_schema: dbo
  source_table: ProgramTransitionsEligibilityStatuses
  source_repo: BankingDBs
  datalake_path: Bronze/FiatDwhDB/dbo/ProgramTransitionsEligibilityStatuses
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses

> Bronze ingest in `main.bi_db` (1:1 passthrough of `FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses`). 4 of 7 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 14:11:33 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses` (`BankingDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md`.

- Lake path: `Bronze/FiatDwhDB/dbo/ProgramTransitionsEligibilityStatuses`
- Copy strategy: `Append`
- Source database: `FiatDwhDB` (`BankingDBs`)
- Source schema/table: `dbo.ProgramTransitionsEligibilityStatuses`
- 4 of 7 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate PK (Tier 1 — inherited from FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses). |
| 1 | ProgramTransitionEligibilityId | LONG | YES | FK to dbo.ProgramTransitionsEligibility.Id. The eligibility assessment this status belongs to (Tier 1 — inherited from FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses). |
| 2 | StatusId | INT | YES | Outcome status: 0=Pending, 1=Completed, 2=Rejected, 3=Disabled, 4=Expired. See [Program Transition Eligibility Status](../../_glossary.md#program-transition-eligibility-status). (Dictionary.ProgramTransitionEligibilityStatuses) (Tier 1 — inherited from FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses). |
| 3 | Created | TIMESTAMP | YES | UTC timestamp when this status was recorded (Tier 1 — inherited from FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses). |
| 4 | etr_y | INT | YES | Source: FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 5 | etr_ym | STRING | YES | Source: FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | etr_ymd | DATE | YES | Source: FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses` | Primary | `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md` |

### 4.2 Pipeline ASCII Diagram

```
FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses
        │
        ▼
main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses) |
| ProgramTransitionEligibilityId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses) |
| StatusId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses) |
| Created | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses) |
| etr_y | would inherit from `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
