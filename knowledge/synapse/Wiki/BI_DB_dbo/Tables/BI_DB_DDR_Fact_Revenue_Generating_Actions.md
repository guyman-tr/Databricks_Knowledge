# BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions

> Unified DDR revenue fact (~**3.16B** logical rows via `SUM(sys.partitions.rows)`), **HASH(`RealCID`)** columnstore; history **DateID 20100103–20260425** (Synapse MCP). Daily `DELETE`/reload by `DateID` plus exceptional **full Options** reshuffle (`DELETE WHERE RevenueMetricID=18`), **Staking monthly slice rewinds** tied to staking source replays (`RevenueMetricID=12`). Each row rolls up revenue into stream label **`Metric`** (commissions vs overnight vs MIMO vs rev-share vs specials) keyed by segmented trade flags analysts use inside Genie. Unity Catalog mirror: **`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`**.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | DDR fact (granular revenue actions) |
| **Production Source** | Multi-branch — `BI_DB_dbo.Function_Revenue_*` TVF family over `Fact_CustomerAction`/positions + parquet overlays orchestrated entirely inside Synapse (no single external table lineage) |
| **Refresh** | Daily — partition wipe `DELETE … WHERE DateID=@dateID` + `INSERT` from `SP_DDR_Fact_Revenue_Generating_Actions @date`; options second pass reloads metric id **18**; staking deletes current calendar month slice before insert |
| | |
| **Synapse Distribution** | `HASH (RealCID)` |
| **Synapse Index** | `CLUSTERED COLUMNSTORE INDEX` |
| | |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` |
| **UC Format** | delta (`DESCRIBE` confirmed 2026-05-14) |
| **UC Partitioned By** | Align to Generic Pipeline Override metadata (typically `etr_*` surrogates — validate before wide scans in Databricks SQL) |
| **UC Masked / PII** | **`main.pii_data`:** no sibling `*_revenue_generating_actions` table surfaced via `SHOW TABLES … LIKE '%revenue_generating%'` (Databricks MCP 2026-05-14). Column comments/tagging on gold table still mark key attributes `pii='none'` in deployed UC metadata. |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_Revenue_Generating_Actions` (**RGA**) is eToro’s **long-format revenue bridge** tying every surfaced fee/revenue mechanic to analytic slices (instrument type, copy vs manual, CFD vs settled asset, SQF posture, recurring/IBAN/C2P flags, etc.). The SP fans in **sixteen BI_DB TVFs**, stages multi-step temp merges (`#rollovers … #staking`, `#optionsalltime`), enriches with **Smart Portfolio**, **copy-to-portfolio**, and **finance parquet** lookups, aligns dictionary ids through `Dim_Revenue_Metrics`, and finally merges into the physical table alongside **monthly staking repairs** plus **historic options reload**.

Row grain is logically **daily customer revenue slices**: `SUM` aggregates collapse raw position hits into stable keys so analyst queries can pivot on `Metric` while still retaining `ActionTypeID` fidelity for genuine trade actions (`ManualPositionOpen`, `ManualPositionClose`, etc.). Rows with `Metric IN ('Commission','Dividends','SDRT')` remain **financially tracked** yet **normally excluded from top-line totals** (`IncludedInTotalRevenue` follows `Dim_Revenue_Metrics` but SDRT additionally coerced inside the SP).

**`IsRedeem` does not ship as its own column** in this layout: transfercoin analytics still depend on **`Function_Revenue_TransferCoinFee`**, whose TVF predicates (`ActionTypeID = 30` AND `IsRedeem = 1`) are spelled out upstream on `Fact_CustomerAction` (`see §2.3`).

---

## 2. Business Logic

### 2.1 Metric → TVF lineage (principal columns)

**What**: Each **`Metric`** value maps to explicit TVF payloads feeding `Amount`.

| Metric | Amount column source (TVF) | SP predicate highlights |
|--------|---------------------------|-------------------------|
| `FullCommission` | `SUM(TotalFullCommission)` from `#fullcommissions` (`Function_Revenue_FullCommissions`) | Requires `JOIN DWH_dbo.Dim_ActionType`; `CASE WHEN ActionTypeID IN (1,39) AND ISNULL(IsAirDrop,0)=0 THEN 1 ELSE 0 END` for `CountAsActiveTrade`; `IncludedInTotalRevenue=1` baseline |
| `Commission` | `SUM(TotalCommission)` from `#commissions` (`Function_Revenue_Commissions`) | Mirrors FullCommission branching but flagged out of totals (`IncludedInTotalRevenue=0` before dim join); **never sum simultaneously with FullCommission** (see `Dim_Revenue_Metrics §1`) |
| `RollOverFee` | `#overnights` (`Function_Revenue_RolloverFee` rows aggregated) | Overnight branch exposes `WHERE frrf.Metric = 'Rollover'`; `Amount` summed from prior temp |
| `Dividends` | `Function_Revenue_Dividend` (`Dividend` column aggregated) | `Function_Instrument_Snapshot_Enriched(@dateID)` supplies `IsSQF` enrichment on dividends; aggregates later null `IsSQF` inside `#overnights` union |
| `SDRT` | `Function_Revenue_SDRT` | Hard-coded zero `IsFuture`, `IncludedInTotalRevenue` collapsed to zero via post `UPDATE`; `Metric='SDRT'` resets `IsMarginTrade` sentinel where relevant |
| `TicketFee`, `TicketFeeByPercent` | `Function_Revenue_TicketFee`, `Function_Revenue_TicketFeeByPercent` | Feed overnight temp then second-stage filters `WHERE Metric IN (...)`
| `CashoutFeeExclRedeem` | `CashoutFeeExcludeRedeem` from `Function_Revenue_CashoutFee_ExcludeRedeem` | CID-only grain; literals null-out instrument columns |
| `ConversionFee` | `ConversionFee` from `Function_Revenue_ConversionFee` | Keeps textual `TransactionType` as `ActionType`; merges recurring flag |
| `DormantFee` | `DormantFee` from `Function_Revenue_DormantFee` | Forces `IsAirDrop=0` sentinel |
| `InterestFee` | `InterestFee` from `Function_Revenue_InterestFee` | Wrapped with `WHERE InterestFee IS NOT NULL` inside TVF call |
| `TransferCoinFee` | `TransferCoinFee` aggregated from `Function_Revenue_TransferCoinFee` | TVF restricts `Fact_CustomerAction.ActionTypeID=30 AND IsRedeem=1`; table stores only aggregated revenue without separate `IsRedeem` projection |
| `AdminFee`, `SpotPriceAdjustment` | `AdminFee`, `SpotAdjustFee` from `Function_Revenue_AdminFee`/`Function_Revenue_SpotAdjustFee` | `JOIN Dim_Instrument` to align `IsFuture` |
| `ShareLending` | `ROUND(ShareLendingGrossAmount,6)` aggregates from `Function_Revenue_Share_Lending` | Fixed instrument attributes (`InstrumentTypeID=5`, settled, non-copy) inside SP union |
| `CryptoToFiatFee` | `TotalFeeUSD` from `Function_Revenue_CryptoToFiat_C2F` | Post `UPDATE`s force sentinel `-1` for copy/buy/leverage/future/smart-portfolio sentinel columns (`Metric='CryptoToFiatFee'`) |
| `StakingLagOneMonth` | `TotalUSDDistributed` from `Function_Revenue_StakingFee` | `DateID` shifted forward `(DATEADD(month,1,…)` + dynamic window into prior month staging); explicit `RevenueMetricID=12`, `Category=4`
| `Options_PFOF` | `Amount`/`CountTransactions`/flags from `#optionsalltime` sourcing `Function_Revenue_OptionsPlatform` | Separate `DELETE`/`INSERT`; `WHERE RevenueMetricID=18`; resets `IsMarginTrade` selectively |

### 2.2 Action type semantics & sentinel `-1`

**What**: **`ActionTypeID`** stays faithful to trading grains for commissions; **`ISNULL(ActionTypeID,-1)` at insert collapses analytic streams without trading keys.

**Columns Involved**: `ActionTypeID`, `ActionType`, `Metric`.

**Rules** — verbatim predicates from `#revenue` construction logic:
- `'FullCommission'`, `'Commission'` unions honour real `fc.ActionTypeID` while joining `JOIN DWH_dbo.Dim_ActionType dat ON frfc.ActionTypeID = dat.ActionTypeID`.
- Overnight-style unions push literal `NULL AS ActionTypeID` before insert coerces to `-1`.
- Rolling metrics like `CashoutFeeExclRedeem`, `ConversionFee`, `TransferCoinFee`, etc., all emit `NULL AS ActionTypeID` prior to sentinel packaging.

Recent slice (`WHERE DateID >= 20260101`) ActionType clustering (joined to `Dim_ActionType`):

| Rows (approx.) | ActionTypeID | Representative Dim name |
|----------------|--------------|--------------------------|
| 46.4M | -1 | *Sentinel for non-trade metrics / rolled NULLs*
| 22.1M | 2 | CopyPositionOpen
| 21.0M | 1 | ManualPositionOpen
| 19.1M | 5 | CopyPositionClose
| 17.3M | 4 | ManualPositionClose
| 2.17M | NULL | Legacy NULL bucket (investigate loaders if unexpected)
| 37.9k | 6 | CopyPlusPositionClose
| 1.7k | 3 | CopyPlusPositionOpen |

### 2.3 Transfercoin & **`IsRedeem`** semantics (upstream only)

Even though **`IsRedeem` is omitted from the physical schema**, interpreting **`Metric='TransferCoinFee'`** requires **`Fact_CustomerAction.IsRedeem` dual-semantics**:

> **Dual-semantics redeem flag.** (A) **Ledger / Crypto-wallet Path:** Loader CASE documented in **`Dim_FundingType.md` §2.3 (`CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`)** tagging **eToroCryptoWallet (`FundingTypeID=27`) cash-outs** (`ActionTypeID = 8` sample slice **100 % FundingType 27 whenever `IsRedeem=1`** for `DateID≥20260101`). Revenue TVF **`Function_Revenue_TransferCoinFee`** filters **`Fact_CustomerAction` with `ActionTypeID = 30` AND `IsRedeem = 1`** — interpret as **transfer-to-coin / fiat-wallet → on-chain custody** (**not** shorthand for bank cash-out). (B) **CFD Billing.Redeem Path:** Positional closes (`ActionTypeID∈{4,5,6,…}`) can emit **`IsRedeem=1` alongside `RedeemID`/`RedeemStatus`** (Billing.Redeem integration per `Trade.PositionTbl`) — orthogonal to transfercoin semantics. CLOSE-branch **`CASE` text unavailable** (`sys.sql_modules.definition` **NULL** for `SP_Fact_CustomerAction` on this Synapse warehouse). **Do not equate blindly to non-existent `Dim_Position.IsRedeem` column.** (Tier 2 — SP_Fact_CustomerAction)

### 2.4 Lake-merge key semantics (`NULL → -1`)

**What**: 2025-12 changes replace merge-key NULLs with **`-1`** (and `CountTransactions` coerced to numeric zero).

**Rules** (verbatim idea from changelog inside SP header + body):
- Outer insert applies `ISNULL` to `RealCID`-adjacent sentinel columns (`IsCopy`, instrument columns, SQF column, …) to stabilise merges from lake SB automation.

---

## 3. Query Advisory

### 3.1 Synapse distribution & pruning

Targeting **`HASH(RealCID)`** mandates filters on **`DateID`** *and*, when possible, selective `RealCID` lists — never full-table scans (>3 B logical rows).

### 3.2 Patterns

| Question | Recommendation |
|---------|----------------|
| Total revenue dashboards | Join `Dim_Revenue_Metrics` and filter **`IncludedInTotalRevenue = 1`** remembering SDRT coercion already happened downstream |
| Commission vs CFD economics | Pivot on **`Metric`** plus `InstrumentTypeID` / `IsSettled` combinations |
| Transfercoin auditing | Focus `Metric='TransferCoinFee'` and cross-check **`Function_Revenue_TransferCoinFee`** definition for predicates |
| Options panel | Isolate `WHERE RevenueMetricID = 18` knowing it's reloaded nightly across full horizon |

### 3.3 Common JOINs

| Join target | Predicate | Purpose |
|-------------|-----------|---------|
| `BI_DB_dbo.Dim_Revenue_Metrics` | `drm.Metric = f.Metric OR drm.RevenueMetricID = f.RevenueMetricID` | Inclusion flags + categories |
| `DWH_dbo.Dim_ActionType` | `ActionTypeID` (ignore `-1`/NULL sentinel rows) | Action naming when applicable |
| `DWH_dbo.Dim_Instrument` / `Dim_Instrument_Snapshot` | via separate modeling (not stored here) | Deep instrument facts |
| `DWH_dbo.Dim_Customer` | `RealCID` | Customer attributes |

### 3.4 Gotchas

- **Do not double-count `Commission` + `FullCommission`.** `Dim_Revenue_Metrics` explicitly treats `Commission` as subcomponent excluded from totals.
- **`ActionTypeID = -1`** encodes “non-trading metric stream” — not a `Dim_ActionType` natural key.
- **Staking rows lag one month** relative to TVF-sourced close dates (see SP `DATEADD(MONTH,1,…)`).
- **Options** second pass can rewrite historical `DateID`s outside the nominal daily partition when SB replays backlog.
- **InstrumentType sentinel `-1`** still shows heavy volume (**~4.8M rows / day slice**) — validates account-wide fees lacking instrument granularity.

InstrumentType hotspots (`DateID >= 20260101`, Synapse MCP):

| InstrumentTypeID | Rows (approx.) |
|------------------|----------------|
| 5 | 61.6M |
| 2 | 19.2M |
| 10 | 16.2M |
| 6 | 13.9M |
| 4 | 9.5M |
| -1 | 4.77M |

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| 1 | Upstream wiki / dictionary-verified lineage |
| 2 | SP/TVF-computed aggregates, composites, parquet overlays |
| 5 | Domain expert reconciliation (prior narrative corrected) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business date key (**YYYYMMDD**) driving partition swaps; staking branch shifts Month+1 versus TVF-derived activity date; Options reload obeys TVF-supplied horizon. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 2 | Date | date | YES | Calendar `DATE` mirrored from `@date` parameter on primary insert, TVF timestamps for Options, or derived calendar date when staking rewinds partitions. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 3 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. **(Tier 1 — Customer.CustomerStatic)** |
| 4 | ActionTypeID | int | YES | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds. **DDR note:** aggregated revenue streams coerce NULL → `ISNULL(...,-1)` at insert; `-1` marks non-trade metrics. **(Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads)** |
| 5 | ActionType | varchar(50) | YES | Verb text for streams — either `Dim_ActionType.Name` (commissions path) **or** literal identifiers (`Rollover`, `SDRT`, `'Redeem'` for TransferCoin aggregates, staking/options labels). **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 6 | InstrumentTypeID | int | YES | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. **`ISNULL(...,-1)`** masks NULL account-level feeds. **(Tier 1 — Trade.GetInstrument)** |
| 7 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. **DDR note:** `ISNULL(...,-1)` sentinel for streams lacking instruments. **(Tier 5 — Expert Review)** |
| 8 | IsCopy | int | YES | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END` from revenue TVFs, then `ISNULL(...,-1)`; crypto-to-fiat branch forces `-1` post UPDATE. Indicates copy-trading linkage on applicable metrics. **(Tier 2 — Fact_CustomerAction.MirrorID logic via Function_Revenue_*)** |
| 9 | Metric | varchar(50) | YES | Canonical revenue column label (`FullCommission`, `RollOverFee`, `TransferCoinFee`, `StakingLagOneMonth`, …) — enumerated in **`Dim_Revenue_Metrics.Metric`**. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 10 | Amount | decimal(16,6) | YES | USD revenue amount aggregated per UNION/GROUP grain — sign reflects economic direction (negative dividend payouts retained). Populated strictly from enumerated TVF monetary columns summarized in **`§2.1`**. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 11 | CountTransactions | int | YES | `COUNT`/`SUM` amalgamation counting instrumented actions per grain; `ISNULL(...,0)` enforced on insert (`ShareLending`/`Staking` may collapse NULL counts). **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 12 | IncludedInTotalRevenue | int | YES | True if this metric contributes to the canonical "Total Revenue" rollup; False for raw/pass-through entries (`Commission`, `Dividends`, `SDRT`). Filter on this when computing top-line revenue to avoid double-counting. **`SP_DDR`** post-processing forces `Metric='SDRT'` rows to **`0`** even if dictionary flipped historically. Stored as **`int` mirror** of **`Dim_Revenue_Metrics`** bit semantics. **(Tier 1 — UC sample)** |
| 13 | CountAsActiveTrade | int | YES | **`CASE WHEN ActionTypeID IN (1,39) AND ISNULL(IsAirDrop,0) = 0 THEN 1 ELSE 0 END`** on commission feeders; flattened to **`0`** elsewhere before insert coercion. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 14 | UpdateDate | datetime | YES | ETL stamp `GETDATE()` captured at each INSERT pass (main, options purge, staking window). **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 15 | IsBuy | int | YES | **`1`** Long **`0`** Short; NULL ⇒ non-trade row sentinel — widened/truncated via `ISNULL(...,-1)` with dividend amount-based overrides (**`Metric='Dividends'`**) and **`CryptoToFiatFee`** sentinel `-1` path. **(Tier 1 — Trade.PositionTbl)** |
| 16 | IsLeveraged | int | YES | Derived `CASE WHEN Leverage > 1 THEN 1 ELSE 0 END` sourced from BI_DB TVFs feeding position-level revenue; `ISNULL` packaging for lake merges. Admin fee branch aliases `Leverage` as `IsLeverage` inside grouping (typo tolerated). **(Tier 2 — Function_Revenue_FullCommissions / AdminFee lineage)** |
| 17 | IsFuture | int | YES | Combination of TVF payloads and `Dim_Instrument.IsFuture` for admin/spot adjust branches (with `CryptoToFiatFee` forced `-1`). `ISNULL` packaging standard. **(Tier 2 — Dim_Instrument / Function_Revenue_TVF)** |
| 18 | IsCopyFund | int | YES | **`CASE WHEN BI_DB_CopyFund_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END`** seeded via sequential updates on commission temps; `ISNULL` packaging. **(Tier 2 — BI_DB_CopyFund_Positions)** |
| 19 | IsOpenedFromIBAN | int | YES | Indicator set via staged parquet + `Dim_Position`-aligned `UPDATE` overlays for eligible overnight/ticket/dividends positions (`1` once matched else `-1` sentinel via `ISNULL`). **(Tier 2 — External_bi_output_finance_bi_db_positions_opened_from_iban_parquet)** |
| 20 | IsClosedToIBAN | int | YES | Same IBAN close-table overlay pattern as `IsOpenedFromIBAN`. **(Tier 2 — External_bi_output_finance_bi_db_positions_closed_to_iban_parquet)** |
| 21 | IsRecurring | int | YES | Recurring investment overlay using `External_bi_db_recurringinvestment_positions_parquet`; `ConversionFee` branch also carries TVF `IsRecurring`. **(Tier 2 — External_bi_db_recurringinvestment_positions_parquet)** |
| 22 | IsAirDrop | int | YES | Free-share flag sourced from BI_DB TVFs describing AirDrop exclusions for active-trade tallies (`ISNULL` packaging plus metric-specific coercion). **(Tier 2 — Function_Revenue_FullCommissions / Function_Revenue_Commissions)** |
| 23 | IsSQF | int | YES | **`IsSQF` (SpotQuotedFuture flag) — 1 = instrument is a SpotQuotedFuture (a smaller-contract variant of eToro RealFutures, traded on the CME / Chicago Mercantile Exchange). 0 = not an SQF instrument. Source: `Function_Instrument_Snapshot_Enriched(@dateInt)` via membership in `Trade.InstrumentGroups` with `GroupID = 59`. ISNULL coalesces to -1 for streams where SQF classification doesn't apply (Dividends, SDRT, staking, deposit/withdraw fees). (Tier 5 — user expert correction; previously mis-described as "Sustainable & Quality-Focused")** |
| 24 | RevenueMetricID | int | YES | Surrogate key. Stable integer 1-18 (with new entries appended). FK target from DDR fact tables when revenue is stored long-form. Seeds via `JOIN Dim_Revenue_Metrics`; staking (`12`) and options (`18`) forcibly seeded in dedicated branches prior to dictionary refresh. **(Tier 1 — UC sample)** |
| 25 | RevenueMetricCategoryID | int | YES | Category surrogate key 1-5. 1=TradeTransactional, 2=Overnight, 3=MIMO, 4=RevShare, 5=Other — inherited from **`Dim_Revenue_Metrics`** (plus staking/options seeded pairs). **(Tier 1 — UC sample)** |
| 26 | IsMarginTrade | int | YES | Mirrors TVF-supplied flag with SP-level overrides (`Metric='SDRT'` ⇒ `IsMarginTrade=0`; `Metric='Options_PFOF'` margin adjustments). **(Tier 2 — Function_Revenue_* / SP_DDR_Fact_Revenue_Generating_Actions)** |
| 27 | IsC2P | int | YES | **`CASE WHEN V_C2P_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END`** on position-backed paths; `ISNULL` packaging for non-position metrics. **(Tier 2 — BI_DB_dbo.V_C2P_Positions)** |

---

## 5. Lineage

### 5.1 Production sources (representative)

| Synapse column | Production / DWH origin | Source column | Transform |
|----------------|------------------------|---------------|-----------|
| RealCID | `Customer.CustomerStatic` (via `Fact_CustomerAction`) | `RealCID` | TVF passthrough + aggregation |
| Amount | Enumerated TVF-specific fee columns (see **§2.1**) | Various | `SUM` / `COUNT` |
| InstrumentTypeID | `Trade.GetInstrument` / `Dim_Instrument` | `InstrumentTypeID` | cast + sentinel |
| IsSQF | `Trade.InstrumentGroups` (**GroupID=59**) via `Function_Instrument_Snapshot_Enriched` staging join | Derived flag | Instrument membership |

### 5.2 ETL pipeline sketch

```
Generic Pipeline Bronze/DWH ingestion → DWH Facts/Dims (+ lake parquet overlays)
               │
 BI_DB Revenue TVFs (Function_Revenue_*) ──► temp tables (#rollovers … #staking, #optionsalltime)
               │
 BI_DB.SP_DDR_Fact_Revenue_Generating_Actions (@date parameter)
               │ DELETE target WHERE DateID=@dateID
               │ INSERT #revenue (union of all metrics)
               │ DELETE/INSERT RevenueMetricID=18 (Options history)
               │ DELETE month slice RevenueMetricID=12 + INSERT staking lag rows
               ▼
 BI_DB_DDR_Fact_Revenue_Generating_Actions (Synapse)
               │ Generic Pipeline (Override delta)
               ▼
 main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
```

```text
UPSTREAM SEARCH LOG — BI_DB_DDR_Fact_Revenue_Generating_Actions:
  Lineage source objects:
    1. Function_Revenue_* family (fact: TVF aggregates) → Local BI_DB wiki (Functions/*.md): FOUND Read YES — enumerates Fact_CustomerAction joins etc.
    2. Fact_CustomerAction → knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md FOUND Read YES — ActionTypeID, IsBuy, dual semantics prose
    3. Dim_Customer → FOUND Read YES — RealCID verbatim description
    4. Dim_Instrument → FOUND Read YES — InstrumentTypeID reference set
    5. Dim_Revenue_Metrics → FOUND Read YES — Inclusion/category columns
    6. BI_DB_CopyFund_Positions → NOT_FOUND dedicated wiki — rely on SP overlay description (Tier 2)
    7. V_C2P_Positions → NOT_FOUND standalone wiki — SP-only reference (Tier 2)
    8. Parade IBAN parquet externals → NOT_FOUND wiki → Tier 2 external overlay
    9. Fact_CustomerAction.md + Function_Revenue_TransferCoinFee.md → FOUND Read YES for transfercoin predicates
```

---

## 6. Relationships

### 6.1 References to

| Element bundle | Related object | Notes |
|----------------|----------------|-------|
| `Metric`, `RevenueMetricID`, `IncludedInTotalRevenue` | `BI_DB_dbo.Dim_Revenue_Metrics` | Inclusion + category semantics |
| `ActionTypeID` (non sentinel) | `DWH_dbo.Dim_ActionType` | Naming / classification joins |
| `RealCID` | `DWH_dbo.Dim_Customer`, `Fact_SnapshotCustomer` (+ Genie composites) | Standard customer spine |

### 6.2 Referenced by

UC Genie **`etoro_kpi_prep`** `v_revenue_*` mirrored views, dashboards, notebooks pulling **`main.bi_db.gold_*`**, and downstream KPI prep bundles — exact consumer list rotates; search Unity Catalog dependents before refactors.

---

## 7. Sample Queries

### 7.1 Full vs net commission split

```sql
SELECT Metric,
       SUM(Amount) AS usd_amt
FROM   BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE  DateID BETWEEN 20260101 AND 20260131
  AND  Metric IN ('FullCommission','Commission')
GROUP BY Metric;
```

### 7.2 Top-line revenue only

```sql
SELECT DateID,
       SUM(Amount) AS top_line_rev
FROM   BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions f
JOIN   BI_DB_dbo.Dim_Revenue_Metrics drm
       ON drm.Metric = f.Metric
WHERE  IncludedInTotalRevenue = 1
GROUP BY DateID
ORDER BY DateID DESC;
```

### 7.3 SpotQuotedFuture slice for futures analytics

```sql
SELECT Metric,
       AVG(CAST(IsSQF AS FLOAT)) AS sqf_activation_rate -- exploratory; mind sentinel -1 filtering
FROM   BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE  DateID = 20260425 AND IsSQF >= 0
GROUP BY Metric;
```

---

## 8. Atlassian Knowledge Sources

**Phase 10 skipped** — Confluence/Jira queries not executed (`plugin-atlassian-atlassian` MCP not invoked this session).

---

*Generated: 2026-05-14 | Quality: **8.4**/10 | Phases: P1‑P16 (Atlassian SOFT skip) | Encoding: UTF-8*  
*Tiers: 7×T1 · 18×T2 · 2×T5 — Elements **27**/27 DDL columns (parity ✅)*  
*Synapse MCP row estimate **3 162 411 783** rows | Date span **20100103–20260425** (`DateID`)*  
*Object: BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions*
