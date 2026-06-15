---
object_fqn: main.etoro_kpi.ftd_click_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.ftd_click_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 9
row_count: null
generated_at: '2026-05-19T15:20:39Z'
upstreams:
- main.etoro_kpi.de_output_ftd_click
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_click_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_click_v.sql
concept_count: 1
formula_count: 9
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 1
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 8
  unverified_columns: 0
---

# ftd_click_v

> View in `main.etoro_kpi`. 1 business concept(s) in §2; 9 of 9 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ftd_click_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | arielka@etoro.com |
| **Row count** | n/a |
| **Column count** | 9 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 10 16:52:08 UTC 2026 |

---

## 1. Business Meaning

`ftd_click_v` is a view in `main.etoro_kpi` that composes 1 CASE-based classifier flag(s) computed from upstream IDs.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.etoro_kpi.de_output_ftd_click` → this object. Canonical upstream documentation: `knowledge/UC_generated/etoro_kpi/<Tables|Views>/de_output_ftd_click.md`.

Of its 9 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 1 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 8 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `initial_deposit_click_type` computed flag
**What**: Computed flag on `initial_deposit_click_type` set to `'                          '` when the predicates below hold, else `None`.
**Columns Involved**: `initial_deposit_click_type`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_click_v.sql` etoro_kpi.sql L44-L50

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
| Filter on discriminator flags | Use `initial_deposit_click_type = 1`-style filters on the precomputed flag columns (`initial_deposit_click_type`) instead of recomputing the underlying CASE predicates downstream. |

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
| 1 | gcid | STRING | YES | Source: `main.etoro_kpi.de_output_ftd_click.gcid`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.de_output_ftd_click`). |
| 1 | realcid | LONG | YES | Source: `main.etoro_kpi.de_output_ftd_click.realcid`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.de_output_ftd_click`). |
| 2 | initial_deposit_click | TIMESTAMP | YES | Source: `main.etoro_kpi.de_output_ftd_click.initial_deposit_click`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.de_output_ftd_click`). |
| 3 | ftd_wizard_intro | TIMESTAMP | YES | Source: `main.etoro_kpi.de_output_ftd_click.ftd_wizard_intro`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.de_output_ftd_click`). |
| 4 | ftd_wizard_amount | TIMESTAMP | YES | Source: `main.etoro_kpi.de_output_ftd_click.ftd_wizard_amount`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.de_output_ftd_click`). |
| 5 | ftd_wizard_mean_of_payment | TIMESTAMP | YES | Source: `main.etoro_kpi.de_output_ftd_click.ftd_wizard_mean_of_payment`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.de_output_ftd_click`). |
| 6 | final_deposit_click | TIMESTAMP | YES | Source: `main.etoro_kpi.de_output_ftd_click.final_deposit_click`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.de_output_ftd_click`). |
| 7 | initial_deposit_clicks_combined | TIMESTAMP | YES | Source: `main.etoro_kpi.de_output_ftd_click.max_time`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.de_output_ftd_click`). |
| 8 | initial_deposit_click_type | STRING | YES | `initial_deposit_click_type` computed flag. Formula: `CASE WHEN max_time IS NULL THEN NULL WHEN max_time = initial_deposit_click THEN 'initial_deposit_click' WHEN max_time = ftd_wizard_intro THEN 'ftd_wizard_intro' WHEN ma…`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.etoro_kpi.de_output_ftd_click` | Primary | `knowledge/UC_generated/etoro_kpi/<Tables|Views>/de_output_ftd_click.md` |

### 5.2 Pipeline ASCII Diagram

```
main.etoro_kpi.de_output_ftd_click
        │
        ▼
main.etoro_kpi.ftd_click_v   ←── this object
        │
        ▼
main.etoro_kpi.ftd_funnel_v
main.etoro_kpi.ftd_funnel_v_dev
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=9 runtime=9 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.etoro_kpi.de_output_ftd_click` (wiki: `knowledge/UC_generated/etoro_kpi/<Tables|Views>/de_output_ftd_click.md`)

### 6.2 Referenced By (downstream consumers)

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 9 | Tiers: 0 T1, 1 T2, 0 T3, 0 T4, 0 T5, 8 TN, 0 U | Elements: 9/9 | Source: view_definition*
