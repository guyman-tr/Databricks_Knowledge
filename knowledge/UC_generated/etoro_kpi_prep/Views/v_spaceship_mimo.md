---
object_fqn: main.etoro_kpi_prep.v_spaceship_mimo
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_spaceship_mimo
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T12:26:42Z'
upstreams:
- main.spaceship.bronze_spaceship_metabase_user_beta
- main.spaceship.bronze_spaceship_metabase_contact
- main.spaceship.bronze_spaceship_metabase_super_transactions
- main.spaceship.bronze_spaceship_analytics_fct_money_transactions
- main.spaceship.spaceship_metabase_voyager_user_balances
- main.spaceship.bronze_spaceship_metabase_nova_transactions
- main.bi_db.bronze_sub_accounts_accounts
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql
concept_count: 8
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

# v_spaceship_mimo

> View in `main.etoro_kpi_prep`. 8 business concept(s) in §2; 15 of 15 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_spaceship_mimo` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 8 (see §2) |
| **Downstream consumers** | 3 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Mon Apr 20 06:30:42 UTC 2026 |

---

## 1. Business Meaning

`v_spaceship_mimo` is a view in `main.etoro_kpi_prep` that composes 6 CASE-based classifier flag(s) computed from upstream IDs, 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.spaceship.bronze_spaceship_metabase_user_beta` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 7 object(s), listed in §5 Lineage.

Of its 15 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 15 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `is_deposit` discriminator: `type = '             '`, `description = '                 '`, `type = '             '` → set to 1 else 0
**What**: Computed flag on `is_deposit` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `is_deposit`
**Rules**:
- `type = '             '`
- `description = '                 '`
- `type = '             '`
- `description = '                 '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql` etoro_kpi_prep.sql L34-L50
**Source(s)**: `main.spaceship.bronze_spaceship_metabase_super_transactions`

### 2.2 `is_withdrawal` computed flag
**What**: Computed flag on `is_withdrawal` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `is_withdrawal`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql` etoro_kpi_prep.sql L51-L55
**Source(s)**: `main.spaceship.bronze_spaceship_metabase_super_transactions`

### 2.3 `is_deposit` computed flag
**What**: Computed flag on `is_deposit` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `is_deposit`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql` etoro_kpi_prep.sql L67-L105
**Source(s)**: `main.spaceship.bronze_spaceship_analytics_fct_money_transactions`, `main.spaceship.bronze_spaceship_metabase_contact`

### 2.4 `is_deposit` discriminator: `order_direction = '   '`, `order_direction = '    '`, `order_direction = '   '` → set to 1 else 0
**What**: Computed flag on `is_deposit` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `is_deposit`
**Rules**:
- `order_direction = '   '`
- `order_direction = '    '`
- `order_direction = '   '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql` etoro_kpi_prep.sql L153-L161
**Source(s)**: `main.spaceship.bronze_spaceship_metabase_nova_transactions`

### 2.5 `is_withdrawal` discriminator: `order_direction = '    '` → set to 1 else 0
**What**: Computed flag on `is_withdrawal` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `is_withdrawal`
**Rules**:
- `order_direction = '    '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql` etoro_kpi_prep.sql L162-L162
**Source(s)**: `main.spaceship.bronze_spaceship_metabase_nova_transactions`

### 2.6 `ftd_product` computed flag
**What**: Computed flag on `ftd_product` set to `'    '` when the predicates below hold, else `None`.
**Columns Involved**: `ftd_product`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql` etoro_kpi_prep.sql L199-L203
**Source(s)**: `main.spaceship.bronze_spaceship_metabase_user_beta`

### 2.7 Filter on scope `user_gcid`: `providerName = '         '`
**What**: `WHERE` clause at the top of scope `user_gcid` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `providerName`
**Rules**:
- `providerName = '         '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql` L254

### 2.8 Filter on scope `aud_usd_rates`: `InstrumentID = 7`
**What**: `WHERE` clause at the top of scope `aud_usd_rates` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `InstrumentID`
**Rules**:
- `InstrumentID = 7`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_spaceship_mimo.sql` L263

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
| Filter on discriminator flags | Use `ftd_product = 1`-style filters on the precomputed flag columns (`ftd_product`, `is_deposit`, `is_withdrawal`) instead of recomputing the underlying CASE predicates downstream. |
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
| 1 | date | DATE | YES | Cast of upstream column. Formula: `CAST(paid_date AS DATE)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`) |
| 1 | date_id | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(date, 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (+3 more)) |
| 2 | product | STRING | YES | Literal constant set in this object. Formula: `'Super'`. (Tier 2 — literal) |
| 3 | is_internal_transfer | BOOLEAN | NO | Direct passthrough from upstream. Formula: `FALSE`. (Tier 2 — computed in source) |
| 4 | user_id | STRING | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(user_id, member_id)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_metabase_super_transactions`) |
| 5 | gcid | LONG | YES | Direct passthrough from upstream. Formula: `gcid`. (Tier 2 — from `main.bi_db.bronze_sub_accounts_accounts`) |
| 6 | total_deposits_aud | DOUBLE | YES | Direct passthrough from upstream. Formula: `total_deposits`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (+3 more)) |
| 7 | total_withdrawals_aud | DOUBLE | YES | Direct passthrough from upstream. Formula: `total_withdrawals`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (+3 more)) |
| 8 | net_flow_aud | DOUBLE | YES | Direct passthrough from upstream. Formula: `net_flow`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (+3 more)) |
| 9 | total_deposits_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `total_deposits * COALESCE(aud_to_usd_rate, 0)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (+4 more)) |
| 10 | total_withdrawals_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `total_withdrawals * COALESCE(aud_to_usd_rate, 0)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (+4 more)) |
| 11 | net_flow_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `net_flow * COALESCE(aud_to_usd_rate, 0)`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (+4 more)) |
| 12 | count_deposits | LONG | YES | Aggregate over upstream rows. Formula: `SUM(is_deposit)`. (Tier 2 — literal) |
| 13 | count_withdrawals | LONG | YES | Aggregate over upstream rows. Formula: `SUM(is_withdrawal)`. (Tier 2 — literal) |
| 14 | is_ftd | BOOLEAN | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN _is_orphan_ftd THEN TRUE WHEN date = first_deposit_date AND total_deposits > 0 THEN TRUE ELSE FALSE END AS is_ft…`. (Tier 2 — from `main.spaceship.bronze_spaceship_metabase_super_transactions`, `main.spaceship.bronze_spaceship_metabase_user_beta`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (+3 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.spaceship.bronze_spaceship_metabase_user_beta` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_contact` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_super_transactions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.spaceship_metabase_voyager_user_balances` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.spaceship.bronze_spaceship_metabase_nova_transactions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |

### 5.2 Pipeline ASCII Diagram

```
main.spaceship.bronze_spaceship_metabase_user_beta
main.spaceship.bronze_spaceship_metabase_contact
main.spaceship.bronze_spaceship_metabase_super_transactions
... (5 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_spaceship_mimo   ←── this object
        │
        ▼
main.etoro_kpi.v_spaceship_mimo
main.etoro_kpi_prep_stg.v_ddr_mimo_allplatforms
main.etoro_kpi_prep_stg.v_spaceship_f30dd
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.spaceship.bronze_spaceship_metabase_user_beta` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 7 additional object(s)
- **Wiki coverage**: 2/7 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi.v_spaceship_mimo`
- `main.etoro_kpi_prep_stg.v_ddr_mimo_allplatforms`
- `main.etoro_kpi_prep_stg.v_spaceship_f30dd`

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

*Generated: 2026-05-19 | Concepts: 8 | Formulas: 15 | Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 15/15 | Source: view_definition*
