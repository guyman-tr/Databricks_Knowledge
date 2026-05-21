---
object_fqn: main.etoro_kpi_prep.v_revenue_share_lending
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_share_lending
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 9
row_count: null
generated_at: '2026-05-19T12:26:40Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_share_lending.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_share_lending.sql
concept_count: 1
formula_count: 9
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 5
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_share_lending

> View in `main.etoro_kpi_prep`. 1 business concept(s) in §2; 9 of 9 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_share_lending` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 9 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:50 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_share_lending` is a view in `main.etoro_kpi_prep` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 9 columns: 4 inherit byte-for-byte from upstream wikis (Tier 1), 5 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID     AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_share_lending.sql` L20
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID     AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID` | Lookup via alias `dr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 1 | GCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 2 | DateID | INT | YES | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 3 | Occurred | TIMESTAMP | YES | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 4 | ShareLendingFeeEtoroShare | DECIMAL | YES | Position / ledger amount discipline per branch (cash change on opens; fee/deposit sizing on ledger rows — see lineage). Must be ≥0 on trade opens historically. (Tier 1 — Trade.PositionTbl / History.Credit) |
| 5 | ShareLendingFeeUserShare | DECIMAL | YES | Position / ledger amount discipline per branch (cash change on opens; fee/deposit sizing on ledger rows — see lineage). Must be ≥0 on trade opens historically. (Tier 1 — Trade.PositionTbl / History.Credit) |
| 6 | ShareLendingFeeBrokerShare | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `Amount / 0.4 - 2 * Amount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 7 | ShareLendingGrossAmount | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `Amount / 0.4`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 8 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
        │
        ▼
main.etoro_kpi_prep.v_revenue_share_lending   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=9 runtime=9 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 9 | Tiers: 4 T1, 5 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 9/9 | Source: view_definition*
