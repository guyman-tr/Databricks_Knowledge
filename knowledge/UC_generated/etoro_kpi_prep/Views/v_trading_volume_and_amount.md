---
object_fqn: main.etoro_kpi_prep.v_trading_volume_and_amount
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_trading_volume_and_amount
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 32
row_count: null
generated_at: '2026-05-19T12:26:42Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.etoro_kpi_prep.v_copyfund_positions
- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.dim_position
- main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
- main.etoro_kpi_prep.v_dim_instrument_enriched
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql
concept_count: 12
formula_count: 32
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 32
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_trading_volume_and_amount

> View in `main.etoro_kpi_prep`. 12 business concept(s) in §2; 32 of 32 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_trading_volume_and_amount` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 32 |
| **Concepts** | 12 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Tue May 05 20:48:51 UTC 2026 |

---

## 1. Business Meaning

`v_trading_volume_and_amount` is a view in `main.etoro_kpi_prep` that composes 8 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s), 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`. Additional upstreams: 8 object(s), listed in §5 Lineage.

Of its 32 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 32 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `CountOpenTransactions` computed flag
**What**: Computed flag on `CountOpenTransactions` set to `0` when the predicates below hold, else `1`.
**Columns Involved**: `CountOpenTransactions`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` etoro_kpi_prep.sql L17-L17
**Source(s)**: `main.dwh.dim_position`

### 2.2 `IsCopy` discriminator: `OpenDateID > 0`, `CloseDateID > 0`, `MirrorID > 0` → set to 1 else 0
**What**: Computed flag on `IsCopy` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopy`
**Rules**:
- `OpenDateID > 0`
- `CloseDateID > 0`
- `MirrorID > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` etoro_kpi_prep.sql L19-L129
**Source(s)**: `main.dwh.dim_position`

### 2.3 `IsMarginTrade` discriminator: `SettlementTypeID = 5` → set to 1 else 0
**What**: Computed flag on `IsMarginTrade` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsMarginTrade`
**Rules**:
- `SettlementTypeID = 5`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` etoro_kpi_prep.sql L130-L130
**Source(s)**: `main.dwh.dim_position`

### 2.4 `IsSQF` computed flag
**What**: Computed flag on `IsSQF` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsSQF`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` etoro_kpi_prep.sql L133-L133
**Source(s)**: `main.etoro_kpi_prep.v_dim_instrument_enriched`

### 2.5 `IsC2P` computed flag
**What**: Computed flag on `IsC2P` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsC2P`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` etoro_kpi_prep.sql L134-L134
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e`

### 2.6 `IsCopyFund` computed flag
**What**: Computed flag on `IsCopyFund` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopyFund`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` etoro_kpi_prep.sql L135-L135
**Source(s)**: `main.etoro_kpi_prep.v_copyfund_positions`

### 2.7 `IsOpenedFromIBAN` computed flag
**What**: Computed flag on `IsOpenedFromIBAN` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsOpenedFromIBAN`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` etoro_kpi_prep.sql L137-L137
**Source(s)**: `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban`

### 2.8 `IsClosedToIBAN` computed flag
**What**: Computed flag on `IsClosedToIBAN` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsClosedToIBAN`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` etoro_kpi_prep.sql L138-L138
**Source(s)**: `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban`

### 2.9 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID     AND v.DateID BETWEEN dr.FromDateID AND dr.ToDateID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` L143
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.10 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `v.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` L146
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.11 Filter on scope `volume_open`: `OpenDateID > 0`
**What**: `WHERE` clause at the top of scope `volume_open` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `OpenDateID`
**Rules**:
- `OpenDateID > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` L39

### 2.12 Filter on scope `volume_close`: `CloseDateID > 0`
**What**: `WHERE` clause at the top of scope `volume_close` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `CloseDateID`
**Rules**:
- `CloseDateID > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_trading_volume_and_amount.sql` L65

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
| Filter on discriminator flags | Use `CountOpenTransactions = 1`-style filters on the precomputed flag columns (`CountOpenTransactions`, `IsC2P`, `IsClosedToIBAN`, `IsCopy`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`, `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID     AND v.DateID BETWEEN dr.FromDateID AND dr.ToDateID` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `v.InstrumentID = di.InstrumentID` | Lookup via alias `di` |

### 3.4 Gotchas

- Scope `volume_open` applies `OpenDateID > 0` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `volume_close` applies `CloseDateID > 0` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Direct passthrough from upstream. Formula: `CID`. (Tier 2 — from `main.dwh.dim_position`) |
| 1 | PositionID | LONG | YES | Direct passthrough from upstream. Formula: `PositionID`. (Tier 2 — from `main.dwh.dim_position`) |
| 2 | InstrumentID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentID`. (Tier 2 — from `main.dwh.dim_position`) |
| 3 | Amount | DECIMAL | YES | Direct passthrough from upstream. Formula: `Amount`. (Tier 2 — from `main.dwh.dim_position`) |
| 4 | Leverage | INT | YES | Direct passthrough from upstream. Formula: `Leverage`. (Tier 2 — from `main.dwh.dim_position`) |
| 5 | DateID | INT | YES | Direct passthrough from upstream. Formula: `OpenDateID`. (Tier 2 — from `main.dwh.dim_position`) |
| 6 | VolumeOpen | LONG | NO | COALESCE / null-replacement of upstream values. Formula: `COALESCE(CAST(Volume AS BIGINT), CAST(0 AS BIGINT))`. (Tier 2 — from `main.dwh.dim_position`) |
| 7 | VolumeClose | LONG | NO | Cast of upstream column. Formula: `CAST(0 AS BIGINT)`. (Tier 2 — computed in source) |
| 8 | InvestedAmountOpen | DOUBLE | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN COALESCE(IsPartialCloseChild, 0) = 1 THEN 0 ELSE CAST(InitialAmountCents / 100.0 AS DOUBLE) END`. (Tier 2 — from `main.dwh.dim_position`) |
| 9 | InvestedAmountClosed | DOUBLE | YES | Cast of upstream column. Formula: `CAST(0.0 AS DOUBLE)`. (Tier 2 — computed in source) |
| 10 | TotalVolume | LONG | NO | Arithmetic combination of upstream columns. Formula: `(COALESCE(VolumeOpen, 0) + COALESCE(VolumeClose, 0))`. (Tier 2 — computed in source) |
| 11 | NetInvestedAmount | DOUBLE | NO | Arithmetic combination of upstream columns. Formula: `(COALESCE(InvestedAmountOpen, 0) - COALESCE(InvestedAmountClosed, 0))`. (Tier 2 — computed in source) |
| 12 | CountOpenTransactions | INT | NO | `CountOpenTransactions` computed flag. Formula: `CASE WHEN COALESCE(IsPartialCloseChild, 0) = 1 THEN 0 ELSE 1 END`. (Tier 2 — from `main.dwh.dim_position`) |
| 13 | CountCloseTransactions | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 14 | CountTotalTransactions | INT | NO | Arithmetic combination of upstream columns. Formula: `(CountOpenTransactions + CountCloseTransactions)`. (Tier 2 — computed in source) |
| 15 | IsSettled | INT | YES | Direct passthrough from upstream. Formula: `IsSettled`. (Tier 5 — from `main.dwh.dim_position`) |
| 16 | IsAirDrop | INT | YES | Direct passthrough from upstream. Formula: `IsAirDrop`. (Tier 2 — from `main.dwh.dim_position`) |
| 17 | IsBuy | INT | NO | Cast of upstream column. Formula: `CAST(COALESCE(IsBuy, false) AS INT)`. (Tier 2 — from `main.dwh.dim_position`) |
| 18 | SettlementTypeID | INT | YES | Direct passthrough from upstream. Formula: `SettlementTypeID`. (Tier 2 — from `main.dwh.dim_position`) |
| 19 | ComputedVolumeOpen | DOUBLE | YES | Direct passthrough from upstream. Formula: `END`. (Tier 2 — computed in source) |
| 20 | ComputedVolumeClose | DOUBLE | YES | Cast of upstream column. Formula: `CAST(0.0 AS DOUBLE)`. (Tier 2 — computed in source) |
| 21 | IsCopy | INT | NO | `IsCopy` discriminator: `OpenDateID > 0`, `CloseDateID > 0`, `MirrorID > 0` → set to 1 else 0. Formula: `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.dim_position`) |
| 22 | IsMarginTrade | INT | NO | `IsMarginTrade` discriminator: `SettlementTypeID = 5` → set to 1 else 0. Formula: `CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.dim_position`) |
| 23 | InstrumentTypeID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 24 | IsFuture | INT | YES | Direct passthrough from upstream. Formula: `IsFuture`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 25 | IsSQF | INT | NO | `IsSQF` computed flag. Formula: `CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.etoro_kpi_prep.v_dim_instrument_enriched`) |
| 26 | IsC2P | INT | NO | `IsC2P` computed flag. Formula: `CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e`) |
| 27 | IsCopyFund | INT | NO | `IsCopyFund` computed flag. Formula: `CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.etoro_kpi_prep.v_copyfund_positions`) |
| 28 | IsRecurring | INT | NO | Cast of upstream column. Formula: `CAST(0 AS INT)`. (Tier 2 — computed in source) |
| 29 | IsOpenedFromIBAN | INT | NO | `IsOpenedFromIBAN` computed flag. Formula: `CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban`) |
| 30 | IsClosedToIBAN | INT | NO | `IsClosedToIBAN` computed flag. Formula: `CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban`) |
| 31 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.etoro_kpi_prep.v_copyfund_positions` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_copyfund_positions.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Positions_Opened_From_IBAN.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Positions_Closed_To_IBAN.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e` | JOIN/UNION | `knowledge\synapse\Wiki\EXW_dbo\Tables\EXW_C2P_E2E.md` |
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_dim_instrument_enriched.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.etoro_kpi_prep.v_copyfund_positions
main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
... (6 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_trading_volume_and_amount   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=32 runtime=32 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`)
- **JOIN/UNION upstreams**: 8 additional object(s)
- **Wiki coverage**: 7/8 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 12 | Formulas: 32 | Tiers: 0 T1, 32 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 32/32 | Source: view_definition*
