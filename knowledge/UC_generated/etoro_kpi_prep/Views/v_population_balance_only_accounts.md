---
object_fqn: main.etoro_kpi_prep.v_population_balance_only_accounts
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_population_balance_only_accounts
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 3
row_count: null
generated_at: '2026-05-19T12:26:31Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance
- main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
- main.general.bronze_usabroker_apex_options
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.etoro_kpi_prep.v_population_active_traders
- main.etoro_kpi_prep.v_population_portfolio_only
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_balance_only_accounts.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_balance_only_accounts.sql
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

# v_population_balance_only_accounts

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 3 of 3 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_balance_only_accounts` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 3 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:05:01 UTC 2026 |

---

## 1. Business Meaning

`v_population_balance_only_accounts` is a view in `main.etoro_kpi_prep` that composes 1 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md`. Additional upstreams: 6 object(s), listed in §5 Lineage.

Of its 3 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 3 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `op.GCID = dc.GCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_balance_only_accounts.sql` L45
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.2 Filter on scope `maxbalance_tp`: `Equity > 0`
**What**: `WHERE` clause at the top of scope `maxbalance_tp` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `Equity`
**Rules**:
- `Equity > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_balance_only_accounts.sql` L24

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `op.GCID = dc.GCID` | Lookup via alias `dc` |

### 3.4 Gotchas

- Scope `maxbalance_tp` applies `Equity > 0` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`) |
| 1 | RealCID | LONG | YES | Direct passthrough from upstream. Formula: `CID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`) |
| 2 | MaxAnyEquity | DECIMAL | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(TPMaxEquity, 0) + COALESCE(eMoneyMaxEquity, 0) + COALESCE(TotalEquity, 0)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance`, `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary` (+2 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoneyClientBalance.md` |
| `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT981_BuyPowerSummary.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN/UNION | `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.etoro_kpi_prep.v_population_active_traders` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_population_active_traders.md` |
| `main.etoro_kpi_prep.v_population_portfolio_only` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_population_portfolio_only.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance
main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
... (4 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_population_balance_only_accounts   ←── this object
        │
        ▼
main.etoro_kpi_prep_stg._tmp_cds_balance_only
main.etoro_kpi_prep_stg._tmp_cds_segmentation
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=3 runtime=3 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md`)
- **JOIN/UNION upstreams**: 6 additional object(s)
- **Wiki coverage**: 6/6 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep_stg._tmp_cds_balance_only`
- `main.etoro_kpi_prep_stg._tmp_cds_segmentation`

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
