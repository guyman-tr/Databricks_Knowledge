---
object_fqn: main.etoro_kpi.v_ddr_non_revenue_actions
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.v_ddr_non_revenue_actions
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T15:20:41Z'
upstreams:
- main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_ddr_non_revenue_actions.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_ddr_non_revenue_actions.sql
concept_count: 2
formula_count: 6
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 6
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_ddr_non_revenue_actions

> View in `main.etoro_kpi`. 2 business concept(s) in §2; 6 of 6 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_ddr_non_revenue_actions` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 6 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu May 07 12:15:42 UTC 2026 |

---

## 1. Business Meaning

`v_ddr_non_revenue_actions` is a view in `main.etoro_kpi` that composes 2 CASE-based classifier flag(s) computed from upstream IDs.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` → this object. Canonical upstream documentation: `knowledge/UC_generated/de_output/<Tables|Views>/de_output_etoro_kpi_fact_customeraction_w_metrics.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 6 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 6 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `ActionType` discriminator: `ActionTypeID = 36`, `CompensationReasonID IN (53,54)`, `ActionTypeID = 36` → set to '        '
**What**: Computed flag on `ActionType` set to `'        '` when the predicates below hold, else `None`.
**Columns Involved**: `ActionType`
**Rules**:
- `ActionTypeID = 36`
- `CompensationReasonID IN (53,54)`
- `ActionTypeID = 36`
- `CompensationReasonID = 22`
- `ActionTypeID = 36`
- `CompensationReasonID = 41`
- `ActionTypeID = 36`
- `CompensationReasonID = 50`
- `ActionTypeID = 36`
- `CompensationReasonID = 51`
- `ActionTypeID = 36`
- `CompensationReasonID = 52`
- `ActionTypeID = 36`
- `CompensationReasonID = 134`
- `ActionTypeID = 36`
- `ActionTypeID = 9`
- `ActionTypeID = 32`
- `ActionTypeID IN (1,2,3,39)`
- `ActionTypeID IN (4,5,6,28,40)`
- `ActionTypeID = 15`
- `ActionTypeID = 16`
- `ActionTypeID = 17`
- `ActionTypeID = 18`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_ddr_non_revenue_actions.sql` etoro_kpi.sql L12-L29
**Source(s)**: `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`

### 2.2 `ActionType` discriminator: `ActionTypeID = 36`, `ActionTypeID = 9`, `ActionTypeID = 32` → set to '         '
**What**: Computed flag on `ActionType` set to `'         '` when the predicates below hold, else `None`.
**Columns Involved**: `ActionType`
**Rules**:
- `ActionTypeID = 36`
- `ActionTypeID = 9`
- `ActionTypeID = 32`
- `ActionTypeID IN (1,2,3,39)`
- `ActionTypeID IN (4,5,6,28,40)`
- `ActionTypeID = 15`
- `ActionTypeID = 16`
- `ActionTypeID = 17`
- `ActionTypeID = 18`
- `ActionTypeID IN (1,2,3,4,5,6,9,15,16,17,18,28,32,36,39,40)`
- `ActionTypeID = 14`
- `ActionTypeID = 14`
- `ActionTypeID = 41`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_ddr_non_revenue_actions.sql` etoro_kpi.sql L30-L54
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

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
| Filter on discriminator flags | Use `ActionType = 1`-style filters on the precomputed flag columns (`ActionType`) instead of recomputing the underlying CASE predicates downstream. |

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
| 1 | DateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — from `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`) |
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — from `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`) |
| 2 | ActionType | STRING | YES | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 — via Fact_SnapshotCustomer) |
| 3 | Amount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN ActionTypeID = 36 THEN Amount WHEN ActionTypeID = 9 THEN Amount WHEN ActionTypeID = 32 THEN -1 * Amount WHEN ActionTypeID IN (1,2,3,39) TH…`. (Tier 2 — from `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`) |
| 4 | CountActions | LONG | NO | Aggregate over upstream rows. Formula: `COUNT(*)`. (Tier 2 — literal) |
| 5 | IsCopyFund | INT | YES | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | Primary | `knowledge/UC_generated/de_output/<Tables|Views>/de_output_etoro_kpi_fact_customeraction_w_metrics.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/gold_de_user_dim_ddr_customer_dailystatus_scd.md` |

### 5.2 Pipeline ASCII Diagram

```
main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
... (1 more upstream(s))
        │
        ▼
main.etoro_kpi.v_ddr_non_revenue_actions   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=6 runtime=6 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` (wiki: `knowledge/UC_generated/de_output/<Tables|Views>/de_output_etoro_kpi_fact_customeraction_w_metrics.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 3/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 6 | Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: view_definition*
