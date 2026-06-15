---
object_fqn: main.bi_db.bronze_userapidb_dwh_questions_answers_v
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_userapidb_dwh_questions_answers_v
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:13:07Z'
upstreams:
- UserApiDB.DWH.Questions_Answers_V
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md
  source_database: UserApiDB
  source_schema: DWH
  source_table: Questions_Answers_V
  source_repo: DB_Schema
  datalake_path: Bronze/UserApiDB/DWH/Questions_Answers_V
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_userapidb_dwh_questions_answers_v

> Bronze ingest in `main.bi_db` (1:1 passthrough of `UserApiDB.DWH.Questions_Answers_V`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_userapidb_dwh_questions_answers_v` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Jan 17 10:12:47 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `UserApiDB.DWH.Questions_Answers_V` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md`.

- Lake path: `Bronze/UserApiDB/DWH/Questions_Answers_V`
- Copy strategy: `Override`
- Source database: `UserApiDB` (`DB_Schema`)
- Source schema/table: `DWH.Questions_Answers_V`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | QuestionId | INT | YES | KYC question identifier. From KYC.Questions. Groups all answer rows for the same question (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V). |
| 1 | QuestionText | STRING | YES | The full text of the KYC question as shown to the user. From KYC.Questions (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V). |
| 2 | MultipleSelection | BOOLEAN | YES | Whether the user may select more than one answer for this question. 1=multiple allowed, 0=single answer only. From KYC.Questions (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V). |
| 3 | AnswerId | INT | YES | KYC answer option identifier. From KYC.Answers via KYC.QuestionsAnswers junction (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V). |
| 4 | AnswerText | STRING | YES | The full text of the answer option as shown to the user. From KYC.Answers (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `UserApiDB.DWH.Questions_Answers_V` | Primary | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md` |

### 4.2 Pipeline ASCII Diagram

```
UserApiDB.DWH.Questions_Answers_V
        │
        ▼
main.bi_db.bronze_userapidb_dwh_questions_answers_v   ←── this object
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
| QuestionId | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V) |
| QuestionText | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V) |
| MultipleSelection | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V) |
| AnswerId | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V) |
| AnswerText | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.DWH.Questions_Answers_V) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
