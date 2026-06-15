---
object_fqn: main.bi_dealing.gold_dealing_delta_diffusionanalysis_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_dealing.gold_dealing_delta_diffusionanalysis_v
schema: bi_dealing
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:48:14Z'
upstreams:
- main.bi_dealing.gold_dealing_delta_diffusionanalysis
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_dealing/_discovery/source_code/gold_dealing_delta_diffusionanalysis_v.sql
  source_code_snapshot: knowledge/UC_generated/bi_dealing/_discovery/source_code/gold_dealing_delta_diffusionanalysis_v.sql
concept_count: 0
formula_count: 1
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 1
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 7
  unverified_columns: 5
---

# gold_dealing_delta_diffusionanalysis_v

> View in `main.bi_dealing`. 0 business concept(s) in §2; 8 of 13 columns documented from anchored evidence; 5 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.gold_dealing_delta_diffusionanalysis_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | olegab@etoro.com |
| **Row count** | n/a |
| **Column count** | 13 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 7 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue May 19 11:10:52 UTC 2026 |

---

## 1. Business Meaning

`gold_dealing_delta_diffusionanalysis_v` is a view in `main.bi_dealing`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_dealing.gold_dealing_delta_diffusionanalysis` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_delta_diffusionanalysis.md`.

Of its 13 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 1 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 7 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | PositionsTime | TIMESTAMP | YES | Source: `main.bi_dealing.gold_dealing_delta_diffusionanalysis.PositionsTime`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.gold_dealing_delta_diffusionanalysis`). |
| 1 | InstrumentName | STRING | YES | Source: `main.bi_dealing.gold_dealing_delta_diffusionanalysis.InstrumentName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.gold_dealing_delta_diffusionanalysis`). |
| 2 | InstrumentID | INT | YES | Source: `main.bi_dealing.gold_dealing_delta_diffusionanalysis.InstrumentID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.gold_dealing_delta_diffusionanalysis`). |
| 3 | HedgeServerID | INT | YES | Source: `main.bi_dealing.gold_dealing_delta_diffusionanalysis.HedgeServerID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.gold_dealing_delta_diffusionanalysis`). |
| 4 | NOP | STRING | YES | Transform `udf` for column `NOP` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | NOP_80Percent | STRING | YES | Transform `udf` for column `NOP_80Percent` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | Delta | STRING | YES | Transform `unknown` for column `Delta` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | DeltaSquared | STRING | YES | Transform `unknown` for column `DeltaSquared` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 8 | Mid | FLOAT | YES | Source: `main.bi_dealing.gold_dealing_delta_diffusionanalysis.Mid`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.gold_dealing_delta_diffusionanalysis`). |
| 9 | T | INT | YES | Source: `main.bi_dealing.gold_dealing_delta_diffusionanalysis.T`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.gold_dealing_delta_diffusionanalysis`). |
| 10 | Sigma | STRING | NO | Transform `coalesce` for column `Sigma` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 11 | SigmaDate | DATE | YES | Source: `main.bi_dealing.gold_dealing_delta_diffusionanalysis.SigmaDate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.gold_dealing_delta_diffusionanalysis`). |
| 12 | DeltaRoot | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: bi_dealing.gold_dealing_delta_diffusionanalysis_v -- C…`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_dealing.gold_dealing_delta_diffusionanalysis` | Primary | `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_delta_diffusionanalysis.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_dealing.gold_dealing_delta_diffusionanalysis
        │
        ▼
main.bi_dealing.gold_dealing_delta_diffusionanalysis_v   ←── this object
        │
        ▼
main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save1
main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save2
main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save3
... (4 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=13 runtime=13 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_dealing.gold_dealing_delta_diffusionanalysis` (wiki: `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_delta_diffusionanalysis.md`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save1`
- `main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save2`
- `main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save3`
- `main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save4`
- `main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save6`
- `main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_save7`
- `main.bi_dealing_stg.bi_output_dealing_hedgefactor_df_savetest`

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 1 | Tiers: 0 T1, 1 T2, 0 T3, 0 T4, 0 T5, 7 TN, 5 U | Elements: 13/13 | Source: view_definition*
