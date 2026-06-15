---
object_fqn: main.etoro_kpi.v_spaceship_mimo
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.v_spaceship_mimo
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T15:20:42Z'
upstreams:
- main.etoro_kpi_prep.v_spaceship_mimo
- main.spaceship.bronze_spaceship_analytics_fct_money_transactions
- main.spaceship.bronze_spaceship_metabase_nova_transactions
- main.spaceship.bronze_spaceship_metabase_super_transactions
- main.spaceship.spaceship_metabase_voyager_user_balances
- main.spaceship.bronze_spaceship_metabase_user_beta
- main.bi_db.bronze_sub_accounts_accounts
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
- main.spaceship.bronze_spaceship_metabase_contact
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_mimo.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_mimo.sql
concept_count: 0
formula_count: 0
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 15
---

# v_spaceship_mimo

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 0 of 15 columns documented from anchored evidence; 15 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_spaceship_mimo` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Apr 20 06:30:57 UTC 2026 |

---

## 1. Business Meaning

`v_spaceship_mimo` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.etoro_kpi_prep.v_spaceship_mimo` → this object. Canonical upstream documentation: `knowledge/UC_generated/etoro_kpi_prep/Views/v_spaceship_mimo.md`. Additional upstreams: 8 object(s), listed in §5 Lineage.

Of its 15 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | date | DATE | YES | Transform `unknown` for column `date` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 1 | date_id | INT | YES | Transform `unknown` for column `date_id` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 2 | product | STRING | YES | Transform `unknown` for column `product` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 3 | is_internal_transfer | BOOLEAN | NO | Transform `unknown` for column `is_internal_transfer` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 4 | user_id | STRING | YES | Transform `unknown` for column `user_id` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | gcid | LONG | YES | Transform `unknown` for column `gcid` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | total_deposits_aud | DOUBLE | YES | Transform `unknown` for column `total_deposits_aud` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | total_withdrawals_aud | DOUBLE | YES | Transform `unknown` for column `total_withdrawals_aud` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 8 | net_flow_aud | DOUBLE | YES | Transform `unknown` for column `net_flow_aud` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 9 | total_deposits_usd | DOUBLE | YES | Transform `unknown` for column `total_deposits_usd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 10 | total_withdrawals_usd | DOUBLE | YES | Transform `unknown` for column `total_withdrawals_usd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 11 | net_flow_usd | DOUBLE | YES | Transform `unknown` for column `net_flow_usd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 12 | count_deposits | LONG | YES | Transform `unknown` for column `count_deposits` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 13 | count_withdrawals | LONG | YES | Transform `unknown` for column `count_withdrawals` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 14 | is_ftd | BOOLEAN | NO | Transform `unknown` for column `is_ftd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.etoro_kpi_prep.v_spaceship_mimo` | Primary | `knowledge/UC_generated/etoro_kpi_prep/Views/v_spaceship_mimo.md` |
| `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_nova_transactions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_super_transactions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.spaceship_metabase_voyager_user_balances` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_user_beta` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `main.spaceship.bronze_spaceship_metabase_contact` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.etoro_kpi_prep.v_spaceship_mimo
main.spaceship.bronze_spaceship_analytics_fct_money_transactions
main.spaceship.bronze_spaceship_metabase_nova_transactions
... (6 more upstream(s))
        │
        ▼
main.etoro_kpi.v_spaceship_mimo   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.etoro_kpi_prep.v_spaceship_mimo` (wiki: `knowledge/UC_generated/etoro_kpi_prep/Views/v_spaceship_mimo.md`)
- **JOIN/UNION upstreams**: 8 additional object(s)
- **Wiki coverage**: 2/8 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 0 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 15 U | Elements: 15/15 | Source: view_definition*
