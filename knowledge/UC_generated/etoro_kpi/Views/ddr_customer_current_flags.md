---
object_fqn: main.etoro_kpi.ddr_customer_current_flags
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.ddr_customer_current_flags
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T15:20:36Z'
upstreams:
- main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_customer_current_flags.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_customer_current_flags.sql
concept_count: 0
formula_count: 7
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 7
  unverified_columns: 0
---

# ddr_customer_current_flags

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 7 of 7 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_customer_current_flags` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 7 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Apr 20 07:40:28 UTC 2026 |

---

## 1. Business Meaning

`ddr_customer_current_flags` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` → this object. Canonical upstream documentation: `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/gold_de_user_dim_ddr_customer_dailystatus_scd.md`.

Of its 7 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 7 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | RealCID | STRING | YES | Source: `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd.RealCID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd`). |
| 1 | IsFunded | INT | YES | Source: `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd.IsFunded`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd`). |
| 2 | IsActiveTrade | INT | YES | Source: `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd.ActiveTraded`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd`). |
| 3 | BalanceOnly | INT | YES | Source: `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd.BalanceOnlyAccount`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd`). |
| 4 | PortfolioOnly | INT | YES | Source: `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd.Portfolio_Only`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd`). |
| 5 | IsChurn | INT | YES | Source: `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd.IsChurned`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd`). |
| 6 | IsWinback | INT | YES | Source: `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd.IsWinBack`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd`). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | Primary | `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/gold_de_user_dim_ddr_customer_dailystatus_scd.md` |

### 5.2 Pipeline ASCII Diagram

```
main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
        │
        ▼
main.etoro_kpi.ddr_customer_current_flags   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=7 runtime=7 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` (wiki: `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/gold_de_user_dim_ddr_customer_dailystatus_scd.md`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 7 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 7 TN, 0 U | Elements: 7/7 | Source: view_definition*
