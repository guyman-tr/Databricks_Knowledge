---
object_fqn: main.etoro_kpi.kyc_for_compliance_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.kyc_for_compliance_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T15:20:40Z'
upstreams:
- main.general.bronze_etoro_customer_customer_masked
- main.compliance.bronze_userapidb_kyc_questions
- main.compliance.bronze_userapidb_kyc_answers
- main.compliance.bronze_userapidb_kyc_customeranswers
- main.compliance.bronze_userapidb_history_customeranswers
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/kyc_for_compliance_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/kyc_for_compliance_v.sql
concept_count: 0
formula_count: 8
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 7
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# kyc_for_compliance_v

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 8 of 8 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.kyc_for_compliance_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 8 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 08 13:14:55 UTC 2026 |

---

## 1. Business Meaning

`kyc_for_compliance_v` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.general.bronze_etoro_customer_customer_masked` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md`. Additional upstreams: 4 object(s), listed in §5 Lineage.

Of its 8 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 7 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: etoro_kpi.kyc_for_compliance_v -- Captured: 2026-05-19…`. (Tier 2 — computed in source) |
| 1 | CID | INT | YES | Customer ID - platform-internal primary key. From CustomerStatic. Used as the universal customer identifier across all tables (Tier 1 — inherited from main.general.bronze_etoro_customer_customer_masked). |
| 2 | OccurredAt | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `union all select GCID, OccurredAt_InSource AS OccurredAt, QuestionId, AnswerId, 0`. (Tier 2 — from `main.compliance.bronze_userapidb_history_customeranswers`) |
| 3 | QuestionId | INT | YES | Computed in source (transform kind not classified). Formula: `,CID ,aa.OccurredAt ,aa.QuestionId`. (Tier 2 — from `main.compliance.bronze_userapidb_kyc_customeranswers`) |
| 4 | QuestionText | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID ,aa.OccurredAt ,aa.QuestionId ,QuestionText`. (Tier 2 — from `compliance.bronze_userapidb_kyc_questions`, `main.compliance.bronze_userapidb_kyc_customeranswers`) |
| 5 | AnswerId | INT | YES | Computed in source (transform kind not classified). Formula: `,CID ,aa.OccurredAt ,aa.QuestionId ,QuestionText ,aa.AnswerId`. (Tier 2 — from `compliance.bronze_userapidb_kyc_questions`, `main.compliance.bronze_userapidb_kyc_customeranswers`) |
| 6 | AnswerText | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID ,aa.OccurredAt ,aa.QuestionId ,QuestionText ,aa.AnswerId ,AnswerText`. (Tier 2 — from `compliance.bronze_userapidb_kyc_answers`, `compliance.bronze_userapidb_kyc_questions`, `main.compliance.bronze_userapidb_kyc_customeranswers`) |
| 7 | Is_Current | INT | NO | Computed in source (transform kind not classified). Formula: `union all select GCID, OccurredAt_InSource AS OccurredAt, QuestionId, AnswerId, 0`. (Tier 2 — from `main.compliance.bronze_userapidb_history_customeranswers`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.general.bronze_etoro_customer_customer_masked` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md` |
| `main.compliance.bronze_userapidb_kyc_questions` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.Questions.md` |
| `main.compliance.bronze_userapidb_kyc_answers` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.Answers.md` |
| `main.compliance.bronze_userapidb_kyc_customeranswers` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CustomerAnswers.md` |
| `main.compliance.bronze_userapidb_history_customeranswers` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/History/Tables/History.CustomerAnswers.md` |

### 5.2 Pipeline ASCII Diagram

```
main.general.bronze_etoro_customer_customer_masked
main.compliance.bronze_userapidb_kyc_questions
main.compliance.bronze_userapidb_kyc_answers
... (2 more upstream(s))
        │
        ▼
main.etoro_kpi.kyc_for_compliance_v   ←── this object
        │
        ▼
main.bi_output_stg.churn_winback_recent_targets
main.bi_output_stg.churn_winback_summary
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=8 runtime=8 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.general.bronze_etoro_customer_customer_masked` (wiki: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md`)
- **JOIN/UNION upstreams**: 4 additional object(s)
- **Wiki coverage**: 4/4 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output_stg.churn_winback_recent_targets`
- `main.bi_output_stg.churn_winback_summary`

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 8 | Tiers: 1 T1, 7 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: view_definition*
