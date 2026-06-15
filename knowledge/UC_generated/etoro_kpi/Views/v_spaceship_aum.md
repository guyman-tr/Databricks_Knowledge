---
object_fqn: main.etoro_kpi.v_spaceship_aum
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.v_spaceship_aum
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T15:20:42Z'
upstreams:
- main.spaceship.bronze_spaceship_metabase_contact
- main.spaceship.bronze_spaceship_metabase_user_beta
- main.spaceship.bronze_spaceship_metabase_super_user_balances
- main.spaceship.spaceship_metabase_voyager_user_balances
- main.spaceship.bronze_spaceship_metabase_nova_user_balances
- main.bi_db.bronze_sub_accounts_accounts
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
- main.etoro_kpi_prep.v_spaceship_aum
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_aum.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_aum.sql
concept_count: 2
formula_count: 13
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 13
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_spaceship_aum

> View in `main.etoro_kpi`. 2 business concept(s) in §2; 13 of 13 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_spaceship_aum` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 13 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 3 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Thu Apr 16 12:32:52 UTC 2026 |

---

## 1. Business Meaning

`v_spaceship_aum` is a view in `main.etoro_kpi` that composes 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.spaceship.bronze_spaceship_metabase_contact` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 7 object(s), listed in §5 Lineage.

Of its 13 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 13 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `user_gcid`: `providerName = '         '`
**What**: `WHERE` clause at the top of scope `user_gcid` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `providerName`
**Rules**:
- `providerName = '         '`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_aum.sql` L133

### 2.2 Filter on scope `aud_usd_rates`: `InstrumentID = 7`
**What**: `WHERE` clause at the top of scope `aud_usd_rates` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `InstrumentID`
**Rules**:
- `InstrumentID = 7`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_aum.sql` L142

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
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `user_gcid` applies `providerName = '         '` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `aud_usd_rates` applies `InstrumentID = 7` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | DATE | YES | Cast of upstream column. Formula: `CAST(date AS DATE)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_user_balances`) |
| 1 | date_id | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(date, 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_user_balances`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.spaceship_metabase_voyager_user_balances` (+1 more)) |
| 2 | user_id | STRING | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(canonical_user_id, member_id)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_user_balances`, `main.spaceship.bronze_spaceship_metabase_user_beta`) |
| 3 | gcid | LONG | YES | Direct passthrough from upstream. Formula: `gcid`. (Tier 2 — from `main.bi_db.bronze_sub_accounts_accounts`) |
| 4 | super_balance_aud | DOUBLE | YES | Computed flag (CASE expression in source). Formula: `SUM(CASE WHEN src = 'S' THEN balance_aud ELSE 0 END)`. (Tier 2 — computed in source) |
| 5 | voyager_balance_aud | DOUBLE | YES | Computed flag (CASE expression in source). Formula: `SUM(CASE WHEN src = 'V' THEN balance_aud ELSE 0 END)`. (Tier 2 — computed in source) |
| 6 | nova_balance_aud | DOUBLE | YES | Computed flag (CASE expression in source). Formula: `SUM(CASE WHEN src = 'N' THEN balance_aud ELSE 0 END)`. (Tier 2 — computed in source) |
| 7 | total_balance_aud | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `super_balance_aud + voyager_balance_aud + nova_balance_aud`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_user_balances`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.spaceship_metabase_voyager_user_balances` (+1 more)) |
| 8 | super_balance_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `super_balance_aud * COALESCE(aud_to_usd_rate, 0)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, `main.spaceship.bronze_spaceship_metabase_super_user_balances`, `main.spaceship.bronze_spaceship_metabase_user_beta` (+2 more)) |
| 9 | voyager_balance_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `voyager_balance_aud * COALESCE(aud_to_usd_rate, 0)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, `main.spaceship.bronze_spaceship_metabase_super_user_balances`, `main.spaceship.bronze_spaceship_metabase_user_beta` (+2 more)) |
| 10 | nova_balance_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `nova_balance_aud * COALESCE(aud_to_usd_rate, 0)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, `main.spaceship.bronze_spaceship_metabase_super_user_balances`, `main.spaceship.bronze_spaceship_metabase_user_beta` (+2 more)) |
| 11 | total_balance_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `+ nova_balance_aud) * COALESCE(aud_to_usd_rate, 0)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, `main.spaceship.bronze_spaceship_metabase_super_user_balances`, `main.spaceship.bronze_spaceship_metabase_user_beta` (+2 more)) |
| 12 | is_funded | BOOLEAN | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN (super_balance_aud + voyager_balance_aud + nova_balance_aud) > 0 THEN TRUE ELSE FALSE END`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_user_balances`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.spaceship_metabase_voyager_user_balances` (+1 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.spaceship.bronze_spaceship_metabase_contact` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_user_beta` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_super_user_balances` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.spaceship_metabase_voyager_user_balances` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_nova_user_balances` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `main.etoro_kpi_prep.v_spaceship_aum` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_spaceship_aum.md` |

### 5.2 Pipeline ASCII Diagram

```
main.spaceship.bronze_spaceship_metabase_contact
main.spaceship.bronze_spaceship_metabase_user_beta
main.spaceship.bronze_spaceship_metabase_super_user_balances
... (5 more upstream(s))
        │
        ▼
main.etoro_kpi.v_spaceship_aum   ←── this object
        │
        ▼
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
main.etoro_kpi_prep.v_ddr_fact_aum
main.etoro_kpi_prep.v_dim_dataplatform_uuid
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=13 runtime=13 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.spaceship.bronze_spaceship_metabase_contact` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 7 additional object(s)
- **Wiki coverage**: 3/7 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum`
- `main.etoro_kpi_prep.v_ddr_fact_aum`
- `main.etoro_kpi_prep.v_dim_dataplatform_uuid`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 13 | Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 13/13 | Source: view_definition*
