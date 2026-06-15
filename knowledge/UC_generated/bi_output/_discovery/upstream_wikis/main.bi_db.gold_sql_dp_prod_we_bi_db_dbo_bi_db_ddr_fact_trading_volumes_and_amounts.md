# BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts

> **~804 M-row** DDR fact (`sys.partitions` roll-up **804 221 299** rows · MCP Synapse **2026-05-14**) spanning **`DateID` 2007-08-27 → 2026-04-25**. One row per **calendar `DateID` × `RealCID` × instrument / posture / product-context flag slice** — summarising **persisted notionals** (`VolumeOpen`/`VolumeClose`/`TotalVolume`) and **invested cash legs** (`InitialAmountCents`-driven opens vs **`Amount`** closes) aggregated from **`BI_DB_dbo.Function_Trading_Volume_PositionLevel`**. Loads **daily** via **`BI_DB_dbo.SP_DDR_Fact_Trading_Volumes_And_Amounts`** (**DELETE + INSERT by `DateID`**) with guarded **`BI_DB_VolumeQA`** dump. UC Gold **`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts`** (**Merge**, **1440 min** cadence).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Fact table |
| **Row count / span** | ~804 M rows · `MIN(DateID)=20070827` · `MAX(DateID)=20260425` (Synapse MCP 2026-05-14) |
| **Production source (logical)** | `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Instrument` + BI_DB enrichment TVFs/helpers (see `.lineage.md`) |
| **Refresh** | Daily — `DELETE … WHERE DateID=@dateID` then `INSERT` from `#data` staged `Function_Trading_Volume_PositionLevel(@dateID,@dateID,0)` |
| **Synapse distribution** | `HASH(RealCID)` |
| **Synapse index** | `CLUSTERED COLUMNSTORE` (`ClusteredIndex_2275066b80394ff29122d4e1516d87f1` · MCP catalog) |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` |
| **UC Format** | Delta EXTERNAL (Generic Pipeline classify) |
| **UC partitioned by** | *(Databricks partition columns mirror pipeline defaults — reconcile with UC `SHOW TBLPROPERTIES` when deploying comments)* |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_Trading_Volumes_And_Amounts` is the **DDR “TV&A”** slice for **management / compliance-ready trading volume & invested-flow reporting** aggregated from position-level DDR logic that already aligned with **`Function_Trading_Volume`** semantics but now preserves **grain through `Function_Trading_Volume_PositionLevel`** (authored migration **2026-01-15** per SP changelog) **before** the final `GROUP BY` to customer × segmentation keys.

Every measure on the row is **`SUM`** of TVF outputs for all position open/close micro-rows sharing the **same categorical bucket** (`DateID`, renamed `CID` as `RealCID`, `InstrumentTypeID`, settlement/copy/direction/leverage/instrument-kind flags, copy-fund / recurring / IBAN / airdrop / margin / SQF / C2P markers). Because **open legs and close legs generate separate underlying rows**, a customer opening and closing intra-day contributes **volume to both legs** consistent with **`Function_Trading_Volume`** documentation (`Function_Trading_Volume.md` §1).

**Instrument mix (distribution evidence — MCP `WHERE DateID ≥ 20260101`, TOP instrument types)**:

| InstrumentTypeID | Row groups (approx.) |
|------------------|----------------------|
| 5 | 14 361 924 |
| 2 | 4 565 482 |
| 6 | 4 199 403 |
| 10 | 3 226 669 |
| 4 | 1 813 861 |
| 1 | 691 946 |

SP authorship (**2025-04-20**) post-dates legacy DDR loaders; changelog tracks **`IsSQF`**, **`IsMarginTrade`** (`SettlementTypeID=5` path), **`IsC2P`**, CAST/`ISNULL` hardening, and the **QA table** **`BI_DB_VolumeQA`** (optional object — guarded `IF OBJECT_ID`).

---

## 2. Business Logic

### 2.1 Open vs close volumetrics

**What**: Persisted Synapse **`Volume`** / **`VolumeOnClose`** integers sourced from **`Dim_Position`**, BIGINT-summed.  
**Columns**: `VolumeOpen`, `VolumeClose`, `TotalVolume`.  
**Rules**:

- Opens (`OpenDateID` window inside TVF) populate **`VolumeOpen`** (`ISNULL(CAST(Volume AS BIGINT),0)`); closes populate **`VolumeClose`** (`VolumeOnClose`).  
- Partial-close-child opens zero-out open volume counters per **`Function_Trading_Volume_PositionLevel.md`**.  
- **`TotalVolume`** is TVF **`VolumeOpen+VolumeClose` per union row**, then **`SUM`** in this SP.

### 2.2 Invested amount legs

**What**: Mirrors TVF **`InvestedAmountOpen` / `InvestedAmountClosed`** → **`SUM`**.  
**Columns**: `InvestedAmountOpen`, `InvestedAmountClosed`, `NetInvestedAmount`.  
**Rules**:

- Opens (non-child) **`InitialAmountCents / 100.0`**; closes **`CAST(Amount AS FLOAT)`** · see **`Dim_Position`** (`InitialAmountCents`, `Amount`).  
- **`NetInvestedAmount`** aggregates row-level **`InvestedAmountOpen − InvestedAmountClosed`** sums.

### 2.3 Transaction counters

**What**: Opens vs closes counted per TVF semantics.  
**Columns**: `CountOpenTransactions`, `CountCloseTransactions`, `CountTotalTransactions`.  
**Rules**: Partial-close-child opens suppressed from **open counts** (`Function_Trading_Volume_PositionLevel.md` §4 rows 58–60).

### 2.4 Leverage & margin posture

**What**: Exposure toggles.

**Columns**: `IsLeverage`, `IsMarginTrade`.

**Rules**:

- **`IsLeverage`** = **`CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`** (**SP-level** duplication of grouping CASE). **`Leverage`** semantics: *“Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.”* (`Dim_Position.md` §4 Group E `#30`).  
- **`IsMarginTrade`** derives inside TVF where **`SettlementTypeID = 5` → `MARGIN_TRADE`** (**`Dictionary.SettlementTypes`** excerpt in `Dim_Position.md` § Group L `#115`). **Verbatim grounding**: *Modern settlement classification. Dictionary.SettlementTypes: `0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE.` … (`Tier 1 — Trade.PositionTbl`).* **Applied flag**: **`1`** iff **`SettlementTypeID = 5`**, else **`0`** (TVF `CASE`, grouped here).

### 2.5 Futures vs SpotQuotedFuture (SQF)

**What**: Distinct derivatives flags.

**Columns**: `IsFuture`, `IsSQF`.

**Rules**:

- **`IsFuture`** — join-through from **`Dim_Instrument.IsFuture`**. **Verbatim**: *`1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures.` (`Tier 2 — SP_Dim_Instrument`)* (`Dim_Instrument.md` Elements `#41`).  
- **`IsSQF`** — **not** thematic “ESG”; see §4 verbatim **Tier 5** correction (instrument **SpotQuotedFuture** / **`GroupID=59`** path via **`Function_Instrument_Snapshot_Enriched`**).

### 2.6 Copy → portfolio (C2P)

**What**: Identifies migrated copy positions kept in the customer's own portfolio.

**Column**: `IsC2P`.

**Rules**: TVF **`LEFT JOIN`** / `CASE` on **`BI_DB_dbo.V_C2P_Positions`** (*CASE WHEN join match THEN 1 ELSE 0 END* · `Function_Trading_Volume_PositionLevel.md` row 72).

---

## 3. Query Advisory

### 3.1 Synapse distribution & indexing

HASH on **`RealCID`** → filter **`DateID` + `RealCID`** (and **`InstrumentTypeID`**) before wide joins **to avoid shuffle-heavy scans**. Columnstore benefits from analytic **`SUM`/GROUP aggregates** aligned to partition elimination on **`DateID`**.

### 3.2 Common patterns

| Question | Approach |
|----------|-----------|
| Daily TV&A by stocks vs crypto | `WHERE InstrumentTypeID IN (5,10)` (+ `IsSettled` split) joining `Dim_InstrumentType` labels |
| Copy vs manual footprint | Partition by `IsCopy`, `IsCopyFund`, `IsC2P` (**mutually nuanced** — do not double-label) |
| Margin vs cash leverage | **`IsMarginTrade`** (settlement **`MARGIN_TRADE`**) differs from **`IsLeverage`** (mechanical **`Leverage>1`**) |

### 3.3 Common JOINs

| Join target | Predicate | Purpose |
|-------------|-----------|---------|
| `DWH_dbo.Dim_Customer` | `dc.RealCID = f.RealCID` | Customer demographics / country |
| `DWH_dbo.Dim_Instrument` | `di.InstrumentTypeID = f.InstrumentTypeID` (+ optional instrument drill-down if denormalising) | Type / **`IsFuture`** truth at dim grain |
| `DWH_dbo.Dim_Date` | `dd.DateID = f.DateID` | Calendar attributes |

### 3.4 Gotchas

- **Nullable columns in catalogue** (`IS_NULLABLE = true` everywhere) despite business **0/1** flags — coerce defensively (`ISNULL(flag,0)`) unless profiling proves non-NULL invariant. **`IsAirDrop`** sampled **`NULL`** in MCP TOP 10 (`DateID≥20260101`).  
- **`IsOpenedFromIBAN` is `varchar(100)`** — compare as **`'1'/'0'` strings** (historic DDR pattern).  
- **`IsLeverage`** naming — not **`IsLeveraged`** (other DDR docs).  
- **`IsFuture` vs `IsSQF`** — orthogonal encodings (**`GroupID=25`** futures vs **`GroupID=59`** SQF staging per **`Function_Instrument_Snapshot_Enriched.md`** §4 col 7 commentary).  

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Production-grounded (`Trade.*`, `Customer.*`) — verbatim inherited where available |
| **Tier 2** | TVF / SP / enrichment transforms |
| **Tier 5** | Expert adjudication · disputed heritage |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Event calendar surrogate (`YYYYMMDD`). Determined inside **`Function_Trading_Volume_PositionLevel`** from **`Dim_Position.OpenDateID` / `CloseDateID`** union legs. PARTITION key for nightly reload. (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 2 | Date | date | YES | `CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112)` — derived **DATE** companion to **`DateID`**. (`Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts`) |
| 3 | RealCID | int | YES | Global real-account **`CID`** surfaced as HASH key (`ftv.CID AS RealCID`). **Verbatim parity — `Fact_CustomerAction.md`**: *Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID.* (`Tier 1 — Customer.CustomerStatic`) |
| 4 | InstrumentTypeID | int | YES | **Verbatim parity — `Dim_Instrument.md`**: *From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType.* (`Tier 1 — Trade.GetInstrument`) |
| 5 | IsSettled | int | YES | **Verbatim parity — `Dim_Position.md`**: *1 = real asset, 0 = CFD asset.* (`Tier 5 — Expert Review`) |
| 6 | IsCopy | int | YES | TVF derivation **`CASE WHEN MirrorID > 0 THEN 1 ELSE 0`** on **`Dim_Position.MirrorID`** (`Function_Trading_Volume_PositionLevel.md` §4 `#22`). (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 7 | IsBuy | int | YES | **Verbatim parity — `Dim_Position.md`**: *1 = Long/Buy (profit when price rises), 0 = Short/Sell.* (`Tier 1 — Trade.PositionTbl`) |
| 8 | IsLeverage | int | YES | **`CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`** in **`SP_DDR_Fact_Trading_Volumes_And_Amounts`** (GROUP BY duplication). Leverage originates from **`Dim_Position.Leverage`** (*“(1, 5, 10, …)”* · `Dim_Position.md` `#30`). (`Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts`) |
| 9 | IsFuture | int | YES | **Verbatim grounding — `Dim_Instrument.md`**: *1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures.* (`Tier 2 — SP_Dim_Instrument`) |
| 10 | IsCopyFund | int | YES | **1** when the position `PositionID` appears in `BI_DB_CopyFund_Positions` (Smart Portfolio / copy-fund trees). (`Tier 2 — BI_DB_CopyFund_Positions`) |
| 11 | IsOpenedFromIBAN | varchar(100) | YES | **1/0 varchar** sentinel from **`BI_DB_Positions_Opened_From_IBAN`**. DDL mismatch vs `BIT` semantics — compare as strings. (`Tier 2 — BI_DB_Positions_Opened_From_IBAN`) |
| 12 | IsClosedToIBAN | int | YES | Presence flag from **`BI_DB_Positions_Closed_To_IBAN`**. (`Tier 2 — BI_DB_Positions_Closed_To_IBAN`) |
| 13 | IsRecurring | int | YES | Presence flag from **`BI_DB_RecurringInvestment_Positions`** auto-invest instrumentation. (`Tier 2 — BI_DB_RecurringInvestment_Positions`) |
| 14 | IsAirDrop | int | YES | **Verbatim — `Dim_Position.md` `#107`**: `1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop.` (`Tier 2 — SP_Dim_Position_DL_To_Synapse`) |
| 15 | VolumeOpen | bigint | YES | **`SUM`** of TVF **`VolumeOpen`** (**`CAST(Dim_Position.Volume BIGINT)` on qualifying opens** · `Dim_Position.md` **`Volume`** *ROUND(units × InitForexRate × USD conversion)*). (`Tier 2 — SP_Dim_Position_DL_To_Synapse`) |
| 16 | VolumeClose | bigint | YES | **`SUM`** of TVF **`VolumeClose`** (**`Dim_Position.VolumeOnClose`** *ROUND amount × `EndForexRate`* ). (`Tier 2 — SP_Dim_Position_DL_To_Synapse`) |
| 17 | InvestedAmountOpen | money | YES | **`SUM`** of **`InitialAmountCents/100`** open leg (excluding partial-close children). **`InitialAmountCents`**: *Initial amount in cents… (`Tier 1 — Trade.PositionTbl`).* (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 18 | InvestedAmountClosed | money | YES | **`SUM`** of closed **`CAST(Amount AS FLOAT)`** legs. **`Amount`**: *Position size in currency… (`Tier 1 — Trade.PositionTbl`).* (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 19 | TotalVolume | bigint | YES | **`SUM`** of **`VolumeOpen+VolumeClose`** intra-TVF totals (then aggregated). KPI for combined open+close persisted notionals same day slice. (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 20 | NetInvestedAmount | money | YES | **`SUM`** of **`InvestedAmountOpen − InvestedAmountClosed`** from TVF. (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 21 | CountOpenTransactions | int | YES | **`SUM`** (`CountOpenTransactions`) — excludes partial-close child opens (`Function_Trading_Volume_PositionLevel.md` `#13`). (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 22 | CountCloseTransactions | int | YES | **`SUM`** per-close indicator column inside TVF. (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 23 | CountTotalTransactions | int | YES | **`SUM`** (**open counter + close counter** per underlying row). (`Tier 2 — Function_Trading_Volume_PositionLevel`) |
| 24 | UpdateDate | datetime | YES | ETL watermark **`GETDATE()`** captured at **`SP_DDR_Fact_Trading_Volumes_And_Amounts`** run. (`Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts`) |
| 25 | IsSQF | int | YES | `IsSQF` (SpotQuotedFuture flag) — 1 = instrument is a SpotQuotedFuture (smaller-contract variant of eToro RealFutures, traded on the CME). 0 = not. Source: `Function_Instrument_Snapshot_Enriched(@dateInt)` via membership in `Trade.InstrumentGroups` with `GroupID = 59`. (Tier 5 — user expert correction; previously mis-described as “Sustainable & Quality-Focused”) |
| 26 | IsMarginTrade | int | YES | **Verbatim dictionary anchoring**: *`SettlementTypeID` … `Dictionary.SettlementTypes`: … **`5=MARGIN_TRADE`*** (`Dim_Position.md` `#115` excerpt). **`1`** when **`SettlementTypeID = 5`**, else **`0`** (TVF `CASE`). (`Tier 1 — Trade.PositionTbl`) |
| 27 | IsC2P | int | YES | Copy-to-portfolio migrated position (**1** when TVF **`LEFT JOIN`** to `BI_DB_dbo.V_C2P_Positions` matches **`PositionID`**, else **0**) — customer keeps economics after unlinking copy. (`Tier 2 — BI_DB_dbo.V_C2P_Positions`) |

---

## 5. Lineage

### 5.1 Production sources (rollup)

| Synapse Column | Immediate Source | Ultimate / Transform reference |
|----------------|-----------------|--------------------------------|
| Keys / flags | **`Function_Trading_Volume_PositionLevel`** | **`Dim_Position`**, **`Dim_Instrument`**, BI_DB helper tables (+ **`Function_Instrument_Snapshot_Enriched`**) · see **`BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.lineage.md`** column table |
| Measures | **`SUM` over TVF** | Persisted **`Volume`/`VolumeOnClose`**, **`InitialAmountCents`**, **`Amount`** (`Dim_Position` lineage) |

### 5.2 ETL pipeline diagram

```
DWH staging / EXTERNAL (Bronze Generic Pipeline ─ Trade / History lake feeds)
       │
       ▼
┌─────────────────────────────┐
│ DWH_dbo.Dim_Position        │ ◄─┐ rounding-based Volume / Amount economics
│ DWH_dbo.Dim_Instrument      │ ◄─┤ instrument typing + futures flag
└─────────────────────────────┘   │
               │ UNION open/close position legs
               ▼
   BI_DB_dbo.Function_Trading_Volume_PositionLevel(@dt,@dt,0)
               │
               └── temp `#data` (heap · ROUND_ROBIN)
                       │
                       └── BI_DB_dbo.SP_DDR_Fact_Trading_Volumes_And_Amounts (@date)
                              DELETE slice + INSERT aggregates
                              optional BI_DB_VolumeQA QA dump same DateID

Synapse CLUSTERED COLUMNSTORE fact (HASH RealCID · ~804M rows)
       │
       └── Generic Pipeline Merge (1440 min) → main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
```

---

## 6. Relationships

### 6.1 References to

| Concept | Targets | Notes |
|---------|---------|-------|
| Customer | **`DWH_dbo.Dim_Customer`** (`RealCID`) | Surrogate linkage — **business customer id** (**PII coupling via join**) |
| Instrument typing | **`DWH_dbo.Dim_Instrument` / dictionaries** (`InstrumentTypeID`, `InstrumentType`) | Grain mismatch — fact only stores type id |

### 6.2 Referenced by

MCP **`sys.sql_expression_dependencies`** probe returned **zero** referencing objects (**2026-05-14** catalog scope) — consumers may hide inside dynamic SQL outside catalog.

---

## 7. Sample Queries

### 7.1 Daily equities volume by customer (stocks slice)

```sql
SELECT TOP 50
       DateID,
       RealCID,
       TotalVolume,
       NetInvestedAmount,
       CountTotalTransactions,
       IsCopy,
       IsMarginTrade,
       IsFuture,
       IsSQF,
       IsC2P
FROM   BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts
WHERE  DateID BETWEEN 20260101 AND 20260425
AND    InstrumentTypeID = 5
ORDER BY TotalVolume DESC;
```

### 7.2 Sanity check SQF rarity vs futures

```sql
SELECT SUM(CASE WHEN IsFuture = 1 THEN 1 ELSE 0 END) AS rows_future,
       SUM(CASE WHEN IsSQF  = 1 THEN 1 ELSE 0 END) AS rows_sqf
FROM BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts
WHERE DateID = 20260301;
```

---

## 8. Atlassian knowledge sources

- **Dedicated Confluence page** tying this fact name *(BI_DB_DDR_Fact_Trading_Volumes_And_Amounts / TV&A)* → **none** surfaced via CQL `text ~ "BI_DB_DDR_Fact_Trading_Volumes"` (`0` hits · **2026-05-14**).  
- **Peripheral relevance** *(volume / DDR general)*: e.g. *MIMO Analysis* workspace page ([Finance CY · MCP search hit](https://etoro-jira.atlassian.net/wiki/spaces/FC/pages/12000690235/MIMO+Analysis)).

---

*Generated: 2026-05-14 · Quality (author): **8.2**/10 · Phases: **14**/14 checkpoints recorded (pipeline) · PHASE 16 eval: **7.9**/10 weighted (subagent synthesis — Tier accuracy **8**/10, lineage fidelity **9**/10, upstream glossary **9**/10, sceptic hardness **7**/10, doc hygiene **8**/10)*  

*Tiers: **4 Tier 1**, **21 Tier 2**, **0 Tier 3**, **0 Tier 4**, **2 Tier 5** | **Elements 27 / DDL 27** | Logic depth **9**/10*

*PII stance: **`RealCID` is a customer surrogate** · no direct email/phone/name stored — treat joins to `Dim_Customer` plus external feeds as sensitivity boundary (UC deploy tags **`pii=none`** on scaffolded ALTER aligns with surrogate-only columns).*
