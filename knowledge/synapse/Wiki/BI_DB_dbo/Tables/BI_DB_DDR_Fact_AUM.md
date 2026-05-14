# BI_DB_dbo.BI_DB_DDR_Fact_AUM

> DDR **Assets Under Management** fact — one row per `RealCID` per `DateID` after ETL dedupe/filter. Live samples show ~4.45M distinct customers per day (e.g. DateID **20260425**); observable `DateID` span since 20200101 tops out at **20260425**. Unifies TP balances from **`BI_DB_Client_Balance_CID_Level_New`**, mirrored/manual equity components from **`DWH_dbo.V_Liabilities`**, USD IBAN (**eMoney**) balances, and **Options (Apex)** equity from **`Function_AUM_OptionsPlatform`**.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — DDR daily AUM snapshot) |
| **Production Source** | Derived aggregate — `BI_DB_dbo.SP_DDR_Fact_AUM` blending Client Balance **SUM**, `V_Liabilities`, IBAN rollup, Apex options TVF |
| **Refresh** | Daily parameter load — `DELETE WHERE DateID = @dateID` then INSERT from `#final`; `UpdateDate = GETDATE()` batch stamp |
| | |
| **Synapse Distribution** | HASH (`RealCID`) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` |
| **UC Format** | delta |
| **UC Partitioned By** | _(operational)_ — mirror Synapse partitioning policy in bundle metadata |
| **UC Table Type** | Gold replicated export |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_AUM` answers “How much USD-equivalent equity / credit / NOP does each customer carry across TP, copied portfolios, discretionary stocks/crypto, IBAN-held cash, and US options?” SP header (July 2024, Guy Manova) positions it explicitly as the **DDR framework CID-level assortment of balance items**, including historical **NON-TP instruments (IBAN)** with options-equity uplift added later (change log 20251017).

Row grain is **`(RealCID , DateID)`** after exclusions: PRIMARY population keeps customers with **`EquityGlobal <> 0`**. Supplemental second branch (`UNION` without `ALL`) restores edge cases whose Trading Platform **`TotalLiabilityTP` resolves to zero** yet residual TP exposures remain (NOP, PnL, cashouts etc.). Rows with **NULL RealCID are deleted**.

**DDR “AUM” operational definition**: aggregate headline measure is **`EquityGlobal`**, authored in-SP as **`TotalEquity + IBANBalance + OptionsTotalEquity`**. `TotalEquity` itself is summed from **`ISNULL(TotalLiability,0) + ISNULL(actualNWA,0)`** in `#ClientBalance` (see verbatim block in **`BI_DB_DDR_Fact_AUM.lineage.md`**). This **differs conceptually from `TotalEquityTP` column label** (`TotalEquityTP` persists the same summed field from `#final`/`#equityPrep` lineage). Analysts validating balance equations should reconcile against **`BI_DB_Client_Balance_CID_Level_New`** duplicates (two regulation rows).

**USD / FX**:

- Majority of TP-facing columns originate from BI Client Balance **`decimal(16,6)`** lineage already denominated USD in upstream reporting cubes.
- **IBAN balances** multiply **`ClosingBalanceBO * USDApproxRate`** — approximate conversion, not treasury spot snapshot.

### PII posture

| Signal | Detail |
|--------|--------|
| Direct PII columns | none (numeric measures + surrogate keys/dates only) |
| Sensitive identifiers | `RealCID` is a customer surrogate — treat joins to `Dim_Customer`/PII-bearing tables under GDPR tagging program |
| Downstream tagging | Mirror Unity Catalog stewardship for `CID`‑class surrogate columns |

---

## 2. Business Logic

### 2.1 AUM rollup & platform scope (canonical formulas)

Interpretation **quotes SP comments verbatim** where authored:

```
-- Global totals from #final
p.TotalEquity + p.IBANBalance + p.OptionsTotalEquity AS EquityGlobal
```

```
-- SP comment preceding RealizedEquityGlobal assignment
RealizedEquityGlobal -- excluding Options, which cannot differenciate invested from PNL
p.realizedEquity + p.IBANBalance AS RealizedEquityGlobal
```

**Component coverage**

| Bucket | Goes into EquityGlobal via | Narrative |
|--------|---------------------------|-----------|
| Trading platform liability + NWA | `TotalEquity` from `#ClientBalance` | Mirrors BI Client Balance summed liability + ActualNWA |
| Copy-trade cash/pnl | `CashInCopy`, `CopyInvestedAmount`, `CopyPositionPnL`, `EquityCopy` lineage | Mirrors / Popular Investor copied notionals (+ cash leg) sourced from VL |
| Manual stocks/crypto | Equity / invested splits (`EquityStocksManual`, `EquityCryptoManual`, ...) | Separate manual vs mirrored positions using VL computations |
| Non-TP IBAN wallets | `IBANBalance` | eMoney ClosingBalance aggregated & USD-scaled |
| US Options | `OptionsTotalEquity` (+ `CreditGlobal` leverages `OptionsCashEquity`) | Latest Apex-derived batch date may trail `@date`; see lineage |

Excluded / cautions:

- **`InProcessCashout`** remains in TP aggregates but DDR filter logic does **not** automatically net pending withdrawals separately from headline `EquityGlobal`. Validate against AML / treasury dashboards if payouts are stuck.
- **CFD**, **loan**, **futures**, **TRS** granular buckets stay inside **`BI_DB_Client_Balance_CID_Level_New`** / VL — this fact keeps **rolled TP + compartment** columns enumerated in §4 Elements.

---

### 2.2 Copy / Manual equity reconstruction

See **Phase 9 verbatim `#vl`** block (`EquityCopy`, `InvestedAmountCopy`, `EquityStocksManual`, manual crypto composites) embedded in **`BI_DB_DDR_Fact_AUM.lineage.md`**.

---

### 2.3 Options integration lag

Procedure sets `@OptionsMaxDateID` via **MAX(ProcessDate)** on **`BI_DB_dbo.External_Sodreconciliation_apex_EXT981_BuyPowerSummary`**, feeding **`Function_AUM_OptionsPlatform(@OptionsMaxDateID, 0)`** — inherently **≤ latest Apex ingestion**, not implicitly equal to **`@dateID`**.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(`RealCID`) + columnstore: always predicate **`DateID`**, ideally **`RealCID`** for keyed lookups.

### 3.2 UC (Databricks)

Target table `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum`; comment metadata already surfaced via `DESCRIBE TABLE` aligns with lineage tiers from May 2026 sync.

### 3.3 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Platform AUM (headline DDR) | `SELECT SUM(EquityGlobal)` ... `WHERE DateID = @d` |
| Split TP vs IBAN vs Options | Compare `TotalEquityTP`, `IBANBalance`, `OptionsTotalEquity` columns |
| Copy vs discretionary stock equity | `EquityCopy` vs `EquityStocksManual` |
| Sanity vs Client Balance | Re-sum `SUM(...)` aggregates from **`BI_DB_Client_Balance_CID_Level_New`** and diff |

### 3.4 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `RealCID = RealCID` | Attributes / regulation overlays |
| `DWH_dbo.Dim_Date` | `DateID` | Calendar rollups |

### 3.5 Gotchas

- **Regulation-transfer double rows upstream** ⇒ **DDR TP sums consolidate** duplicates—never assume Client Balance grain when reconciling intermediate exports.
- **Options date ≠ business DateID**.
- **`UNION`** filter resurrecting **`TotalLiabilityTP = 0`** edge cases adds rows outside simple `WHERE NOT EquityGlobal = 0` logic—document exploratory joins carefully.
- **Legacy stock order columns**: VL documents `TotalStockOrders` / mirrored analogues **zero since 2019**—still participates arithmetically.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream analytic object publishes Tier-1 surrogate / passthrough lineage (`Dim_Customer`, `V_Liabilities`/FSE-derived columns documented as direct pulls) |
| Tier 2 | Synapse-derived / aggregated / authored inside `SP_DDR_Fact_AUM` or composite totals (`EquityGlobal`, IBAN rollup, OPTIONS TVF bindings) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. HASH distribution grain for this fact. Merge key `COALESCE(cb.CID, i.CID, ob.RealCID)` resolves TP + IBAN + Options shell customers. (Tier 1 — Customer.CustomerStatic) |
| 2 | DateID | int | YES | Business date encoded `YYYYMMDD`; matches `@dateID` CAST from `@date`; delete predicate key. (Tier 2 — SP_DDR_Fact_AUM) |
| 3 | Date | date | YES | Calendar **`@date`** argument inserted literally; mirrors `DateID`. (Tier 2 — SP_DDR_Fact_AUM) |
| 4 | RealizedEquityTP | decimal(16,6) | YES | Customer's **settled (realized) equity** — the realized portion of customer balance, **excluding unrealized PnL on open positions** (the unrealized component lives in `Fact_CustomerUnrealized_PnL.PositionPnL`). From `Fact_SnapshotEquity.RealizedEquity` via Client Balance. DDR transform: **SUM per CID/DateID** across Client Balance rows. (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 5 | TotalLiabilityTP | decimal(16,6) | YES | Total liability from open positions. From `V_Liabilities.Liabilities`. Represents the unrealized obligation (positive = amount owed to customer; negative = customer owes). DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 6 | InProcessCashout | decimal(16,6) | YES | Pending cashout amount not yet finalized. From `Fact_SnapshotEquity.InProcessCashouts`; excludes statuses 3=Processed, 4=Cancelled, 5, 6. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 7 | NOP | decimal(16,6) | YES | Total Net Open Position across all asset classes. From `V_Liabilities.NOP`. Net market exposure. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 8 | NOPCrypto | decimal(16,6) | YES | Net Open Position for crypto instruments. From `V_Liabilities`. Represents the net market exposure in crypto. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 9 | NOPCryptoCFD | decimal(16,6) | YES | NOP for crypto CFDs specifically (not settled/real crypto). DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 10 | NOPStocks | decimal(16,6) | YES | Net Open Position for stock instruments. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 11 | NOPStocksCFD | decimal(16,6) | YES | NOP for stock CFDs specifically. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 12 | TotalRealCryptoLoan | decimal(16,6) | YES | Total leveraged real crypto loan amount. InitialAmount where `IsSettled=1` AND `InstrumentTypeID=10` AND `Leverage=2`. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 13 | TotalPositionPNL | decimal(16,6) | YES | Total position PnL across all asset classes. From `V_Liabilities.PositionPnL`. Unrealized profit/loss on all open positions. DDR transform: SUM(`PositionPNL`). (Tier 2 — SP_Client_Balance_New) |
| 14 | TotalInvestedAmount | decimal(16,6) | YES | Total position amount (`TotalPositionsAmount` lineage). Measures aggregate market value of exposures. DDR transform: SUM(`PositionAmount`). (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 15 | TotalEquityTP | decimal(16,6) | YES | Trading-platform **TotalEquity surrogate** summed as `SUM(ISNULL(TotalLiability,0) + ISNULL(actualNWA,0))` inside `#ClientBalance`. Not identical to interpreting “TP equity = liability view only”; treat as authoritative DDR column for `_TP` rollup. DDR transform: aggregate SUM pipeline. (Tier 2 — SP_DDR_Fact_AUM) |
| 16 | Bonus | decimal(16,6) | YES | Bonus credits (`ActionTypeID=9`). DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 17 | CashInCopy | decimal(16,6) | YES | Allocation of **`TotalCash`** attributable to mirrored strategies — VL passes `Fact_SnapshotEquity.TotalMirrorCash`; represents copier-side cash earmarked inside copy envelopes. Passthrough VL daily snapshot filtered to `@dateID`. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorCash) |
| 18 | CopyInvestedAmount | decimal(16,6) | YES | **`TotalMirrorPositionsAmount`** — mirrored strategy invested notionals aggregated at customer-day grain. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorPositionsAmount) |
| 19 | CopyStockOrders | decimal(16,6) | YES | **`TotalMirrorStockOrders`** — legacy pathway (documented VL as historically zero since 2019). Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorStockOrders) |
| 20 | CopyPositionPnL | decimal(16,6) | YES | **`CopyPositionPnL`** mirrored strategy unrealized incremental PnL component from **`Fact_CustomerUnrealized_PnL`** via VL. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.CopyPositionPnL) |
| 21 | EquityCopy | decimal(16,6) | YES | **Composite copy equity**: `TotalMirrorCash + TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL`, null-guarded in SP verbatim block. Mirrors entire copy-trade economic bundle. (Tier 2 — SP_DDR_Fact_AUM) |
| 22 | InvestedAmountCopy | decimal(16,6) | YES | **`TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL`** (copy invested + unrealized uplift). Cash excluded intentionally. SP-authored. (Tier 2 — SP_DDR_Fact_AUM) |
| 23 | StockInvestedAmount | decimal(16,6) | YES | **`TotalStockPositionAmount`** equities exposure aggregate from **`Fact_SnapshotEquity`** via VL. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalStockPositionAmount) |
| 24 | StockOrders | decimal(16,6) | YES | **`TotalStockOrders`** equity route (legacy zeros). VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalStockOrders) |
| 25 | StocksPositionPnL | decimal(16,6) | YES | **`StocksPositionPnL`** discretionary + house stock CFD PnL component from VL / FCUPNL join. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.StocksPositionPnL) |
| 26 | MirrorStockInvestedAmount | decimal(16,6) | YES | **`TotalMirrorStockPositionAmount`** — stock exposure executed inside copy overlays. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorStockPositionAmount) |
| 27 | MirrorStocksPositionPnL | decimal(16,6) | YES | **`MirrorStocksPositionPnL`** VL field isolating mirrored stock PnL. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL) |
| 28 | EquityStocksManual | decimal(16,6) | YES | Manual (non-copy) stock equity authored per SP verbatim difference of totals & mirrors (see lineage Phase 9). (Tier 2 — SP_DDR_Fact_AUM) |
| 29 | InvestedAmountStocksManual | decimal(16,6) | YES | Manual invested-only stock footprint **excluding** mirrored mirror stock leg (SP subtract). (Tier 2 — SP_DDR_Fact_AUM) |
| 30 | InvestedAmountCryptoManual | decimal(16,6) | YES | **`TotalCryptoManualPosition`** = `TotalCryptoPositionAmount − TotalMirrorCryptoPositionAmount` per VL formula; VL-classified Tier-2 derivation because computed inside view. Alias renamed in DDR inserts. (Tier 2 — DWH_dbo.V_Liabilities) |
| 31 | CryptoManualPositionPnL | decimal(16,6) | YES | **`ManualCryptoPositionPnL`** from FCUPNL via VL passthrough representing manual-route crypto PnL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL) |
| 32 | EquityCryptoManual | decimal(16,6) | YES | **Manual crypto bundle** sums `TotalCryptoManualPosition + ManualCryptoPositionPnL` with DDR null guards. Authored `#vl`. (Tier 2 — SP_DDR_Fact_AUM) |
| 33 | TotalRealCrypto | decimal(16,6) | YES | **`Fact_SnapshotEquity.TotalRealCrypto`** — outright crypto inventory dollars. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalRealCrypto) |
| 34 | TotalRealStocks | decimal(16,6) | YES | **`Fact_SnapshotEquity.TotalRealStocks`** — shares / cash equities inventories. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalRealStocks) |
| 35 | CreditTP | decimal(16,6) | YES | Promotional **`Credit`** component from VL / `Fact_SnapshotEquity.Credit`; column renamed **`CreditTP`** for DDR clarity while identical numeric semantics. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit) |
| 36 | ActualNWA | decimal(16,6) | YES | VL-computed capped net-worth share: **`CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END`** where `NetEquity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0)` (VL §2.2). Passthrough VL. (Tier 2 — DWH_dbo.V_Liabilities) |
| 37 | IBANBalance | decimal(16,6) | YES | **Non-TP** IBAN-held balance aggregated `SUM(mcb.ClosingBalanceBO * mcb.USDApproxRate)` excluding `GCID IS NULL OR GCID=0`. Explicit USD approximation path. (Tier 2 — SP_DDR_Fact_AUM) |
| 38 | RealizedEquityGlobal | decimal(16,6) | YES | **`RealizedEquityTP + IBANBalance`**; excludes Options equities per SP explanatory comment inability to split invested vs PnL. (Tier 2 — SP_DDR_Fact_AUM) |
| 39 | TotalLiabilityGlobal | decimal(16,6) | YES | **`TotalLiabilityTP + IBANBalance + OptionsTotalEquity`** verbatim from `#final`. (Tier 2 — SP_DDR_Fact_AUM) |
| 40 | EquityGlobal | decimal(16,6) | YES | **`TotalEquityTP + IBANBalance + OptionsTotalEquity`** — consolidated **DDR AUM / equity-under-management style metric**. Filter axis for primary INSERT. (Tier 2 — SP_DDR_Fact_AUM) |
| 41 | CreditGlobal | decimal(16,6) | YES | **`CreditTP + IBANBalance + OptionsCashEquity`** — injects Apex **cash** component only (distinct from **`OptionsTotalEquity`** numerator). Authored verbatim in SP. (Tier 2 — SP_DDR_Fact_AUM) |
| 42 | UpdateDate | datetime | YES | **GETDATE()`** stamp aligning insert batch concurrency control. (Tier 2 — SP_DDR_Fact_AUM) |
| 43 | OptionsTotalEquity | decimal(18,6) | YES | Apex options economic value from **`Function_AUM_OptionsPlatform(@OptionsMaxDateID,0)`** keyed on latest external buy-power close ≤ ingestion; merges by `FULL OUTER` on **`RealCID`**; precision widened DDL `decimal(18,6)` versus TP metrics. House IDs filtered inside downstream function lineage. (Tier 2 — SP_DDR_Fact_AUM) |

---

## 5. Lineage

### 5.1 Production Sources — Column Groups

| Group | Immediate Synapse Inputs | Commentary |
|-------|--------------------------|-------------|
| TP rollup (cols `RealizedEquityTP`…`Bonus`, `TotalEquityTP`) | **`BI_DB_Client_Balance_CID_Level_New`** | Summed across potential duplicate regulation-transfer rows |
| Copy / discretionary / credit / NWAs | **`DWH_dbo.V_Liabilities`** (+ underlying FSE / FCUPNL) | Mirrors manual vs copy decomposition |
| IBAN buckets | **`eMoney_dbo.eMoneyClientBalance`** | USDApprox FX multiplier |
| Options | External **`BuyPowerSummary` + Function** | Temporal alignment nuance |

### 5.2 ETL Pipeline ASCII

```
eMoney + Apex Lake exports
        \
         -> External_Sodreconciliation_apex_EXT981_BuyPowerSummary (MAX(ProcessDate)->@OptionsMaxDateID)
DWH snapshots (Fact_SnapshotEquity, FCUPNL) -> V_Liabilities ------------\
                                                                           \
BI_DB_Client_Balance_CID_Level_New (daily P99) -----------------------------+-> SP_DDR_Fact_AUM
                                                                           /
eMoneyClientBalance (IBAN) ----------------------------------------------/

DELETE + INSERT HASH(RealCID) COLUMNSTORE FACT
|
v
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum  (Databricks Gold)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|-----------------|-------------|
| `RealCID` | `DWH_dbo.Dim_Customer` | Canonical customer attributes |
| `DateID` | `DWH_dbo.Dim_Date` | Calendar |

### 6.2 Referenced By

| Consumer | Purpose |
|---------|---------|
| `BI_DB_dbo.SP_MarketingCloudDaily` | Marketing exports referencing `EquityGlobal` / TP cash columns |
| `BI_DB_dbo.SP_RevenueForum` | Investor deck style revenue vs AUM comps |
| `BI_DB_dbo.SP_AML_KYC_Process` | Risk tiering overlays |
| `BI_DB_dbo.BI_DB_V_DDR_AUM` | Thin DDR façade view |

Canonical narrative siblings: **`BI_DB_Client_Balance_CID_Level_New.md`** (supply), **`DWH_dbo.V_Liabilities.md`** (compartments). **`Fact_SnapshotCustomer.md`** remains *indirect supplier* feeding Client Balance (not sampled this pass). **`Function_PnL_Single_Day`** is analytically adjacent for PnL-day drilldowns—not a direct DDL feeder.

---

## 7. Sample Queries

### 7.1 Headline DDR AUM

```sql
SELECT SUM(EquityGlobal) AS ddr_aum_usd
FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM
WHERE DateID = 20260425;
```

### 7.2 Per-customer compartments

```sql
SELECT EquityCopy,
       EquityStocksManual,
       EquityCryptoManual,
       IBANBalance,
       OptionsTotalEquity,
       EquityGlobal
FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM
WHERE RealCID = @cid
  AND DateID = @d;
```

### 7.3 Duplicate regulations — reconcile TP sums

Always aggregate **`BI_DB_Client_Balance_CID_Level_New`** before comparing to **`RealizedEquityTP`** / **`TotalEquityTP`**:

```sql
SELECT CID,
       SUM(realizedEquity) AS realized_agg,
       SUM(TotalLiability) AS liability_agg,
       SUM(ISNULL(actualNWA, 0)) AS nwa_agg
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New
WHERE DateID = @dateid
GROUP BY CID;
```

Compare to **`BI_DB_DDR_Fact_AUM`** for the matching `RealCID`.

---

## 8. Atlassian Knowledge Sources

- Local Synapse reference: **`DWH_dbo.V_Liabilities.md §8 Atlassian`** references “Summary of V-Liabilities (Confluence/BI)” for balance decomposition identities reused here.
- No additional object-specific DDR Confluence slug captured in-repo (flagged Tier 4 follow-up).

---

*Generated: 2026-05-14 | Quality: Phase 16 weighted **8.1 / 10** (see sibling review-needed scorecard narrative)*
*Tiers: 14 Tier 1, 29 Tier 2, 0 Tier 3, 0 Tier 4, 0 Tier 5 | Elements: **43 / 43** parity vs DDL ✓*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_AUM | Type: Table | Production Source: BI_DB_dbo.SP_DDR_Fact_AUM*
