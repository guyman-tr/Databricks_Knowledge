---
object_fqn: main.etoro_kpi.crm_quality_assessment_per_case_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.crm_quality_assessment_per_case_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T15:20:34Z'
upstreams:
- main.crm.silver_crm_surveytaker__c
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/crm_quality_assessment_per_case_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/crm_quality_assessment_per_case_v.sql
concept_count: 0
formula_count: 3
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 3
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 5
---

# crm_quality_assessment_per_case_v

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 3 of 8 columns documented from anchored evidence; 5 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.crm_quality_assessment_per_case_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | katyfr@etoro.com |
| **Row count** | n/a |
| **Column count** | 8 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Tue May 12 07:32:55 UTC 2026 |

---

## 1. Business Meaning

`crm_quality_assessment_per_case_v` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.crm.silver_crm_surveytaker__c` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`).

Of its 8 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 3 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.crm.silver_crm_surveytaker__c` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | Case__c | STRING | YES | Arithmetic combination of upstream columns. Formula: `SELECT Case__c -- CaseID`. (Tier 2 — from `main.crm.silver_crm_surveytaker__c`) |
| 1 | Survey__c | STRING | YES | Transform `passthrough` for column `Survey__c` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 2 | Agent_Under_Assessment__c | STRING | YES | Transform `passthrough` for column `Agent_Under_Assessment__c` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 3 | Quality_Score__c | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `,Survey__c -- Id of the survey ,Agent_Under_Assessment__c -- CS agent that is under assessment ,TRY_CAST(Quality_Score__c AS DOUBLE) AS Quality_Score__c -- Grade the agent received regarding h…`. (Tier 2 — from `main.crm.silver_crm_surveytaker__c`) |
| 4 | Compliance_a__c | DECIMAL | YES | Transform `passthrough` for column `Compliance_a__c` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | Type_of_Communication__c | STRING | YES | Transform `passthrough` for column `Type_of_Communication__c` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | Team__c | STRING | YES | Transform `passthrough` for column `Team__c` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | CreatedDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `SELECT Case__c, Survey__c, Agent_Under_Assessment__c, Quality_Score__c, Compliance_a__c, Type_of_Communication__c, Team__c, CreatedDate`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.crm.silver_crm_surveytaker__c` | Primary | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.crm.silver_crm_surveytaker__c
        │
        ▼
main.etoro_kpi.crm_quality_assessment_per_case_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=8 runtime=8 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.crm.silver_crm_surveytaker__c` (wiki: `(no wiki)`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 3 | Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 0 T5, 0 TN, 5 U | Elements: 8/8 | Source: view_definition*
