---
object_fqn: main.etoro_kpi_prep.mv_revenue_trading
object_type: MATERIALIZED_VIEW
producer_kind: sp_or_sql
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.mv_revenue_trading
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: MATERIALIZED_VIEW
format: null
column_count: 24
row_count: null
generated_at: '2026-05-19T12:26:21Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.etoro_kpi_prep.v_revenue_fullcommission
- main.etoro_kpi_prep.v_revenue_commission
- main.etoro_kpi_prep.v_revenue_ticketfee_fixed
- main.etoro_kpi_prep.v_revenue_ticketfee_bypercent
- main.etoro_kpi_prep.v_revenue_rollover
- main.etoro_kpi_prep.v_revenue_dividend
- main.etoro_kpi_prep.v_revenue_adminfee
- main.etoro_kpi_prep.v_revenue_spotadjustfee
- main.dwh.dim_position
writer:
  kind: sp_or_sql
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/mv_revenue_trading.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/mv_revenue_trading.sql
concept_count: 6
formula_count: 24
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 24
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# mv_revenue_trading

> Table (sp/sql writer) in `main.etoro_kpi_prep`. 6 business concept(s) in §2; 24 of 24 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.mv_revenue_trading` |
| **Type** | MATERIALIZED_VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 24 |
| **Concepts** | 6 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 22 13:35:01 UTC 2026 |

---

## 1. Business Meaning

`mv_revenue_trading` is a table (SP/SQL writer) in `main.etoro_kpi_prep` that composes 4 CASE-based classifier flag(s) computed from upstream IDs, 1 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`. Additional upstreams: 13 object(s), listed in §5 Lineage.

Of its 24 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 24 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsOpenFromIBAN` computed flag
**What**: Computed flag on `IsOpenFromIBAN` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsOpenFromIBAN`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/mv_revenue_trading.sql` etoro_kpi_prep.sql L173-L176
**Source(s)**: `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban`

### 2.2 `IsClosedToIBAN` computed flag
**What**: Computed flag on `IsClosedToIBAN` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsClosedToIBAN`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/mv_revenue_trading.sql` etoro_kpi_prep.sql L177-L180
**Source(s)**: `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban`

### 2.3 `IsCopyFund` discriminator: `MirrorTypeID = 4` (Fund per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsCopyFund` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopyFund`
**Rules**:
- `MirrorTypeID = 4` (Fund per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/mv_revenue_trading.sql` etoro_kpi_prep.sql L181-L184
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`

### 2.4 `IsSQF` computed flag
**What**: Computed flag on `IsSQF` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsSQF`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/mv_revenue_trading.sql` etoro_kpi_prep.sql L190-L193
**Source(s)**: `main.trading.bronze_etoro_trade_instrumentgroups`

### 2.5 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/mv_revenue_trading.sql` L204
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.6 Filter on scope `SQF`: `GroupID = 59`
**What**: `WHERE` clause at the top of scope `SQF` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `GroupID`
**Rules**:
- `GroupID = 59`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/mv_revenue_trading.sql` L165

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | MATERIALIZED_VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Filter on discriminator flags | Use `IsClosedToIBAN = 1`-style filters on the precomputed flag columns (`IsClosedToIBAN`, `IsCopyFund`, `IsOpenFromIBAN`, `IsSQF`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `dp.InstrumentID = di.InstrumentID` | Lookup via alias `di` |

### 3.4 Gotchas

- Scope `SQF` applies `GroupID = 59` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | LONG | YES | Computed in source (transform kind not classified). Formula: `IBANOPEN AS (SELECT DISTINCT TreeID`. (Tier 2 — from `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban`) |
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — computed in source) |
| 2 | DateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — computed in source) |
| 3 | Occurred | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `Occurred`. (Tier 2 — computed in source) |
| 4 | Amount | DECIMAL | YES | Direct passthrough from upstream. Formula: `TotalFullCommission`. (Tier 2 — computed in source) |
| 5 | Metric | STRING | YES | Literal constant set in this object. Formula: `'FullCommission'`. (Tier 2 — literal) |
| 6 | ActionType | STRING | YES | Direct passthrough from upstream. Formula: `ActionType`. (Tier 2 — computed in source) |
| 7 | IncludedInTotalRevenue | INT | YES | Literal constant set in this object. Formula: `1`. (Tier 2 — literal) |
| 8 | IsActiveTrade | INT | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 9 | IsSettled | INT | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 10 | MirrorID | LONG | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 11 | SettlementTypeID | INT | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 12 | IsSettled_Final | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(IsSettled, IsSettled)`. (Tier 2 — from `main.dwh.dim_Position`, `main.etoro_kpi_prep.v_revenue_fullcommission`, `main.etoro_kpi_prep.v_revenue_commission` (+6 more)) |
| 13 | MirrorID_Final | LONG | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(MirrorID, MirrorID)`. (Tier 2 — from `main.dwh.dim_Position`, `main.etoro_kpi_prep.v_revenue_fullcommission`, `main.etoro_kpi_prep.v_revenue_commission` (+6 more)) |
| 14 | SettlementTypeID_Final | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(SettlementTypeID, SettlementTypeID)`. (Tier 2 — from `main.dwh.dim_Position`, `main.etoro_kpi_prep.v_revenue_fullcommission`, `main.etoro_kpi_prep.v_revenue_commission` (+6 more)) |
| 15 | IsOpenFromIBAN | INT | YES | `IsOpenFromIBAN` computed flag. Formula: `CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban`) |
| 16 | IsClosedToIBAN | INT | YES | `IsClosedToIBAN` computed flag. Formula: `CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban`) |
| 17 | IsCopyFund | INT | YES | `IsCopyFund` discriminator: `MirrorTypeID = 4` (Fund per upstream wiki) → set to 1 else 0. Formula: `CASE WHEN MirrorTypeID = 4 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 18 | InstrumentID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentID`. (Tier 2 — from `main.dwh.dim_Position`) |
| 19 | InstrumentTypeID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 20 | InstrumentType | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentType`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 21 | InstrumentName | STRING | YES | Display name computed by Trade.GetInstrument as BuyCurrency Abbreviation + '/' + SellCurrency Abbreviation (e.g., EUR/USD for forex, AAPL/USD for stocks). Not a company name; see InstrumentDisplayName for human-readable labels. |
| 22 | Symbol | STRING | YES | Direct passthrough from upstream. Formula: `Symbol`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 23 | IsSQF | INT | YES | `IsSQF` computed flag. Formula: `CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.trading.bronze_etoro_trade_instrumentgroups`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.etoro_kpi_prep.v_revenue_fullcommission` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_fullcommission.md` |
| `main.etoro_kpi_prep.v_revenue_commission` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_commission.md` |
| `main.etoro_kpi_prep.v_revenue_ticketfee_fixed` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_ticketfee_fixed.md` |
| `main.etoro_kpi_prep.v_revenue_ticketfee_bypercent` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_ticketfee_bypercent.md` |
| `main.etoro_kpi_prep.v_revenue_rollover` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_rollover.md` |
| `main.etoro_kpi_prep.v_revenue_dividend` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_dividend.md` |
| `main.etoro_kpi_prep.v_revenue_adminfee` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_adminfee.md` |
| `main.etoro_kpi_prep.v_revenue_spotadjustfee` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_spotadjustfee.md` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban.md` |
| `main.trading.bronze_etoro_trade_instrumentgroups` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentGroups.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.etoro_kpi_prep.v_revenue_fullcommission
main.etoro_kpi_prep.v_revenue_commission
... (11 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.mv_revenue_trading   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=24 runtime=24 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`)
- **JOIN/UNION upstreams**: 13 additional object(s)
- **Wiki coverage**: 12/13 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 6 | Formulas: 24 | Tiers: 0 T1, 24 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 24/24 | Source: sp_or_sql*
