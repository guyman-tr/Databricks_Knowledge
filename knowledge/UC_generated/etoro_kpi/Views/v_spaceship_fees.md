---
object_fqn: main.etoro_kpi.v_spaceship_fees
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.v_spaceship_fees
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T15:20:42Z'
upstreams:
- main.spaceship.bronze_spaceship_metabase_user_beta
- main.spaceship.bronze_spaceship_metabase_super_transactions
- main.spaceship.bronze_spaceship_metabase_voyager_account_fees
- main.spaceship.bronze_spaceship_metabase_voyager_management_fees
- main.spaceship.spaceship_metabase_voyager_product_balances
- main.spaceship.bronze_spaceship_metabase_nova_fees
- main.spaceship.bronze_spaceship_metabase_nova_transactions
- main.bi_db.bronze_sub_accounts_accounts
- main.spaceship.bronze_spaceship_metabase_contact
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_fees.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_fees.sql
concept_count: 6
formula_count: 7
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 7
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_spaceship_fees

> View in `main.etoro_kpi`. 6 business concept(s) in §2; 7 of 7 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_spaceship_fees` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 7 |
| **Concepts** | 6 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Apr 16 12:32:55 UTC 2026 |

---

## 1. Business Meaning

`v_spaceship_fees` is a view in `main.etoro_kpi` that composes 6 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.spaceship.bronze_spaceship_metabase_user_beta` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 10 object(s), listed in §5 Lineage.

Of its 7 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 7 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `super_fees`: `type = '    '`
**What**: `WHERE` clause at the top of scope `super_fees` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `type`
**Rules**:
- `type = '    '`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_fees.sql` L30

### 2.2 Filter on scope `voyager_mgmt_fees`: `aud_fee_total <> 0`; `aud_balance > 0`
**What**: `WHERE` clause at the top of scope `voyager_mgmt_fees` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `aud_fee_total`, `aud_balance`
**Rules**:
- `aud_fee_total <> 0`
- `aud_balance > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_fees.sql` L74

### 2.3 Filter on scope `nova_fees`: `aud_net_amount <> 0`
**What**: `WHERE` clause at the top of scope `nova_fees` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `aud_net_amount`
**Rules**:
- `aud_net_amount <> 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_fees.sql` L86

### 2.4 Filter on scope `nova_fx_fees`: `order_status = '         '`; `order_fx_aud_fee <> 0`
**What**: `WHERE` clause at the top of scope `nova_fx_fees` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `order_status`, `order_fx_aud_fee`
**Rules**:
- `order_status = '         '`
- `order_fx_aud_fee <> 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_fees.sql` L98

### 2.5 Filter on scope `user_gcid`: `providerName = '         '`
**What**: `WHERE` clause at the top of scope `user_gcid` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `providerName`
**Rules**:
- `providerName = '         '`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_fees.sql` L110

### 2.6 Filter on scope `aud_usd_rates`: `InstrumentID = 7`
**What**: `WHERE` clause at the top of scope `aud_usd_rates` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `InstrumentID`
**Rules**:
- `InstrumentID = 7`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_spaceship_fees.sql` L119

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

- Scope `super_fees` applies `type = '    '` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `voyager_mgmt_fees` applies `aud_fee_total <> 0`; `aud_balance > 0` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `nova_fees` applies `aud_net_amount <> 0` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `nova_fx_fees` applies `order_status = '         '`; `order_fx_aud_fee <> 0` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `user_gcid` applies `providerName = '         '` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `aud_usd_rates` applies `InstrumentID = 7` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | DATE | YES | Cast of upstream column. Formula: `CAST(paid_date AS DATE)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`) |
| 1 | date_id | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(f.date, 'yyyyMMdd') AS INT)`. (Tier 2 — computed in source) |
| 2 | product | STRING | NO | Literal constant set in this object. Formula: `'Super'`. (Tier 2 — literal) |
| 3 | user_id | STRING | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(user_id, member_id)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`) |
| 4 | gcid | LONG | YES | Direct passthrough from upstream. Formula: `gcid`. (Tier 2 — from `main.bi_db.bronze_sub_accounts_accounts`) |
| 5 | total_fees_aud | DOUBLE | YES | Function call computed in source. Formula: `ABS(SUM(f.fee_amount))`. (Tier 2 — literal) |
| 6 | total_fees_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `ABS(SUM(f.fee_amount)) * COALESCE(aud_to_usd_rate, 0)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.spaceship.bronze_spaceship_metabase_user_beta` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_super_transactions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_voyager_account_fees` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_voyager_management_fees` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.spaceship_metabase_voyager_product_balances` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_nova_fees` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_nova_transactions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.spaceship.bronze_spaceship_metabase_contact` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `main.etoro_kpi_prep.v_spaceship_fees` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_spaceship_fees.md` |

### 5.2 Pipeline ASCII Diagram

```
main.spaceship.bronze_spaceship_metabase_user_beta
main.spaceship.bronze_spaceship_metabase_super_transactions
main.spaceship.bronze_spaceship_metabase_voyager_account_fees
... (8 more upstream(s))
        │
        ▼
main.etoro_kpi.v_spaceship_fees   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=7 runtime=7 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.spaceship.bronze_spaceship_metabase_user_beta` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 10 additional object(s)
- **Wiki coverage**: 3/10 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 6 | Formulas: 7 | Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: view_definition*
