---
object_fqn: main.etoro_kpi.ftd_funnel_kyc
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.ftd_funnel_kyc
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 3
row_count: null
generated_at: '2026-05-19T15:20:39Z'
upstreams:
- main.compliance.bronze_userapidb_kyc_customeranswers
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_kyc.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_kyc.sql
concept_count: 0
formula_count: 3
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 2
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# ftd_funnel_kyc

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 3 of 3 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ftd_funnel_kyc` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | eyalbo@etoro.com |
| **Row count** | n/a |
| **Column count** | 3 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 9 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Wed Jan 07 12:26:55 UTC 2026 |

---

## 1. Business Meaning

`ftd_funnel_kyc` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.compliance.bronze_userapidb_kyc_customeranswers` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CustomerAnswers.md`.

Of its 3 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 2 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | GCID | INT | YES | Part of composite PK. Global Customer ID (Tier 1 — inherited from main.compliance.bronze_userapidb_kyc_customeranswers). |
| 1 | First_KYC_Answer | TIMESTAMP | YES | Aggregate over upstream rows. Formula: `min(OccurredAt)`. (Tier 2 — from `main.compliance.bronze_userapidb_kyc_customeranswers`) |
| 2 | Last_KYC_Answer | TIMESTAMP | YES | Aggregate over upstream rows. Formula: `max(OccurredAt)`. (Tier 2 — from `main.compliance.bronze_userapidb_kyc_customeranswers`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.compliance.bronze_userapidb_kyc_customeranswers` | Primary | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CustomerAnswers.md` |

### 5.2 Pipeline ASCII Diagram

```
main.compliance.bronze_userapidb_kyc_customeranswers
        │
        ▼
main.etoro_kpi.ftd_funnel_kyc   ←── this object
        │
        ▼
main.etoro_kpi.ftd_funnel_aus
main.etoro_kpi.ftd_funnel_fr
main.etoro_kpi.ftd_funnel_ger
... (6 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=3 runtime=3 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.compliance.bronze_userapidb_kyc_customeranswers` (wiki: `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CustomerAnswers.md`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi.ftd_funnel_aus`
- `main.etoro_kpi.ftd_funnel_fr`
- `main.etoro_kpi.ftd_funnel_ger`
- `main.etoro_kpi.ftd_funnel_ita`
- `main.etoro_kpi.ftd_funnel_uae`
- `main.etoro_kpi.ftd_funnel_uk`
- `main.etoro_kpi.ftd_funnel_usa`
- `main.etoro_kpi.ftd_funnel_v`
- `main.etoro_kpi.ftd_funnel_v_dev`

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 3 | Tiers: 1 T1, 2 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 3/3 | Source: view_definition*
