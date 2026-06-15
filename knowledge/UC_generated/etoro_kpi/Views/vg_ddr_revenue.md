---
object_fqn: main.etoro_kpi.vg_ddr_revenue
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.vg_ddr_revenue
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 30
row_count: null
generated_at: '2026-05-19T15:20:44Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
- main.bi_output.bi_ouput_v_dim_instrumenttype
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
  / main.bi_output.bi_ouput_v_dim_instrumenttype
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_ddr_revenue.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_ddr_revenue.sql
concept_count: 3
formula_count: 30
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 21
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 2
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_ddr_revenue

> View in `main.etoro_kpi`. 3 business concept(s) in §2; 28 of 30 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_ddr_revenue` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 30 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Jan 22 15:39:12 UTC 2026 |

---

## 1. Business Meaning

`vg_ddr_revenue` is a view in `main.etoro_kpi` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Revenue_Generating_Actions.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 30 columns: 7 inherit byte-for-byte from upstream wikis (Tier 1), 21 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsICC` discriminator: `IsFuture = 1`, `InstrumentTypeID IN (1, 2, 4)` (1=Currencies, 2=Commodities, 4=Indices per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsICC` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsICC`
**Rules**:
- `IsFuture = 1`
- `InstrumentTypeID IN (1, 2, 4)` (1=Currencies, 2=Commodities, 4=Indices per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_ddr_revenue.sql` etoro_kpi.sql L37-L40
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `main.bi_output.bi_ouput_v_dim_instrumenttype`

### 2.2 Dim lookup via alias `drm` → `gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dfr.RevenueMetricID = drm.RevenueMetricID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_ddr_revenue.sql` L42
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics`

### 2.3 Dim lookup via alias `vit` → `bi_ouput_v_dim_instrumenttype`
**What**: `JOIN` to dimension `bi_ouput_v_dim_instrumenttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dfr.InstrumentTypeID = vit.InstrumentTypeID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_ddr_revenue.sql` L44
**Source(s)**: `main.bi_output.bi_ouput_v_dim_instrumenttype`

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
| Filter on discriminator flags | Use `IsICC = 1`-style filters on the precomputed flag columns (`IsICC`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics`, `bi_ouput_v_dim_instrumenttype`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` | `dfr.RevenueMetricID = drm.RevenueMetricID` | Lookup via alias `drm` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | `dfr.InstrumentTypeID = vit.InstrumentTypeID` | Lookup via alias `vit` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Business date key (**YYYYMMDD**) driving partition swaps; staking branch shifts Month+1 versus TVF-derived activity date; Options reload obeys TVF-supplied horizon. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 1 | Date | TIMESTAMP | YES | Calendar `DATE` mirrored from `@date` parameter on primary insert, TVF timestamps for Options, or derived calendar date when staking rewinds partitions. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 2 | RealCID | INT | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. **(Tier 1 — Customer.CustomerStatic)** |
| 3 | ActionTypeID | INT | YES | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds. **DDR note:** aggregated revenue streams coerce NULL → `ISNULL(...,-1)` at insert; `-1` marks non-trade metrics. **(Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads)** |
| 4 | ActionType | STRING | YES | Verb text for streams — either `Dim_ActionType.Name` (commissions path) **or** literal identifiers (`Rollover`, `SDRT`, `'Redeem'` for TransferCoin aggregates, staking/options labels). **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 5 | InstrumentTypeID | INT | YES | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. **`ISNULL(...,-1)`** masks NULL account-level feeds. **(Tier 1 — Trade.GetInstrument)** |
| 6 | IsSettled | INT | YES | 1 = real asset, 0 = CFD asset. **DDR note:** `ISNULL(...,-1)` sentinel for streams lacking instruments. **(Tier 5 — Expert Review)** |
| 7 | IsCopy | INT | YES | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END` from revenue TVFs, then `ISNULL(...,-1)`; crypto-to-fiat branch forces `-1` post UPDATE. Indicates copy-trading linkage on applicable metrics. **(Tier 2 — Fact_CustomerAction.MirrorID logic via Function_Revenue_*)** |
| 8 | Metric | STRING | YES | Canonical revenue column label (`FullCommission`, `RollOverFee`, `TransferCoinFee`, `StakingLagOneMonth`, …) — enumerated in **`Dim_Revenue_Metrics.Metric`**. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 9 | Amount | DECIMAL | YES | USD revenue amount aggregated per UNION/GROUP grain — sign reflects economic direction (negative dividend payouts retained). Populated strictly from enumerated TVF monetary columns summarized in **`§2.1`**. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 10 | CountTransactions | INT | YES | `COUNT`/`SUM` amalgamation counting instrumented actions per grain; `ISNULL(...,0)` enforced on insert (`ShareLending`/`Staking` may collapse NULL counts). **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 11 | IncludedInTotalRevenue | INT | YES | True if this metric contributes to the canonical "Total Revenue" rollup; False for raw/pass-through entries (`Commission`, `Dividends`, `SDRT`). Filter on this when computing top-line revenue to avoid double-counting. **`SP_DDR`** post-processing forces `Metric='SDRT'` rows to **`0`** even if dictionary flipped historically. Stored as **`int` mirror** of **`Dim_Revenue_Metrics`** bit semantics. **(Tier 1 — UC sample)** |
| 12 | CountAsActiveTrade | INT | YES | **`CASE WHEN ActionTypeID IN (1,39) AND ISNULL(IsAirDrop,0) = 0 THEN 1 ELSE 0 END`** on commission feeders; flattened to **`0`** elsewhere before insert coercion. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 13 | UpdateDate | TIMESTAMP | YES | ETL stamp `GETDATE()` captured at each INSERT pass (main, options purge, staking window). **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 14 | IsBuy | INT | YES | **`1`** Long **`0`** Short; NULL ⇒ non-trade row sentinel — widened/truncated via `ISNULL(...,-1)` with dividend amount-based overrides (**`Metric='Dividends'`**) and **`CryptoToFiatFee`** sentinel `-1` path. **(Tier 1 — Trade.PositionTbl)** |
| 15 | IsLeveraged | INT | YES | Derived `CASE WHEN Leverage > 1 THEN 1 ELSE 0 END` sourced from BI_DB TVFs feeding position-level revenue; `ISNULL` packaging for lake merges. Admin fee branch aliases `Leverage` as `IsLeverage` inside grouping (typo tolerated). **(Tier 2 — Function_Revenue_FullCommissions / AdminFee lineage)** |
| 16 | IsFuture | INT | YES | Combination of TVF payloads and `Dim_Instrument.IsFuture` for admin/spot adjust branches (with `CryptoToFiatFee` forced `-1`). `ISNULL` packaging standard. **(Tier 2 — Dim_Instrument / Function_Revenue_TVF)** |
| 17 | IsCopyFund | INT | YES | **`CASE WHEN BI_DB_CopyFund_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END`** seeded via sequential updates on commission temps; `ISNULL` packaging. **(Tier 2 — BI_DB_CopyFund_Positions)** |
| 18 | IsOpenedFromIBAN | INT | YES | Indicator set via staged parquet + `Dim_Position`-aligned `UPDATE` overlays for eligible overnight/ticket/dividends positions (`1` once matched else `-1` sentinel via `ISNULL`). **(Tier 2 — External_bi_output_finance_bi_db_positions_opened_from_iban_parquet)** |
| 19 | IsClosedToIBAN | INT | YES | Same IBAN close-table overlay pattern as `IsOpenedFromIBAN`. **(Tier 2 — External_bi_output_finance_bi_db_positions_closed_to_iban_parquet)** |
| 20 | IsRecurring | INT | YES | Recurring investment overlay using `External_bi_db_recurringinvestment_positions_parquet`; `ConversionFee` branch also carries TVF `IsRecurring`. **(Tier 2 — External_bi_db_recurringinvestment_positions_parquet)** |
| 21 | IsAirDrop | INT | YES | Free-share flag sourced from BI_DB TVFs describing AirDrop exclusions for active-trade tallies (`ISNULL` packaging plus metric-specific coercion). **(Tier 2 — Function_Revenue_FullCommissions / Function_Revenue_Commissions)** |
| 22 | IsSQF | INT | YES | **`IsSQF` (SpotQuotedFuture flag) — 1 = instrument is a SpotQuotedFuture (a smaller-contract variant of eToro RealFutures, traded on the CME / Chicago Mercantile Exchange). 0 = not an SQF instrument. Source: `Function_Instrument_Snapshot_Enriched(@dateInt)` via membership in `Trade.InstrumentGroups` with `GroupID = 59`. ISNULL coalesces to -1 for streams where SQF classification doesn't apply (Dividends, SDRT, staking, deposit/withdraw fees). (Tier 5 — user expert correction; previously mis-described as "Sustainable & Quality-Focused")** |
| 23 | RevenueMetricID | INT | YES | Surrogate key. Stable integer 1-18 (with new entries appended). FK target from DDR fact tables when revenue is stored long-form. Seeds via `JOIN Dim_Revenue_Metrics`; staking (`12`) and options (`18`) forcibly seeded in dedicated branches prior to dictionary refresh. **(Tier 1 — UC sample)** |
| 24 | RevenueMetricCategoryID | INT | YES | Category surrogate key 1-5. 1=TradeTransactional, 2=Overnight, 3=MIMO, 4=RevShare, 5=Other — inherited from **`Dim_Revenue_Metrics`** (plus staking/options seeded pairs). **(Tier 1 — UC sample)** |
| 25 | IsMarginTrade | INT | YES | Mirrors TVF-supplied flag with SP-level overrides (`Metric='SDRT'` ⇒ `IsMarginTrade=0`; `Metric='Options_PFOF'` margin adjustments). **(Tier 2 — Function_Revenue_* / SP_DDR_Fact_Revenue_Generating_Actions)** |
| 26 | IsC2P | INT | YES | **`CASE WHEN V_C2P_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END`** on position-backed paths; `ISNULL` packaging for non-position metrics. **(Tier 2 — BI_DB_dbo.V_C2P_Positions)** |
| 27 | RevenueMetricCategory | STRING | YES | Direct passthrough from upstream. Formula: `RevenueMetricCategory`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics`) |
| 28 | InstrumentType | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentType`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_instrumenttype`) |
| 29 | IsICC | INT | NO | `IsICC` discriminator: `IsFuture = 1`, `InstrumentTypeID IN (1, 2, 4)` (1=Currencies, 2=Commodities, 4=Indices per upstream wiki) → set to 1 else 0. Formula: `CASE WHEN IsFuture = 1 OR InstrumentTypeID IN (1, 2, 4) THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `main.bi_output.bi_ouput_v_dim_instrumenttype`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Revenue_Generating_Actions.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\Dim_Revenue_Metrics.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_ouput_v_dim_instrumenttype.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions / main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
main.bi_output.bi_ouput_v_dim_instrumenttype
... (1 more upstream(s))
        │
        ▼
main.etoro_kpi.vg_ddr_revenue   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=30 runtime=30 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Revenue_Generating_Actions.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 2/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 3 | Formulas: 30 | Tiers: 7 T1, 21 T2, 0 T3, 0 T4, 2 T5, 0 TN, 0 U | Elements: 30/30 | Source: view_definition*
