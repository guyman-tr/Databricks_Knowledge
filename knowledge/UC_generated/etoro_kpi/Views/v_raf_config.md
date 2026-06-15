---
object_fqn: main.etoro_kpi.v_raf_config
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.v_raf_config
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T15:20:42Z'
upstreams:
- main.experience.bronze_rafcompensations_config_viewconfig
- main.general.bronze_etoro_dictionary_regulation
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_raf_config.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_raf_config.sql
concept_count: 0
formula_count: 15
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 15
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_raf_config

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 15 of 15 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_raf_config` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 13 06:10:58 UTC 2026 |

---

## 1. Business Meaning

`v_raf_config` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.experience.bronze_rafcompensations_config_viewconfig` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 15 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 15 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | CountryName | STRING | YES | Direct passthrough from upstream. Formula: `CountryName`. (Tier 2 — computed in source) |
| 1 | RegulationName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_regulation`) |
| 2 | ReferringCompensationInDollar | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `ReferringCompensationInCents/100`. (Tier 2 — computed in source) |
| 3 | ReferredCompensationInDollar | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `ReferredCompensationInCents/100`. (Tier 2 — computed in source) |
| 4 | MaxNumberOfCompensations | INT | YES | Direct passthrough from upstream. Formula: `MaxNumberOfCompensations`. (Tier 2 — computed in source) |
| 5 | FraudScore | DOUBLE | YES | Direct passthrough from upstream. Formula: `FraudScore`. (Tier 2 — computed in source) |
| 6 | LevelName | STRING | YES | Direct passthrough from upstream. Formula: `LevelName`. (Tier 2 — computed in source) |
| 7 | ValidFrom | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `ValidFrom`. (Tier 2 — computed in source) |
| 8 | ReferringMinDepositInDollar | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `ReferringMinDepositInCents/100`. (Tier 2 — computed in source) |
| 9 | ReferredMinDepositInDollar | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `ReferredMinDepositInCents/100`. (Tier 2 — computed in source) |
| 10 | RafProgramStartDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `RafProgramStartDate`. (Tier 2 — computed in source) |
| 11 | DaysToWaitFromFTD | INT | YES | Direct passthrough from upstream. Formula: `DaysToWaitFromFTD`. (Tier 2 — computed in source) |
| 12 | ReferringMinPositionsAmountInDollar | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `ReferringMinPositionsAmountInCents/100`. (Tier 2 — computed in source) |
| 13 | ReferredMinPositionsAmountInDollar | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `ReferredMinPositionsAmountInCents/100`. (Tier 2 — computed in source) |
| 14 | DaysToCheckMinPositionsAmountFromRegistration | INT | YES | Direct passthrough from upstream. Formula: `DaysToCheckMinPositionsAmountFromRegistration`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.experience.bronze_rafcompensations_config_viewconfig` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.general.bronze_etoro_dictionary_regulation` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |

### 5.2 Pipeline ASCII Diagram

```
main.experience.bronze_rafcompensations_config_viewconfig
main.general.bronze_etoro_dictionary_regulation
        │
        ▼
main.etoro_kpi.v_raf_config   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.experience.bronze_rafcompensations_config_viewconfig` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 15 | Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 15/15 | Source: view_definition*
