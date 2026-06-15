---
object_fqn: main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:13:08Z'
upstreams:
- UserApiDB.KYC.CryptoAssessmentAnswers
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md
  source_database: UserApiDB
  source_schema: KYC
  source_table: CryptoAssessmentAnswers
  source_repo: DB_Schema
  datalake_path: Bronze/UserApiDB/KYC/CryptoAssessmentAnswers
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

# bronze_userapidb_kyc_cryptoassessmentanswers

> Bronze ingest in `main.bi_db` (1:1 passthrough of `UserApiDB.KYC.CryptoAssessmentAnswers`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Oct 29 04:16:36 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `UserApiDB.KYC.CryptoAssessmentAnswers` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md`.

- Lake path: `Bronze/UserApiDB/KYC/CryptoAssessmentAnswers`
- Copy strategy: `Override`
- Source database: `UserApiDB` (`DB_Schema`)
- Source schema/table: `KYC.CryptoAssessmentAnswers`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Primary key. Auto-incrementing (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers). |
| 1 | AnswerId | INT | YES | FK to KYC.Answers. The answer option (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers). |
| 2 | IsCorrect | BOOLEAN | YES | Whether this answer demonstrates correct understanding of the crypto risk. 1=correct, 0=incorrect (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers). |
| 3 | AnswerCategoryId | INT | YES | FK to Dictionary.CryptoAssessmentAnswerCategory. Risk category (1-7): Complete Loss, Cyber-Risks, Diversification, Regulatory, Liquidity, Technical, Volatility. See [Crypto Assessment Answer Category](_glossary.md#crypto-assessment-answer-category) (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers). |
| 4 | IsEnabled | BOOLEAN | YES | Whether this answer is currently active in the assessment. Default: 1 (enabled) (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `UserApiDB.KYC.CryptoAssessmentAnswers` | Primary | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md` |

### 4.2 Pipeline ASCII Diagram

```
UserApiDB.KYC.CryptoAssessmentAnswers
        │
        ▼
main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers) |
| AnswerId | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers) |
| IsCorrect | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers) |
| AnswerCategoryId | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers) |
| IsEnabled | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.KYC.CryptoAssessmentAnswers) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
