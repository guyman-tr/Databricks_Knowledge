---
object_fqn: main.etoro_kpi.ddr_trading_volumes_and_amounts_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.ddr_trading_volumes_and_amounts_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 31
row_count: null
generated_at: '2026-05-19T15:20:38Z'
upstreams:
- main.bi_output.bi_output_vg_date
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
- main.bi_output.bi_ouput_v_dim_instrumenttype
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_trading_volumes_and_amounts_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_trading_volumes_and_amounts_v.sql
concept_count: 1
formula_count: 31
tier_breakdown:
  tier1_columns: 25
  tier2_columns: 5
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 1
  tier_null_columns: 0
  unverified_columns: 0
---

# ddr_trading_volumes_and_amounts_v

> View in `main.etoro_kpi`. 1 business concept(s) in §2; 30 of 31 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_trading_volumes_and_amounts_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 31 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu May 07 09:51:24 UTC 2026 |

---

## 1. Business Meaning

`ddr_trading_volumes_and_amounts_v` is a view in `main.etoro_kpi` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_vg_date` → this object. Canonical upstream documentation: `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 31 columns: 25 inherit byte-for-byte from upstream wikis (Tier 1), 5 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `ins` → `bi_ouput_v_dim_instrumenttype`
**What**: `JOIN` to dimension `bi_ouput_v_dim_instrumenttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `tva.InstrumentTypeID = ins.InstrumentTypeID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_trading_volumes_and_amounts_v.sql` L43
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
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | `tva.InstrumentTypeID = ins.InstrumentTypeID` | Lookup via alias `ins` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 1 | Date | TIMESTAMP | YES | `CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112)` — derived **DATE** companion to **`DateID`**. (`Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 2 | CalendarYearMonth | STRING | YES | Direct passthrough from upstream. Formula: `CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | CalendarQuarter | INT | YES | Direct passthrough from upstream. Formula: `CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | CalendarYear | INT | YES | Direct passthrough from upstream. Formula: `CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 5 | RealCID | STRING | YES | Global real-account **`CID`** surfaced as HASH key (`ftv.CID AS RealCID`). **Verbatim parity — `Fact_CustomerAction.md`**: *Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID.* (`Tier 1 — Customer.CustomerStatic`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 6 | InstrumentTypeID | INT | YES | **Verbatim parity — `Dim_Instrument.md`**: *From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType.* (`Tier 1 — Trade.GetInstrument`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 7 | InstrumentType | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentType`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_instrumenttype`) |
| 8 | IsSettled | INT | YES | **Verbatim parity — `Dim_Position.md`**: *1 = real asset, 0 = CFD asset.* (`Tier 5 — Expert Review`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 9 | IsCopy | INT | YES | TVF derivation **`CASE WHEN MirrorID > 0 THEN 1 ELSE 0`** on **`Dim_Position.MirrorID`** (`Function_Trading_Volume_PositionLevel.md` §4 `#22`). (`Tier 2 — Function_Trading_Volume_PositionLevel`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 10 | IsBuy | INT | YES | **Verbatim parity — `Dim_Position.md`**: *1 = Long/Buy (profit when price rises), 0 = Short/Sell.* (`Tier 1 — Trade.PositionTbl`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 11 | IsLeverage | INT | YES | **`CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`** in **`SP_DDR_Fact_Trading_Volumes_And_Amounts`** (GROUP BY duplication). Leverage originates from **`Dim_Position.Leverage`** (*“(1, 5, 10, …)”* · `Dim_Position.md` `#30`). (`Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 12 | IsFuture | INT | YES | **Verbatim grounding — `Dim_Instrument.md`**: *1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures.* (`Tier 2 — SP_Dim_Instrument`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 13 | IsCopyFund | INT | YES | **1** when the position `PositionID` appears in `BI_DB_CopyFund_Positions` (Smart Portfolio / copy-fund trees). (`Tier 2 — BI_DB_CopyFund_Positions`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 14 | IsOpenedFromIBAN | STRING | YES | **1/0 varchar** sentinel from **`BI_DB_Positions_Opened_From_IBAN`**. DDL mismatch vs `BIT` semantics — compare as strings. (`Tier 2 — BI_DB_Positions_Opened_From_IBAN`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 15 | IsClosedToIBAN | INT | YES | Presence flag from **`BI_DB_Positions_Closed_To_IBAN`**. (`Tier 2 — BI_DB_Positions_Closed_To_IBAN`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 16 | IsRecurring | INT | YES | Presence flag from **`BI_DB_RecurringInvestment_Positions`** auto-invest instrumentation. (`Tier 2 — BI_DB_RecurringInvestment_Positions`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 17 | IsAirDrop | INT | YES | **Verbatim — `Dim_Position.md` `#107`**: `1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop.` (`Tier 2 — SP_Dim_Position_DL_To_Synapse`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 18 | VolumeOpen | LONG | YES | **`SUM`** of TVF **`VolumeOpen`** (**`CAST(Dim_Position.Volume BIGINT)` on qualifying opens** · `Dim_Position.md` **`Volume`** *ROUND(units × InitForexRate × USD conversion)*). (`Tier 2 — SP_Dim_Position_DL_To_Synapse`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 19 | VolumeClose | LONG | YES | **`SUM`** of TVF **`VolumeClose`** (**`Dim_Position.VolumeOnClose`** *ROUND amount × `EndForexRate`* ). (`Tier 2 — SP_Dim_Position_DL_To_Synapse`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 20 | InvestedAmountOpen | DECIMAL | YES | **`SUM`** of **`InitialAmountCents/100`** open leg (excluding partial-close children). **`InitialAmountCents`**: *Initial amount in cents… (`Tier 1 — Trade.PositionTbl`).* (`Tier 2 — Function_Trading_Volume_PositionLevel`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 21 | InvestedAmountClosed | DECIMAL | YES | **`SUM`** of closed **`CAST(Amount AS FLOAT)`** legs. **`Amount`**: *Position size in currency… (`Tier 1 — Trade.PositionTbl`).* (`Tier 2 — Function_Trading_Volume_PositionLevel`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 22 | TotalVolume | LONG | YES | **`SUM`** of **`VolumeOpen+VolumeClose`** intra-TVF totals (then aggregated). KPI for combined open+close persisted notionals same day slice. (`Tier 2 — Function_Trading_Volume_PositionLevel`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 23 | NetInvestedAmount | DECIMAL | YES | **`SUM`** of **`InvestedAmountOpen − InvestedAmountClosed`** from TVF. (`Tier 2 — Function_Trading_Volume_PositionLevel`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 24 | CountOpenTransactions | INT | YES | **`SUM`** (`CountOpenTransactions`) — excludes partial-close child opens (`Function_Trading_Volume_PositionLevel.md` `#13`). (`Tier 2 — Function_Trading_Volume_PositionLevel`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 25 | CountCloseTransactions | INT | YES | **`SUM`** per-close indicator column inside TVF. (`Tier 2 — Function_Trading_Volume_PositionLevel`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 26 | CountTotalTransactions | INT | YES | **`SUM`** (**open counter + close counter** per underlying row). (`Tier 2 — Function_Trading_Volume_PositionLevel`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 27 | UpdateDate | TIMESTAMP | YES | ETL watermark **`GETDATE()`** captured at **`SP_DDR_Fact_Trading_Volumes_And_Amounts`** run. (`Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 28 | IsSQF | INT | YES | `IsSQF` (SpotQuotedFuture flag) — 1 = instrument is a SpotQuotedFuture (smaller-contract variant of eToro RealFutures, traded on the CME). 0 = not. Source: `Function_Instrument_Snapshot_Enriched(@dateInt)` via membership in `Trade.InstrumentGroups` with `GroupID = 59`. (Tier 5 — user expert correction; previously mis-described as “Sustainable & Quality-Focused”) |
| 29 | IsMarginTrade | INT | YES | **Verbatim dictionary anchoring**: *`SettlementTypeID` … `Dictionary.SettlementTypes`: … **`5=MARGIN_TRADE`*** (`Dim_Position.md` `#115` excerpt). **`1`** when **`SettlementTypeID = 5`**, else **`0`** (TVF `CASE`). (`Tier 1 — Trade.PositionTbl`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |
| 30 | IsC2P | INT | YES | Copy-to-portfolio migrated position (**1** when TVF **`LEFT JOIN`** to `BI_DB_dbo.V_C2P_Positions` matches **`PositionID`**, else **0**) — customer keeps economics after unlinking copy. (`Tier 2 — BI_DB_dbo.V_C2P_Positions`) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_vg_date` | Primary | `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_ouput_v_dim_instrumenttype.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output.bi_output_vg_date
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
main.bi_output.bi_ouput_v_dim_instrumenttype
        │
        ▼
main.etoro_kpi.ddr_trading_volumes_and_amounts_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=31 runtime=31 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 31 | Tiers: 25 T1, 5 T2, 0 T3, 0 T4, 1 T5, 0 TN, 0 U | Elements: 31/31 | Source: view_definition*
