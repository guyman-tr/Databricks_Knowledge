---
object_fqn: main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 4
row_count: null
generated_at: '2026-05-19T12:13:02Z'
upstreams:
- USABroker.apex.OptionsReasoningFormQuestionsAnswers
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md
  source_database: USABroker
  source_schema: apex
  source_table: OptionsReasoningFormQuestionsAnswers
  source_repo: ComplianceDBs
  datalake_path: Bronze/USABroker/apex/OptionsReasoningFormQuestionsAnswers
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

# bronze_usabroker_apex_optionsreasoningformquestionsanswers

> Bronze ingest in `main.bi_db` (1:1 passthrough of `USABroker.apex.OptionsReasoningFormQuestionsAnswers`). 4 of 4 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 4 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Oct 16 19:16:16 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `USABroker.apex.OptionsReasoningFormQuestionsAnswers` (`ComplianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md`.

- Lake path: `Bronze/USABroker/apex/OptionsReasoningFormQuestionsAnswers`
- Copy strategy: `Override`
- Source database: `USABroker` (`ComplianceDBs`)
- Source schema/table: `apex.OptionsReasoningFormQuestionsAnswers`
- 4 of 4 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReasoningFormID | STRING | YES | FK to Apex.OptionsReasoningForm. Links this question-answer pair to its parent reasoning form. Part of the UNIQUE constraint with KycQuestionID (Tier 1 — inherited from USABroker.apex.OptionsReasoningFormQuestionsAnswers). |
| 1 | KycQuestionID | INT | YES | Identifier of the KYC (Know Your Customer) suitability question that was changed. References the suitability questionnaire system (external). Part of the UNIQUE constraint with ReasoningFormID (Tier 1 — inherited from USABroker.apex.OptionsReasoningFormQuestionsAnswers). |
| 2 | ReasoningFormAnswerID | INT | YES | The customer's selected reasoning for changing this question. Implicit FK to Dictionary.OptionsReasoningFormAnswers: 1=Other, 2=Incorrect Selection, 3=Changed Mind, 4=Lifestyle Change. See [Options Reasoning Form Answers](_glossary.md#options-reasoning-form-answers). NULL until the customer provides their reasoning (Tier 1 — inherited from USABroker.apex.OptionsReasoningFormQuestionsAnswers). |
| 3 | OldKycAnswerID | INT | YES | The answer ID the customer previously had for this KYC question before the change. Provides the "before" state for the audit trail. A value of 0 indicates the question was not previously answered (Tier 1 — inherited from USABroker.apex.OptionsReasoningFormQuestionsAnswers). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `USABroker.apex.OptionsReasoningFormQuestionsAnswers` | Primary | `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md` |

### 4.2 Pipeline ASCII Diagram

```
USABroker.apex.OptionsReasoningFormQuestionsAnswers
        │
        ▼
main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers   ←── this object
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
| ReasoningFormID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.OptionsReasoningFormQuestionsAnswers) |
| KycQuestionID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.OptionsReasoningFormQuestionsAnswers) |
| ReasoningFormAnswerID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.OptionsReasoningFormQuestionsAnswers) |
| OldKycAnswerID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.OptionsReasoningFormQuestionsAnswers) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 4/4 | Source: bronze_tier1_inheritance*
