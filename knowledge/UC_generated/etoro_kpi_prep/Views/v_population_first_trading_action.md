---
object_fqn: main.etoro_kpi_prep.v_population_first_trading_action
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_population_first_trading_action
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 20
row_count: null
generated_at: '2026-05-19T12:26:33Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_trading_action.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_trading_action.sql
concept_count: 5
formula_count: 20
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 20
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_population_first_trading_action

> View in `main.etoro_kpi_prep`. 5 business concept(s) in §2; 20 of 20 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_first_trading_action` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 20 |
| **Concepts** | 5 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:07:58 UTC 2026 |

---

## 1. Business Meaning

`v_population_first_trading_action` is a view in `main.etoro_kpi_prep` that composes 2 CASE-based classifier flag(s) computed from upstream IDs, 3 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 20 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 20 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `FirstActionType` discriminator: `InstrumentTypeID IN (1,2,4)`, `InstrumentTypeID = 10`, `MirrorID > 0` → set to '      ' else '  '
**What**: Computed flag on `FirstActionType` set to `'      '` when the predicates below hold, else `'  '`.
**Columns Involved**: `FirstActionType`
**Rules**:
- `InstrumentTypeID IN (1,2,4)`
- `InstrumentTypeID = 10`
- `MirrorID > 0`
- `IsCopyFund = 0`
- `MirrorID > 0`
- `IsCopyFund = 1`
- `InstrumentTypeID IN (5,6)`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_trading_action.sql` etoro_kpi_prep.sql L13-L20

### 2.2 `IsCopyFund` computed flag
**What**: Computed flag on `IsCopyFund` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopyFund`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_trading_action.sql` etoro_kpi_prep.sql L36-L36
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`

### 2.3 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_trading_action.sql` L40
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.4 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_mirror`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_mirror` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.MirrorID = dm.MirrorID AND dm.MirrorTypeID = 4`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_trading_action.sql` L42
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`

### 2.5 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `a.RealCID = dc.RealCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_population_first_trading_action.sql` L47
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

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
| Filter on discriminator flags | Use `FirstActionType = 1`-style filters on the precomputed flag columns (`FirstActionType`, `IsCopyFund`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_mirror`, `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `dp.InstrumentID = di.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `dp.MirrorID = dm.MirrorID AND dm.MirrorTypeID = 4` | Lookup via alias `dm` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `a.RealCID = dc.RealCID` | Lookup via alias `dc` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 1 | PositionID | LONG | YES | Direct passthrough from upstream. Formula: `PositionID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 2 | InstrumentID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 3 | Instrument | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 4 | InstrumentTypeID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 5 | InstrumentType | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentType`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 6 | IsSettled | INT | YES | Direct passthrough from upstream. Formula: `IsSettled`. (Tier 5 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 7 | MirrorID | INT | YES | Direct passthrough from upstream. Formula: `MirrorID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 8 | Exchange | STRING | YES | Direct passthrough from upstream. Formula: `Exchange`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 9 | ISINCode | STRING | YES | Direct passthrough from upstream. Formula: `ISINCode`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 10 | IsAirDrop | INT | NO | COALESCE / null-replacement of upstream values. Formula: `IFNULL(IsAirDrop, 0)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 11 | RN | INT | NO | Window function over upstream rows. Formula: `ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY DateID, Occurred)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 12 | IsCopyFund | INT | NO | `IsCopyFund` computed flag. Formula: `CASE WHEN IFNULL(MirrorTypeID, 0) = 4 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 13 | FirstTradeDateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 14 | Occurred | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `Occurred`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 15 | IsDepositor | BOOLEAN | YES | Direct passthrough from upstream. Formula: `IsDepositor`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 16 | FirstDepositDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `FirstDepositDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 17 | FirstTradeDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `a.Occurred`. (Tier 2 — computed in source) |
| 18 | FirstDepositDateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(FirstDepositDate AS DATE), 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 19 | FirstActionType | STRING | NO | `FirstActionType` discriminator: `InstrumentTypeID IN (1,2,4)`, `InstrumentTypeID = 10`, `MirrorID > 0` → set to '      ' else '  '. Formula: `CASE WHEN a.InstrumentTypeID IN (1,2,4) THEN 'Forex' WHEN a.InstrumentTypeID = 10 THEN 'Crypto' WHEN a.MirrorID > 0 AND a.IsCopyFund = 0 THEN 'Copy' WHEN a.MirrorID >…`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
... (1 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_population_first_trading_action   ←── this object
        │
        ▼
main.etoro_kpi_prep_stg._tmp_cds_basic_statuses
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=20 runtime=20 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 3/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

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

*Generated: 2026-05-19 | Concepts: 5 | Formulas: 20 | Tiers: 0 T1, 20 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 20/20 | Source: view_definition*
