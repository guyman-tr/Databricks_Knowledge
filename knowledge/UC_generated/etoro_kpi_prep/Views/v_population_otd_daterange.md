---
object_fqn: main.etoro_kpi_prep.v_population_otd_daterange
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_population_otd_daterange
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 3
row_count: null
generated_at: '2026-05-19T12:26:33Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_otd_daterange.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_otd_daterange.sql
concept_count: 2
formula_count: 3
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 3
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_population_otd_daterange

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 3 of 3 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_otd_daterange` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 3 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:08:01 UTC 2026 |

---

## 1. Business Meaning

`v_population_otd_daterange` is a view in `main.etoro_kpi_prep` that composes 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 3 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 3 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `PREP`: `ActionTypeID = 7`; `ActionTypeID = 44`; `IsFTD = 1`
**What**: `WHERE` clause at the top of scope `PREP` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `ActionTypeID`, `ActionTypeID`, `IsFTD`
**Rules**:
- `ActionTypeID = 7`
- `ActionTypeID = 44`
- `IsFTD = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_otd_daterange.sql` L16

### 2.2 Filter on scope `FilteredRealCID`: `RowNum = 1`; `CountDeposits > 1`
**What**: `WHERE` clause at the top of scope `FilteredRealCID` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `RowNum`, `CountDeposits`
**Rules**:
- `RowNum = 1`
- `CountDeposits > 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_otd_daterange.sql` L35

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

- Scope `PREP` applies `ActionTypeID = 7`; `ActionTypeID = 44`; `IsFTD = 1` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `FilteredRealCID` applies `RowNum = 1`; `CountDeposits > 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `CID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 1 | FromDateID | INT | YES | Aggregate over upstream rows. Formula: `MIN(DateID)`. (Tier 2 — literal) |
| 2 | ToDateID | INT | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN MIN(TotalRows) = 1 THEN CAST(DATE_FORMAT(CURRENT_DATE(), 'yyyyMMdd') AS INT) WHEN MIN(CountDeposits) > 1 THEN MIN(DateID) ELSE COALESCE(MIN(CASE WHEN RowN…`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
        │
        ▼
main.etoro_kpi_prep.v_population_otd_daterange   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=3 runtime=3 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 3 | Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 3/3 | Source: view_definition*
