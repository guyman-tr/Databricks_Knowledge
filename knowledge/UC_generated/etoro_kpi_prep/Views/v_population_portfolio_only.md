---
object_fqn: main.etoro_kpi_prep.v_population_portfolio_only
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_population_portfolio_only
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 21
row_count: null
generated_at: '2026-05-19T12:26:34Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
- main.dwh.dim_position
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
- main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
- main.general.bronze_usabroker_apex_options
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.etoro_kpi_prep.v_population_active_traders
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_portfolio_only.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_portfolio_only.sql
concept_count: 4
formula_count: 21
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 21
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_population_portfolio_only

> View in `main.etoro_kpi_prep`. 4 business concept(s) in §2; 21 of 21 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_portfolio_only` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 4 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:08:03 UTC 2026 |

---

## 1. Business Meaning

`v_population_portfolio_only` is a view in `main.etoro_kpi_prep` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md`. Additional upstreams: 7 object(s), listed in §5 Lineage.

Of its 21 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 21 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsCopyFund` computed flag
**What**: Computed flag on `IsCopyFund` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopyFund`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_portfolio_only.sql` etoro_kpi_prep.sql L18-L18

### 2.2 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_portfolio_only.sql` L24
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.3 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `op.GCID = dc.GCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_portfolio_only.sql` L40
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.4 Filter on scope `holders`: `MirrorTypeID = 4`
**What**: `WHERE` clause at the top of scope `holders` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `MirrorTypeID`
**Rules**:
- `MirrorTypeID = 4`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_portfolio_only.sql` L29

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `dp.InstrumentID = di.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `op.GCID = dc.GCID` | Lookup via alias `dc` |

### 3.4 Gotchas

- Scope `holders` applies `MirrorTypeID = 4` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`) |
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `CID`. (Tier 2 — from `main.dwh.dim_position`) |
| 2 | Portfolio_Only | INT | NO | Literal constant set in this object. Formula: `1`. (Tier 2 — literal) |
| 3 | Portfolio_Only_Manual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 4 | Portfolio_Only_CFD_Manual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) = 0 AND COALESCE(InstrumentTypeID, 0) IN (1, 2, 4) THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 5 | Portfolio_Only_CryptoCFD_Manual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) = 0 AND COALESCE(InstrumentTypeID, 0) IN (10) AND COALESCE(IsSettled, 0) = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 6 | Portfolio_Only_CryptoReal_Manual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) = 0 AND COALESCE(InstrumentTypeID, 0) IN (10) AND COALESCE(IsSettled, 0) = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 7 | Portfolio_Only_StocksCFD_Manual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) = 0 AND COALESCE(InstrumentTypeID, 0) IN (5) AND COALESCE(IsSettled, 0) = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 8 | Portfolio_Only_StocksReal_Manual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) = 0 AND COALESCE(InstrumentTypeID, 0) IN (5) AND COALESCE(IsSettled, 0) = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 9 | Portfolio_Only_ETFCFD_Manual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) = 0 AND COALESCE(InstrumentTypeID, 0) IN (6) AND COALESCE(IsSettled, 0) = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 10 | Portfolio_Only_ETFReal_Manual | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) = 0 AND COALESCE(InstrumentTypeID, 0) IN (6) AND COALESCE(IsSettled, 0) = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 11 | Portfolio_Only_Copy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 12 | Portfolio_Only_CFD_Copy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 AND COALESCE(InstrumentTypeID, 0) IN (1, 2, 4) THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 13 | Portfolio_Only_CryptoCFD_Copy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 AND COALESCE(InstrumentTypeID, 0) IN (10) AND COALESCE(IsSettled, 0) = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 14 | Portfolio_Only_CryptoReal_Copy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 AND COALESCE(InstrumentTypeID, 0) IN (10) AND COALESCE(IsSettled, 0) = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 15 | Portfolio_Only_StocksCFD_Copy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 AND COALESCE(InstrumentTypeID, 0) IN (5) AND COALESCE(IsSettled, 0) = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 16 | Portfolio_Only_StocksReal_Copy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 AND COALESCE(InstrumentTypeID, 0) IN (5) AND COALESCE(IsSettled, 0) = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 17 | Portfolio_Only_ETFCFD_Copy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 AND COALESCE(InstrumentTypeID, 0) IN (6) AND COALESCE(IsSettled, 0) = 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 18 | Portfolio_Only_ETFReal_Copy | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 AND COALESCE(InstrumentTypeID, 0) IN (6) AND COALESCE(IsSettled, 0) = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 19 | Portfolio_Only_CopyFund | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(MirrorID, 0) > 0 AND COALESCE(IsCopyFund, 0) = 1 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |
| 20 | Portfolio_Only_Options | INT | YES | Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN COALESCE(PositionMarketValue, 0) > 0 THEN 1 ELSE 0 END)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+5 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT981_BuyPowerSummary.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN/UNION | `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.etoro_kpi_prep.v_population_active_traders` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_population_active_traders.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
main.dwh.dim_position
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
... (5 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_population_portfolio_only   ←── this object
        │
        ▼
main.etoro_kpi_prep_stg._tmp_cds_portfolio_only
main.etoro_kpi_prep_stg._tmp_cds_segmentation
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md`)
- **JOIN/UNION upstreams**: 7 additional object(s)
- **Wiki coverage**: 6/7 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep_stg._tmp_cds_portfolio_only`
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

*Generated: 2026-05-19 | Concepts: 4 | Formulas: 21 | Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 21/21 | Source: view_definition*
