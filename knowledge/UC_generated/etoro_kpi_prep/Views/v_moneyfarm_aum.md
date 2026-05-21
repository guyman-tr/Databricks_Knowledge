---
object_fqn: main.etoro_kpi_prep.v_moneyfarm_aum
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_moneyfarm_aum
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:26:27Z'
upstreams:
- main.money_farm.silver_moneyfarm_etoro_mf_aum
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_moneyfarm_aum.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_moneyfarm_aum.sql
concept_count: 1
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

# v_moneyfarm_aum

> View in `main.etoro_kpi_prep`. 1 business concept(s) in §2; 7 of 7 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_moneyfarm_aum` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 7 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 23 10:24:11 UTC 2026 |

---

## 1. Business Meaning

`v_moneyfarm_aum` is a view in `main.etoro_kpi_prep` that composes 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.money_farm.silver_moneyfarm_etoro_mf_aum` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 7 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 7 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `gbp_usd_rates`: `InstrumentID = 2`
**What**: `WHERE` clause at the top of scope `gbp_usd_rates` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `InstrumentID`
**Rules**:
- `InstrumentID = 2`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_moneyfarm_aum.sql` L23

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

- Scope `gbp_usd_rates` applies `InstrumentID = 2` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | DATE | YES | Direct passthrough from upstream. Formula: `etr_ymd`. (Tier 2 — from `main.money_farm.silver_moneyfarm_etoro_mf_aum`) |
| 1 | dateid | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(date, 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.money_farm.silver_moneyfarm_etoro_mf_aum`) |
| 2 | gcid | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.money_farm.silver_moneyfarm_etoro_mf_aum`) |
| 3 | total_balance_gbp | DOUBLE | YES | Aggregate over upstream rows. Formula: `SUM(market_value)`. (Tier 2 — literal) |
| 4 | total_balance_usd | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `total_balance_gbp * COALESCE(gbp_to_usd_rate, 0)`. (Tier 2 — from `main.money_farm.silver_moneyfarm_etoro_mf_aum`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |
| 5 | is_funded | BOOLEAN | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN total_balance_gbp > 0 THEN TRUE ELSE FALSE END`. (Tier 2 — from `main.money_farm.silver_moneyfarm_etoro_mf_aum`) |
| 6 | portfolio_count | LONG | NO | Aggregate over upstream rows. Formula: `COUNT(DISTINCT PortfolioID)`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.money_farm.silver_moneyfarm_etoro_mf_aum` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |

### 5.2 Pipeline ASCII Diagram

```
main.money_farm.silver_moneyfarm_etoro_mf_aum
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
        │
        ▼
main.etoro_kpi_prep.v_moneyfarm_aum   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=7 runtime=7 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.money_farm.silver_moneyfarm_etoro_mf_aum` (wiki: `(no wiki)`)
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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 7 | Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: view_definition*
