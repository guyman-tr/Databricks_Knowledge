---
object_fqn: main.etoro_kpi_prep.v_population_first_time_funded
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_population_first_time_funded
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 18
row_count: null
generated_at: '2026-05-19T12:26:32Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.etoro_kpi_prep.v_mimo_allplatforms
- main.etoro_kpi_prep.v_globalftdplatform
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.dim_position
- main.etoro_kpi_prep.v_revenue_optionsplatform
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_time_funded.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_time_funded.sql
concept_count: 3
formula_count: 18
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 18
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_population_first_time_funded

> View in `main.etoro_kpi_prep`. 3 business concept(s) in §2; 18 of 18 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_first_time_funded` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 18 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:07:57 UTC 2026 |

---

## 1. Business Meaning

`v_population_first_time_funded` is a view in `main.etoro_kpi_prep` that composes 3 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 6 object(s), listed in §5 Lineage.

Of its 18 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 18 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `First_IOB`: `ActionTypeID = 36`; `CompensationReasonID = 57`
**What**: `WHERE` clause at the top of scope `First_IOB` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `ActionTypeID`, `CompensationReasonID`
**Rules**:
- `ActionTypeID = 36`
- `CompensationReasonID = 57`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_time_funded.sql` L14

### 2.2 Filter on scope `DWH_FTD`: `IsDepositor = 1`
**What**: `WHERE` clause at the top of scope `DWH_FTD` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `IsDepositor`
**Rules**:
- `IsDepositor = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_time_funded.sql` L47

### 2.3 Filter on scope `Verification`: `VerificationLevelID = 3`
**What**: `WHERE` clause at the top of scope `Verification` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `VerificationLevelID`
**Rules**:
- `VerificationLevelID = 3`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_time_funded.sql` L56

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

- Scope `First_IOB` applies `ActionTypeID = 36`; `CompensationReasonID = 57` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `DWH_FTD` applies `IsDepositor = 1` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `Verification` applies `VerificationLevelID = 3` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `CID`. (Tier 2 — from `main.dwh.dim_position`) |
| 1 | FTDPlatformID | INT | YES | Direct passthrough from upstream. Formula: `FTDPlatformID`. (Tier 2 — from `main.etoro_kpi_prep.v_globalftdplatform`) |
| 2 | FTDPlatform | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.etoro_kpi_prep.v_globalftdplatform`) |
| 3 | FTDDateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(FirstDepositDate, 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 4 | FTDDate | DATE | YES | Cast of upstream column. Formula: `CAST(FirstDepositDate AS DATE)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 5 | FTDTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `FirstDepositDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 6 | FirstTradeDateID | INT | YES | Aggregate over upstream rows. Formula: `MIN(OpenDateID)`. (Tier 2 — from `main.dwh.dim_position`) |
| 7 | FirstTradeDate | DATE | YES | Function call computed in source. Formula: `TO_DATE(CAST(MIN(OpenDateID) AS STRING), 'yyyyMMdd')`. (Tier 2 — from `main.dwh.dim_position`) |
| 8 | FirstTradeTime | TIMESTAMP | YES | Aggregate over upstream rows. Formula: `MIN(OpenOccurred)`. (Tier 2 — from `main.dwh.dim_position`) |
| 9 | FirstIOBDateID | INT | YES | Aggregate over upstream rows. Formula: `MIN(CAST(DATE_FORMAT(CAST(Occurred AS DATE), 'yyyyMMdd') AS INT))`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 10 | FirstIOBDate | DATE | YES | Cast of upstream column. Formula: `CAST(MIN(Occurred) AS DATE)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 11 | FirstIOBTime | TIMESTAMP | YES | Aggregate over upstream rows. Formula: `MIN(Occurred)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 12 | FirstOptionsTradeDateID | INT | YES | Aggregate over upstream rows. Formula: `MIN(FirstTradeDateID)`. (Tier 2 — from `main.etoro_kpi_prep.v_revenue_optionsplatform`) |
| 13 | FirstOptionsTradeDate | DATE | YES | Aggregate over upstream rows. Formula: `MIN(FirstTradeDate)`. (Tier 2 — from `main.etoro_kpi_prep.v_revenue_optionsplatform`) |
| 14 | FirstVerifiedDateID | INT | YES | Aggregate over upstream rows. Formula: `MIN(FromDateID)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 15 | FirstVerifiedDate | DATE | YES | Function call computed in source. Formula: `TO_DATE(CAST(MIN(FromDateID) AS STRING), 'yyyyMMdd')`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 16 | FirstFundedDateID | INT | YES | Computed in source (transform kind not classified). Formula: `)`. (Tier 2 — literal) |
| 17 | FirstFundedDate | DATE | YES | Computed in source (transform kind not classified). Formula: `'yyyyMMdd' )`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.etoro_kpi_prep.v_mimo_allplatforms` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_allplatforms.md` |
| `main.etoro_kpi_prep.v_globalftdplatform` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_globalftdplatform.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.etoro_kpi_prep.v_revenue_optionsplatform` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_optionsplatform.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.etoro_kpi_prep.v_mimo_allplatforms
... (4 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_population_first_time_funded   ←── this object
        │
        ▼
main.etoro_kpi_prep.v_population_funded
main.etoro_kpi_prep_stg._tmp_cds_basic_statuses
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=18 runtime=18 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 6 additional object(s)
- **Wiki coverage**: 5/6 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep.v_population_funded`
- `main.etoro_kpi_prep_stg._tmp_cds_basic_statuses`

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

*Generated: 2026-05-19 | Concepts: 3 | Formulas: 18 | Tiers: 0 T1, 18 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 18/18 | Source: view_definition*
