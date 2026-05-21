---
object_fqn: main.etoro_kpi.positions_for_compliance_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.positions_for_compliance_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 53
row_count: null
generated_at: '2026-05-19T15:20:41Z'
upstreams:
- main.dwh.dim_position
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/positions_for_compliance_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/positions_for_compliance_v.sql
concept_count: 3
formula_count: 53
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 53
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# positions_for_compliance_v

> View in `main.etoro_kpi`. 3 business concept(s) in §2; 53 of 53 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.positions_for_compliance_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 53 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 08 07:28:33 UTC 2026 |

---

## 1. Business Meaning

`positions_for_compliance_v` is a view in `main.etoro_kpi` that composes 2 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.dim_position` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 53 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 53 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.instrumentid = di.instrumentid`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/positions_for_compliance_v.sql` L62
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.2 Dim lookup via alias `dcpr` → `gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.closepositionreasonid = dcpr.closepositionreasonid`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/positions_for_compliance_v.sql` L64
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason`

### 2.3 Lifecycle pair (open → close)
**What**: Column-name pattern group (Init*/End*): these columns work together as a unit. Treat them together when filtering or aggregating.
**Columns Involved**: `inithedgetype`, `endhedgetype`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/positions_for_compliance_v.sql` uc_inventory.json

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `dp.instrumentid = di.instrumentid` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason` | `dp.closepositionreasonid = dcpr.closepositionreasonid` | Lookup via alias `dcpr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | positionid | LONG | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: etoro_kpi.positions_for_compliance_v -- Captured: 2026…`. (Tier 2 — computed in source) |
| 1 | cid | INT | YES | Direct passthrough from upstream. Formula: `cid`. (Tier 2 — from `main.dwh.dim_position`) |
| 2 | instrumentid | INT | YES | Direct passthrough from upstream. Formula: `instrumentid`. (Tier 2 — from `main.dwh.dim_position`) |
| 3 | amount | DECIMAL | YES | Direct passthrough from upstream. Formula: `amount`. (Tier 2 — from `main.dwh.dim_position`) |
| 4 | InitialAmount | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `initialamountcents / 100`. (Tier 2 — from `main.dwh.dim_position`) |
| 5 | hedgeserverid | INT | YES | Direct passthrough from upstream. Formula: `hedgeserverid`. (Tier 2 — from `main.dwh.dim_position`) |
| 6 | leverage | INT | YES | Direct passthrough from upstream. Formula: `leverage`. (Tier 2 — from `main.dwh.dim_position`) |
| 7 | isbuy | BOOLEAN | YES | Direct passthrough from upstream. Formula: `isbuy`. (Tier 2 — from `main.dwh.dim_position`) |
| 8 | openoccurred | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `openoccurred`. (Tier 2 — from `main.dwh.dim_position`) |
| 9 | closeoccurred | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `closeoccurred`. (Tier 2 — from `main.dwh.dim_position`) |
| 10 | parentpositionid | LONG | YES | Direct passthrough from upstream. Formula: `parentpositionid`. (Tier 2 — from `main.dwh.dim_position`) |
| 11 | origparentpositionid | LONG | YES | Direct passthrough from upstream. Formula: `origparentpositionid`. (Tier 2 — from `main.dwh.dim_position`) |
| 12 | mirrorid | INT | YES | Direct passthrough from upstream. Formula: `mirrorid`. (Tier 2 — from `main.dwh.dim_position`) |
| 13 | isopenopen | BOOLEAN | YES | Direct passthrough from upstream. Formula: `isopenopen`. (Tier 2 — from `main.dwh.dim_position`) |
| 14 | opendateid | INT | YES | Direct passthrough from upstream. Formula: `opendateid`. (Tier 2 — from `main.dwh.dim_position`) |
| 15 | closedateid | INT | YES | Direct passthrough from upstream. Formula: `closedateid`. (Tier 2 — from `main.dwh.dim_position`) |
| 16 | volume | INT | YES | Direct passthrough from upstream. Formula: `volume`. (Tier 2 — from `main.dwh.dim_position`) |
| 17 | regulationidonopen | INT | YES | Direct passthrough from upstream. Formula: `regulationidonopen`. (Tier 2 — from `main.dwh.dim_position`) |
| 18 | treeid | LONG | YES | SL/TP/TSL settings for the position; also used as linkage key in Trade.PositionTreeInfo hierarchy (Tier 1 - Trade.PositionTbl wiki) |
| 19 | initialunits | DECIMAL | YES | Direct passthrough from upstream. Formula: `initialunits`. (Tier 2 — from `main.dwh.dim_position`) |
| 20 | Units | DECIMAL | YES | Direct passthrough from upstream. Formula: `amountinunitsdecimal`. (Tier 2 — from `main.dwh.dim_position`) |
| 21 | isdiscounted | INT | YES | Direct passthrough from upstream. Formula: `isdiscounted`. (Tier 2 — from `main.dwh.dim_position`) |
| 22 | issettled | INT | YES | Direct passthrough from upstream. Formula: `issettled`. (Tier 2 — from `main.dwh.dim_position`) |
| 23 | issettledonopen | INT | YES | Direct passthrough from upstream. Formula: `issettledonopen`. (Tier 2 — from `main.dwh.dim_position`) |
| 24 | volumeonclose | INT | YES | Direct passthrough from upstream. Formula: `volumeonclose`. (Tier 2 — from `main.dwh.dim_position`) |
| 25 | isairdrop | INT | YES | Direct passthrough from upstream. Formula: `isairdrop`. (Tier 2 — from `main.dwh.dim_position`) |
| 26 | inithedgetype | STRING | YES | Lifecycle pair (open → close). Formula: `inithedgetype`. (Tier 2 — from `main.dwh.dim_position`) |
| 27 | endhedgetype | STRING | YES | Lifecycle pair (open → close). Formula: `endhedgetype`. (Tier 2 — from `main.dwh.dim_position`) |
| 28 | orderid | INT | YES | Direct passthrough from upstream. Formula: `orderid`. (Tier 2 — from `main.dwh.dim_position`) |
| 29 | closepositionreasonid | INT | YES | Direct passthrough from upstream. Formula: `closepositionreasonid`. (Tier 2 — from `main.dwh.dim_position`) |
| 30 | instrumenttypeid | INT | YES | Direct passthrough from upstream. Formula: `instrumenttypeid`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 31 | instrumenttype | STRING | YES | Direct passthrough from upstream. Formula: `instrumenttype`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 32 | Instrument | STRING | YES | Display name computed by Trade.GetInstrument as BuyCurrency Abbreviation + '/' + SellCurrency Abbreviation (e.g., EUR/USD for forex, AAPL/USD for stocks). Not a company name; see InstrumentDisplayName for human-readable labels. |
| 33 | buycurrencyid | INT | YES | Buy-side currency abbreviation. For forex: base currency code; for stocks: the asset code (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument (Tier 1 - Trade.GetInstrument) |
| 34 | sellcurrencyid | INT | YES | Direct passthrough from upstream. Formula: `sellcurrencyid`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 35 | buycurrency | STRING | YES | Direct passthrough from upstream. Formula: `buycurrency`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 36 | sellcurrency | STRING | YES | Direct passthrough from upstream. Formula: `sellcurrency`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 37 | ismajor | STRING | YES | Direct passthrough from upstream. Formula: `ismajor`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 38 | instrumentdisplayname | STRING | YES | Direct passthrough from upstream. Formula: `instrumentdisplayname`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 39 | industry | STRING | YES | Direct passthrough from upstream. Formula: `industry`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 40 | exchange | STRING | YES | Direct passthrough from upstream. Formula: `exchange`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 41 | isincode | STRING | YES | Direct passthrough from upstream. Formula: `isincode`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 42 | isincountrycode | STRING | YES | Direct passthrough from upstream. Formula: `isincountrycode`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 43 | tradable | INT | YES | Direct passthrough from upstream. Formula: `tradable`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 44 | symbol | STRING | YES | Direct passthrough from upstream. Formula: `symbol`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 45 | symbolfull | STRING | YES | Direct passthrough from upstream. Formula: `symbolfull`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 46 | cusip | STRING | YES | CUSIP code sourced from Trade.InstrumentCusip (not InstrumentMetaData). Committee on Uniform Securities Identification Procedures identifier for US/Canada securities. NULL for forex, crypto, and many non-US instruments. |
| 47 | isfuture | INT | YES | Direct passthrough from upstream. Formula: `isfuture`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 48 | ClosePositionReason | STRING | YES | Direct passthrough from upstream. Formula: `NAME`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason`) |
| 49 | ispartialclosechild | INT | YES | Direct passthrough from upstream. Formula: `ispartialclosechild`. (Tier 2 — from `main.dwh.dim_position`) |
| 50 | ispartialcloseparent | INT | YES | Direct passthrough from upstream. Formula: `ispartialcloseparent`. (Tier 2 — from `main.dwh.dim_position`) |
| 51 | netprofit | DECIMAL | YES | Direct passthrough from upstream. Formula: `netprofit`. (Tier 2 — from `main.dwh.dim_position`) |
| 52 | pnlindollars | DECIMAL | YES | Direct passthrough from upstream. Formula: `pnlindollars`. (Tier 2 — from `main.dwh.dim_position`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.dim_position` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ClosePositionReason.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.dim_position
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason
... (1 more upstream(s))
        │
        ▼
main.etoro_kpi.positions_for_compliance_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=53 runtime=53 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.dim_position` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 3/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 3 | Formulas: 53 | Tiers: 0 T1, 53 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 53/53 | Source: view_definition*
