---
object_fqn: main.etoro_kpi_prep.v_population_active_traders
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_population_active_traders
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T12:26:30Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
- main.etoro_kpi_prep.v_revenue_optionsplatform
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_active_traders.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_active_traders.sql
concept_count: 6
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

# v_population_active_traders

> View in `main.etoro_kpi_prep`. 6 business concept(s) in §2; 15 of 15 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_active_traders` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 6 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:57 UTC 2026 |

---

## 1. Business Meaning

`v_population_active_traders` is a view in `main.etoro_kpi_prep` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 3 JOIN-enriched dimension lookup(s), 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 6 object(s), listed in §5 Lineage.

Of its 15 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 15 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsCopyFund` computed flag
**What**: Computed flag on `IsCopyFund` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopyFund`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_active_traders.sql` etoro_kpi_prep.sql L17-L17

### 2.2 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID         AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_active_traders.sql` L21
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.3 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fca.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_active_traders.sql` L24
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.4 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `frop.RealCID = dc.RealCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_active_traders.sql` L47
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.5 Filter on scope `actionsprep`: `MirrorTypeID = 4`
**What**: `WHERE` clause at the top of scope `actionsprep` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `MirrorTypeID`
**Rules**:
- `MirrorTypeID = 4`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_active_traders.sql` L29

### 2.6 Filter on scope `active_options`: `ActionTypeID = 1`
**What**: `WHERE` clause at the top of scope `active_options` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `ActionTypeID`
**Rules**:
- `ActionTypeID = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_active_traders.sql` L49

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
| Filter on discriminator flags | Use `IsCopyFund = 1`-style filters on the precomputed flag columns (`IsCopyFund`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`, `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID         AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `fca.InstrumentID = di.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `frop.RealCID = dc.RealCID` | Lookup via alias `dc` |

### 3.4 Gotchas

- Scope `actionsprep` applies `MirrorTypeID = 4` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `active_options` applies `ActionTypeID = 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 2 | DateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 3 | ActiveTraded | INT | NO | Literal constant set in this object. Formula: `1`. (Tier 2 — literal) |
| 4 | ActiveTradedManual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 5 | ActiveTradedCFD | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (1, 2, 4) THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 6 | ActiveTradedCryptoCFD | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 7 | ActiveTradedCryptoReal | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 8 | ActiveTradedStocksCFD | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 9 | ActiveTradedStocksReal | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 10 | ActiveTradedETFCFD | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 11 | ActiveTradedETFReal | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 12 | ActiveTradedCopy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID > 0 AND ActionTypeID IN (15, 17) THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 13 | ActiveTradedCopyFund | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID > 0 AND ActionTypeID IN (15, 17) AND IsCopyFund = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |
| 14 | ActiveTradedOptions | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN InstrumentTypeID = 9 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+4 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.etoro_kpi_prep.v_revenue_optionsplatform` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_optionsplatform.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
... (4 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_population_active_traders   ←── this object
        │
        ▼
main.etoro_kpi_prep_stg._tmp_cds_active_traders
main.etoro_kpi_prep_stg._tmp_cds_segmentation
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 6 additional object(s)
- **Wiki coverage**: 6/6 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep_stg._tmp_cds_active_traders`
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

*Generated: 2026-05-19 | Concepts: 6 | Formulas: 15 | Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 15/15 | Source: view_definition*
