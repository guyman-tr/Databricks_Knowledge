---
object_fqn: main.etoro_kpi_prep.v_mimo_optionsplatform
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_mimo_optionsplatform
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T12:04:42Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
- main.general.bronze_usabroker_apex_options
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql
concept_count: 11
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

# v_mimo_optionsplatform

> View in `main.etoro_kpi_prep`. 11 business concept(s) in §2; 15 of 15 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_optionsplatform` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 11 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 24 12:49:55 UTC 2026 |

---

## 1. Business Meaning

`v_mimo_optionsplatform` is a view in `main.etoro_kpi_prep` that composes 5 CASE-based classifier flag(s) computed from upstream IDs, 1 JOIN-enriched dimension lookup(s), 5 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 15 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 15 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `FundingTypeID` discriminator: `TerminalID = '     '`, `EnteredBy = '   '`, `EnteredBy = '   '` → set to 2
**What**: Computed flag on `FundingTypeID` set to `2` when the predicates below hold, else `None`.
**Columns Involved**: `FundingTypeID`
**Rules**:
- `TerminalID = '     '`
- `EnteredBy = '   '`
- `EnteredBy = '   '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` etoro_kpi_prep.sql L18-L22
**Source(s)**: `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`

### 2.2 `IsInternalTransfer` discriminator: `TerminalID = '     '` → set to 1 else 0
**What**: Computed flag on `IsInternalTransfer` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsInternalTransfer`
**Rules**:
- `TerminalID = '     '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` etoro_kpi_prep.sql L23-L26
**Source(s)**: `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`

### 2.3 `IsGlobalFTD` computed flag
**What**: Computed flag on `IsGlobalFTD` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsGlobalFTD`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` etoro_kpi_prep.sql L57-L57

### 2.4 `MIMOAction` discriminator: `PayTypeCode = ' '`, `PayTypeCode = ' '` → set to '        '
**What**: Computed flag on `MIMOAction` set to `'        '` when the predicates below hold, else `None`.
**Columns Involved**: `MIMOAction`
**Rules**:
- `PayTypeCode = ' '`
- `PayTypeCode = ' '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` etoro_kpi_prep.sql L149-L152
**Source(s)**: `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`, `main.general.bronze_usabroker_apex_options`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.5 `IsFTD` computed flag
**What**: Computed flag on `IsFTD` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsFTD`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` etoro_kpi_prep.sql L155-L158
**Source(s)**: `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`, `main.general.bronze_usabroker_apex_options`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.6 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `op.GCID = dc.GCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` L30,L167
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.7 Filter on scope `DEPOSIT_UNIQUE_FOR_FTDJOIN`: `PayTypeCode = ' '`; `IsInternalTransfer = 0`
**What**: `WHERE` clause at the top of scope `DEPOSIT_UNIQUE_FOR_FTDJOIN` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `PayTypeCode`, `IsInternalTransfer`
**Rules**:
- `PayTypeCode = ' '`
- `IsInternalTransfer = 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` L49

### 2.8 Filter on scope `GLOBAL_FTD`: `FirstDepositDate >= '          '`; `FTDPlatformID = ' '`
**What**: `WHERE` clause at the top of scope `GLOBAL_FTD` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `FirstDepositDate`, `FTDPlatformID`
**Rules**:
- `FirstDepositDate >= '          '`
- `FTDPlatformID = ' '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` L65

### 2.9 Filter on scope `FINRAONLY_ftd_date`: `PayTypeCode = ' '`; `IsInternalTransfer = 0`; `RegisteredRepCode = '   '`
**What**: `WHERE` clause at the top of scope `FINRAONLY_ftd_date` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `PayTypeCode`, `IsInternalTransfer`, `RegisteredRepCode`
**Rules**:
- `PayTypeCode = ' '`
- `IsInternalTransfer = 0`
- `RegisteredRepCode = '   '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` L77

### 2.10 Filter on scope `FINRAONLY_FTD_records`: `PayTypeCode = ' '`; `IsInternalTransfer = 0`
**What**: `WHERE` clause at the top of scope `FINRAONLY_FTD_records` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `PayTypeCode`, `IsInternalTransfer`
**Rules**:
- `PayTypeCode = ' '`
- `IsInternalTransfer = 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` L94

### 2.11 Filter on scope `FinalFTD`: `rn = 1`
**What**: `WHERE` clause at the top of scope `FinalFTD` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `rn`
**Rules**:
- `rn = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_optionsplatform.sql` L135

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
| Filter on discriminator flags | Use `FundingTypeID = 1`-style filters on the precomputed flag columns (`FundingTypeID`, `IsFTD`, `IsGlobalFTD`, `IsInternalTransfer`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `op.GCID = dc.GCID` | Lookup via alias `dc` |

### 3.4 Gotchas

- Scope `DEPOSIT_UNIQUE_FOR_FTDJOIN` applies `PayTypeCode = ' '`; `IsInternalTransfer = 0` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `GLOBAL_FTD` applies `FirstDepositDate >= '          '`; `FTDPlatformID = ' '` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `FINRAONLY_ftd_date` applies `PayTypeCode = ' '`; `IsInternalTransfer = 0`; `RegisteredRepCode = '   '` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `FINRAONLY_FTD_records` applies `PayTypeCode = ' '`; `IsInternalTransfer = 0` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `FinalFTD` applies `rn = 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | OfficeCode | STRING | YES | Direct passthrough from upstream. Formula: `OfficeCode`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 1 | RegisteredRepCode | STRING | YES | Direct passthrough from upstream. Formula: `RegisteredRepCode`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 2 | AccountNumber | STRING | YES | Direct passthrough from upstream. Formula: `AccountNumber`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 3 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(ProcessDate, 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 4 | Date | DATE | YES | Direct passthrough from upstream. Formula: `ProcessDate`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 5 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 6 | MIMOAction | STRING | YES | `MIMOAction` discriminator: `PayTypeCode = ' '`, `PayTypeCode = ' '` → set to '        '. Formula: `CASE WHEN PayTypeCode = 'C' THEN 'Deposit' WHEN PayTypeCode = 'D' THEN 'Withdraw' END`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`, `main.general.bronze_usabroker_apex_options`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 7 | AmountUSD | DECIMAL | YES | Function call computed in source. Formula: `ABS(CAST(Amount AS DECIMAL(19,4)))`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 8 | FundingTypeID | INT | YES | `FundingTypeID` discriminator: `TerminalID = '     '`, `EnteredBy = '   '`, `EnteredBy = '   '` → set to 2. Formula: `CASE WHEN TerminalID = 'OMJNL' THEN 42 WHEN EnteredBy = 'ACH' THEN 29 WHEN EnteredBy = 'WRD' THEN 2 END`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 9 | IsFTD | INT | NO | `IsFTD` computed flag. Formula: `CASE WHEN TransactionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`, `main.general.bronze_usabroker_apex_options`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 10 | IsInternalTransfer | INT | NO | `IsInternalTransfer` discriminator: `TerminalID = '     '` → set to 1 else 0. Formula: `CASE WHEN TerminalID = 'OMJNL' THEN 1 ELSE 0 END`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 11 | TransactionID | STRING | YES | Direct passthrough from upstream. Formula: `ACATSControlNumber`. (Tier 2 — from `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`) |
| 12 | IsGlobalFTD | INT | NO | `IsGlobalFTD` computed flag. Formula: `CASE WHEN dc_ftd.RealCID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — computed in source) |
| 13 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 14 | IsCreditReportValidCB | INT | YES | Direct passthrough from upstream. Formula: `IsCreditReportValidCB`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT869_CashActivity.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN/UNION | `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
main.general.bronze_usabroker_apex_options
        │
        ▼
main.etoro_kpi_prep.v_mimo_optionsplatform   ←── this object
        │
        ▼
main.etoro_kpi_prep.v_mimo_allplatforms
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep.v_mimo_allplatforms`

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

*Generated: 2026-05-19 | Concepts: 11 | Formulas: 15 | Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 15/15 | Source: view_definition*
