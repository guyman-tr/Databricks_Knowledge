---
object_fqn: main.etoro_kpi_prep.v_revenue_optionsplatform
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_optionsplatform
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 26
row_count: null
generated_at: '2026-05-19T12:26:38Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
- main.general.bronze_usabroker_apex_options
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_optionsplatform.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_optionsplatform.sql
concept_count: 6
formula_count: 26
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 26
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_optionsplatform

> View in `main.etoro_kpi_prep`. 6 business concept(s) in §2; 26 of 26 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_optionsplatform` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 26 |
| **Concepts** | 6 (see §2) |
| **Downstream consumers** | 7 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:47 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_optionsplatform` is a view in `main.etoro_kpi_prep` that composes 4 CASE-based classifier flag(s) computed from upstream IDs, 1 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 26 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 26 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `ActionTypeID` discriminator: `Side = ' '`, `Side = ' '` → set to 4
**What**: Computed flag on `ActionTypeID` set to `4` when the predicates below hold, else `None`.
**Columns Involved**: `ActionTypeID`
**Rules**:
- `Side = ' '`
- `Side = ' '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_optionsplatform.sql` etoro_kpi_prep.sql L22-L22
**Source(s)**: `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`

### 2.2 `ActionType` discriminator: `Side = ' '`, `Side = ' '` → set to '                   '
**What**: Computed flag on `ActionType` set to `'                   '` when the predicates below hold, else `None`.
**Columns Involved**: `ActionType`
**Rules**:
- `Side = ' '`
- `Side = ' '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_optionsplatform.sql` etoro_kpi_prep.sql L23-L23
**Source(s)**: `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`

### 2.3 `InstrumentTypeID` discriminator: `InstrumentType = '      '`, `InstrumentType = '      '` → set to 5
**What**: Computed flag on `InstrumentTypeID` set to `5` when the predicates below hold, else `None`.
**Columns Involved**: `InstrumentTypeID`
**Rules**:
- `InstrumentType = '      '`
- `InstrumentType = '      '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_optionsplatform.sql` etoro_kpi_prep.sql L24-L24
**Source(s)**: `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`

### 2.4 `CountAsActiveTrade` discriminator: `Side = ' '` → set to 1 else 0
**What**: Computed flag on `CountAsActiveTrade` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `CountAsActiveTrade`
**Rules**:
- `Side = ' '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_optionsplatform.sql` etoro_kpi_prep.sql L31-L31
**Source(s)**: `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`

### 2.5 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `op.GCID = dc.GCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_optionsplatform.sql` L50
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.6 Filter on scope `FIRSTTRADE`: `RN = 1`
**What**: `WHERE` clause at the top of scope `FIRSTTRADE` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `RN`
**Rules**:
- `RN = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_optionsplatform.sql` L16

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
| Filter on discriminator flags | Use `ActionType = 1`-style filters on the precomputed flag columns (`ActionType`, `ActionTypeID`, `CountAsActiveTrade`, `InstrumentTypeID`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `op.GCID = dc.GCID` | Lookup via alias `dc` |

### 3.4 Gotchas

- Scope `FIRSTTRADE` applies `RN = 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(TradeDate, 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 1 | Date | DATE | YES | Cast of upstream column. Formula: `CAST(TradeDate AS DATE)`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 2 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 3 | ActionTypeID | INT | YES | `ActionTypeID` discriminator: `Side = ' '`, `Side = ' '` → set to 4. Formula: `CASE WHEN Side = 'B' THEN 1 WHEN Side = 'S' THEN 4 END`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 4 | ActionType | STRING | YES | `ActionType` discriminator: `Side = ' '`, `Side = ' '` → set to '                   '. Formula: `CASE WHEN Side = 'B' THEN 'ManualPositionOpen' WHEN Side = 'S' THEN 'ManualPositionClose' END`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 5 | InstrumentTypeID | INT | YES | `InstrumentTypeID` discriminator: `InstrumentType = '      '`, `InstrumentType = '      '` → set to 5. Formula: `CASE WHEN InstrumentType = 'Option' THEN 9 WHEN InstrumentType = 'Equity' THEN 5 END`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 6 | IsSettled | INT | NO | Literal constant set in this object. Formula: `1`. (Tier 2 — literal) |
| 7 | IsCopy | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 8 | Metric | STRING | NO | Literal constant set in this object. Formula: `'Options_PFOF'`. (Tier 2 — literal) |
| 9 | Amount | DECIMAL | YES | Aggregate over upstream rows. Formula: `SUM(ABS(CustomerPFOFPayback))`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 10 | CountTransactions | LONG | NO | Aggregate over upstream rows. Formula: `COUNT(OrderID)`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 11 | IncludedInTotalRevenue | INT | NO | Literal constant set in this object. Formula: `1`. (Tier 2 — literal) |
| 12 | CountAsActiveTrade | INT | NO | `CountAsActiveTrade` discriminator: `Side = ' '` → set to 1 else 0. Formula: `CASE WHEN Side = 'B' THEN 1 ELSE 0 END`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 13 | UpdateDate | TIMESTAMP | NO | Literal constant set in this object. Formula: `CURRENT_TIMESTAMP()`. (Tier 2 — literal) |
| 14 | IsBuy | INT | NO | Literal constant set in this object. Formula: `1`. (Tier 2 — literal) |
| 15 | IsLeveraged | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 16 | IsFuture | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 17 | IsCopyFund | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 18 | IsOpenedFromIBAN | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 19 | IsClosedToIBAN | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 20 | IsRecurring | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 21 | IsAirDrop | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 22 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 23 | IsCreditReportValidCB | INT | YES | Direct passthrough from upstream. Formula: `IsCreditReportValidCB`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 24 | FirstTradeDate | DATE | YES | Cast of upstream column. Formula: `CAST(TradeDate AS DATE)`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |
| 25 | FirstTradeDateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(TradeDate AS DATE), 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1047_RevenueReports.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN/UNION | `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
main.general.bronze_usabroker_apex_options
        │
        ▼
main.etoro_kpi_prep.v_revenue_optionsplatform   ←── this object
        │
        ▼
main.de_output_stg.qa_ddr_fact_revenue_generating_actions
main.etoro_kpi_prep.v_ddr_revenues
main.etoro_kpi_prep.v_population_active_traders
... (4 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=26 runtime=26 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.de_output_stg.qa_ddr_fact_revenue_generating_actions`
- `main.etoro_kpi_prep.v_ddr_revenues`
- `main.etoro_kpi_prep.v_population_active_traders`
- `main.etoro_kpi_prep.v_population_active_traders_lite`
- `main.etoro_kpi_prep.v_population_first_time_funded`
- `main.etoro_kpi_prep_stg._tmp_cds_segmentation`
- `main.etoro_kpi_prep_stg.v_ddr_revenues`

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

*Generated: 2026-05-19 | Concepts: 6 | Formulas: 26 | Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 26/26 | Source: view_definition*
