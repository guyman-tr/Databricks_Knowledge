---
object_fqn: main.etoro_kpi.ddr_pnl_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.ddr_pnl_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 19
row_count: null
generated_at: '2026-05-19T15:20:37Z'
upstreams:
- main.bi_output.bi_output_vg_date
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
- main.bi_output.bi_ouput_v_dim_instrumenttype
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_pnl_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_pnl_v.sql
concept_count: 1
formula_count: 19
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 14
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 2
  tier_null_columns: 0
  unverified_columns: 0
---

# ddr_pnl_v

> View in `main.etoro_kpi`. 1 business concept(s) in §2; 17 of 19 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_pnl_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 19 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun May 03 14:11:08 UTC 2026 |

---

## 1. Business Meaning

`ddr_pnl_v` is a view in `main.etoro_kpi` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_vg_date` → this object. Canonical upstream documentation: `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 19 columns: 3 inherit byte-for-byte from upstream wikis (Tier 1), 14 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `ins` → `bi_ouput_v_dim_instrumenttype`
**What**: `JOIN` to dimension `bi_ouput_v_dim_instrumenttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `pnl.InstrumentTypeID = ins.InstrumentTypeID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_pnl_v.sql` L31
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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`bi_ouput_v_dim_instrumenttype`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | `pnl.InstrumentTypeID = ins.InstrumentTypeID` | Lookup via alias `ins` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 1 | Date | TIMESTAMP | YES | Calendar **`date`** for the load: **`@date AS [Date]`** in `SP_DDR_Fact_PnL`. (Tier 2 — SP_DDR_Fact_PnL) |
| 2 | CalendarYearMonth | STRING | YES | Direct passthrough from upstream. Formula: `CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | CalendarQuarter | INT | YES | Direct passthrough from upstream. Formula: `CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | CalendarYear | INT | YES | Direct passthrough from upstream. Formula: `CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 5 | RealCID | STRING | YES | Real-account Customer ID. HASH distribution key. References **`Dim_Customer.RealCID`**. Each customer has one real CID. BI_DB transform: column name **`RealCID`**; TVF source column is **`CID`** (same semantics as **`Dim_Position.CID`**). (Tier 1 — Customer.CustomerStatic) |
| 6 | InstrumentTypeID | INT | YES | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. Join-enriched via **`Dim_Instrument`** in **`SP_DDR_Fact_PnL`**. (Tier 1 — Trade.GetInstrument) |
| 7 | InstrumentType | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentType`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_instrumenttype`) |
| 8 | IsCopy | INT | YES | **`CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END`**. **1** = copy-trade child path (see **`MirrorID`** semantics in `Dim_Position`). (Tier 2 — SP_DDR_Fact_PnL) |
| 9 | IsSettled | INT | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 10 | IsFuture | INT | YES | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. **`ISNULL(frfc.IsFuture,0)`** in SP. (Tier 2 — SP_Dim_Instrument) |
| 11 | IsLeveraged | INT | YES | **`CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END`**. Derived from position **Leverage**: Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 2 — Trade.PositionTbl) |
| 12 | IsBuy | INT | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. DWH note: **`bit`** in **`Dim_Position`**; here **int** from TVF/Synapse path. (Tier 1 — Trade.PositionTbl) |
| 13 | IsCopyFund | INT | YES | Smart Portfolio / Fund position flag from TVF: **`CASE WHEN cpt.PositionID IS NOT NULL THEN 1 ELSE 0 END`** with **`LEFT JOIN BI_DB_CopyFund_Positions`**. **`ISNULL(...,0)`** in SP. (Tier 2 — Function_PnL_Single_Day) |
| 14 | IsSQF | INT | YES | **`IsSQF` (SpotQuotedFuture flag) — 1 = instrument is a SpotQuotedFuture (smaller-contract variant of eToro RealFutures, traded on the CME / Chicago Mercantile Exchange). 0 = not an SQF instrument. Source: **`Function_Instrument_Snapshot_Enriched(@dateInt)`** via membership in **`Trade.InstrumentGroups`** with **`GroupID = 59`**. **`ISNULL(frfc.IsSQF, 0)`** per SP. (Tier 5 — user expert correction; previously mis-described as "Sustainable & Quality-Focused") |
| 15 | UnrealizedPnLChange | DECIMAL | YES | **`SUM(frfc.UnrealizedPnLChange)`** from **`Function_PnL_Single_Day`**, where per-position change comes from **`BI_DB_PositionPnL`** prior vs current snapshot **`CASE`** (`UnrealizedPnLEnd - UnrealizedPnLStart` with NULL guards). (Tier 2 — BI_DB_PositionPnL) |
| 16 | NetProfit | DECIMAL | YES | **`SUM(frfc.NetProfit)`** over the group. Base measure: Realized PnL. 0 when open; set on close. In position currency. (Tier 2 — Trade.PositionTbl) |
| 17 | CountPositions | INT | YES | **`COUNT(frfc.PositionID)`** — count of TVF position rows in each aggregate bucket. (Tier 2 — SP_DDR_Fact_PnL) |
| 18 | UpdateDate | TIMESTAMP | YES | ETL load timestamp: **`GETDATE()`** at SP run. (Tier 2 — SP_DDR_Fact_PnL) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_vg_date` | Primary | `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_PnL.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_ouput_v_dim_instrumenttype.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output.bi_output_vg_date
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
main.bi_output.bi_ouput_v_dim_instrumenttype
        │
        ▼
main.etoro_kpi.ddr_pnl_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=19 runtime=19 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output.bi_output_vg_date` (wiki: `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 19 | Tiers: 3 T1, 14 T2, 0 T3, 0 T4, 2 T5, 0 TN, 0 U | Elements: 19/19 | Source: view_definition*
