---
object_fqn: main.bi_db.bronze_userapidb_dbo_v_customeranswers
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_userapidb_dbo_v_customeranswers
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:13:04Z'
upstreams:
- UserApiDB.dbo.V_CustomerAnswers
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md
  source_database: UserApiDB
  source_schema: dbo
  source_table: V_CustomerAnswers
  source_repo: DB_Schema
  datalake_path: Bronze/UserApiDB/dbo/V_CustomerAnswers
  copy_strategy: Merge
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 10
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_userapidb_dbo_v_customeranswers

> Bronze ingest in `main.bi_db` (1:1 passthrough of `UserApiDB.dbo.V_CustomerAnswers`). 10 of 13 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_userapidb_dbo_v_customeranswers` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Sep 28 10:23:02 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `UserApiDB.dbo.V_CustomerAnswers` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md`.

- Lake path: `Bronze/UserApiDB/dbo/V_CustomerAnswers`
- Copy strategy: `Merge`
- Source database: `UserApiDB` (`DB_Schema`)
- Source schema/table: `dbo.V_CustomerAnswers`
- 10 of 13 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | User who answered. From KYC.CustomerAnswers (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 1 | OccurredAt | TIMESTAMP | YES | When answer was submitted. From KYC.CustomerAnswers (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 2 | FreeText | STRING | YES | Free-text response. From KYC.CustomerAnswers (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 3 | QuestionId | INT | YES | Question identifier. From V_KYC (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 4 | QuestionText | STRING | YES | Question display text. From V_KYC -> KYC.Questions (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 5 | AnswerId | INT | YES | Answer identifier. From V_KYC (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 6 | AnswerText | STRING | YES | Answer display text. From V_KYC -> KYC.Answers (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 7 | MinThreshold | INT | YES | Min range value. From V_KYC -> KYC.AnswerThresholds (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 8 | MaxThreshold | INT | YES | Max range value. From V_KYC -> KYC.AnswerThresholds (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |
| 9 | etr_y | STRING | YES | Source: UserApiDB.dbo.V_CustomerAnswers.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | etr_ym | STRING | YES | Source: UserApiDB.dbo.V_CustomerAnswers.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | etr_ymd | STRING | YES | Source: UserApiDB.dbo.V_CustomerAnswers.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | MultipleSelection | BOOLEAN | YES | Whether question allows multiple answers. From V_KYC -> KYC.Questions (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `UserApiDB.dbo.V_CustomerAnswers` | Primary | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` |

### 4.2 Pipeline ASCII Diagram

```
UserApiDB.dbo.V_CustomerAnswers
        │
        ▼
main.bi_db.bronze_userapidb_dbo_v_customeranswers   ←── this object
        │
        ▼
main.de_output.customer_segments_mail_v
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
| GCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| OccurredAt | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| FreeText | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| QuestionId | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| QuestionText | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| AnswerId | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| AnswerText | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| MinThreshold | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| MaxThreshold | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |
| etr_y | would inherit from `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| MultipleSelection | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.V_CustomerAnswers) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
