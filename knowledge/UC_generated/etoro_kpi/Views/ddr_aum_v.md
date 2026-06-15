---
object_fqn: main.etoro_kpi.ddr_aum_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.ddr_aum_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 52
row_count: null
generated_at: '2026-05-19T15:20:36Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
- main.bi_output.bi_output_vg_date
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_aum_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_aum_v.sql
concept_count: 0
formula_count: 52
tier_breakdown:
  tier1_columns: 15
  tier2_columns: 37
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# ddr_aum_v

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 52 of 52 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_aum_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 52 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Apr 14 07:54:04 UTC 2026 |

---

## 1. Business Meaning

`ddr_aum_v` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_AUM.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 52 columns: 15 inherit byte-for-byte from upstream wikis (Tier 1), 37 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

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
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | STRING | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. HASH distribution grain for this fact. Merge key `COALESCE(cb.CID, i.CID, ob.RealCID)` resolves TP + IBAN + Options shell customers. (Tier 1 — Customer.CustomerStatic) |
| 1 | DateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 2 | RealizedEquityTradingPlatform | DECIMAL | YES | Customer's **settled (realized) equity** — the realized portion of customer balance, **excluding unrealized PnL on open positions** (the unrealized component lives in `Fact_CustomerUnrealized_PnL.PositionPnL`). From `Fact_SnapshotEquity.RealizedEquity` via Client Balance. DDR transform: **SUM per CID/DateID** across Client Balance rows. (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 3 | TotalPositionPNL | DECIMAL | YES | Total position PnL across all asset classes. From `V_Liabilities.PositionPnL`. Unrealized profit/loss on all open positions. DDR transform: SUM(`PositionPNL`). (Tier 2 — SP_Client_Balance_New) |
| 4 | TotalInvestedAmount | DECIMAL | YES | Total position amount (`TotalPositionsAmount` lineage). Measures aggregate market value of exposures. DDR transform: SUM(`PositionAmount`). (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 5 | EquityTradingPlatform | DECIMAL | YES | Trading-platform **TotalEquity surrogate** summed as `SUM(ISNULL(TotalLiability,0) + ISNULL(actualNWA,0))` inside `#ClientBalance`. Not identical to interpreting “TP equity = liability view only”; treat as authoritative DDR column for `_TP` rollup. DDR transform: aggregate SUM pipeline. (Tier 2 — SP_DDR_Fact_AUM) |
| 6 | CashInCopy | DECIMAL | YES | Allocation of **`TotalCash`** attributable to mirrored strategies — VL passes `Fact_SnapshotEquity.TotalMirrorCash`; represents copier-side cash earmarked inside copy envelopes. Passthrough VL daily snapshot filtered to `@dateID`. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorCash) |
| 7 | InvestedAmountCopy | DECIMAL | YES | **`TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL`** (copy invested + unrealized uplift). Cash excluded intentionally. SP-authored. (Tier 2 — SP_DDR_Fact_AUM) |
| 8 | EquityCopy | DECIMAL | YES | **Composite copy equity**: `TotalMirrorCash + TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL`, null-guarded in SP verbatim block. Mirrors entire copy-trade economic bundle. (Tier 2 — SP_DDR_Fact_AUM) |
| 9 | EquityStocksManual | DECIMAL | YES | Manual (non-copy) stock equity authored per SP verbatim difference of totals & mirrors (see lineage Phase 9). (Tier 2 — SP_DDR_Fact_AUM) |
| 10 | InvestedAmountStocksManual | DECIMAL | YES | Manual invested-only stock footprint **excluding** mirrored mirror stock leg (SP subtract). (Tier 2 — SP_DDR_Fact_AUM) |
| 11 | InvestedAmountCryptoManual | DECIMAL | YES | **`TotalCryptoManualPosition`** = `TotalCryptoPositionAmount − TotalMirrorCryptoPositionAmount` per VL formula; VL-classified Tier-2 derivation because computed inside view. Alias renamed in DDR inserts. (Tier 2 — DWH_dbo.V_Liabilities) |
| 12 | BalanceTradingPlatfrom | DECIMAL | YES | Promotional **`Credit`** component from VL / `Fact_SnapshotEquity.Credit`; column renamed **`CreditTP`** for DDR clarity while identical numeric semantics. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit) |
| 13 | BalanceIBAN | DECIMAL | YES | **Non-TP** IBAN-held balance aggregated `SUM(mcb.ClosingBalanceBO * mcb.USDApproxRate)` excluding `GCID IS NULL OR GCID=0`. Explicit USD approximation path. (Tier 2 — SP_DDR_Fact_AUM) |
| 14 | RealizedEquityGlobal | DECIMAL | YES | **`RealizedEquityTP + IBANBalance`**; excludes Options equities per SP explanatory comment inability to split invested vs PnL. (Tier 2 — SP_DDR_Fact_AUM) |
| 15 | EquityGlobal | DECIMAL | YES | **`TotalEquityTP + IBANBalance + OptionsTotalEquity`** — consolidated **DDR AUM / equity-under-management style metric**. Filter axis for primary INSERT. (Tier 2 — SP_DDR_Fact_AUM) |
| 16 | CreditGlobal | DECIMAL | YES | **`CreditTP + IBANBalance + OptionsCashEquity`** — injects Apex **cash** component only (distinct from **`OptionsTotalEquity`** numerator). Authored verbatim in SP. (Tier 2 — SP_DDR_Fact_AUM) |
| 17 | OptionsTotalEquity | DECIMAL | YES | Apex options economic value from **`Function_AUM_OptionsPlatform(@OptionsMaxDateID,0)`** keyed on latest external buy-power close ≤ ingestion; merges by `FULL OUTER` on **`RealCID`**; precision widened DDL `decimal(18,6)` versus TP metrics. House IDs filtered inside downstream function lineage. (Tier 2 — SP_DDR_Fact_AUM) |
| 18 | WeekNumberYear | INT | YES | Direct passthrough from upstream. Formula: `WeekNumberYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 19 | CalendarYearMonth | STRING | YES | Direct passthrough from upstream. Formula: `CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 20 | CalendarQuarter | INT | YES | Direct passthrough from upstream. Formula: `CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 21 | CalendarYear | INT | YES | Direct passthrough from upstream. Formula: `CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 22 | IsLastDayWeek | INT | NO | Direct passthrough from upstream. Formula: `IsLastDayWeek`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 23 | IsLastDayMonth | INT | NO | Direct passthrough from upstream. Formula: `IsLastDayMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 24 | IsLastDayQuarter | INT | NO | Direct passthrough from upstream. Formula: `IsLastDayQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 25 | IsLastDayYear | INT | NO | Direct passthrough from upstream. Formula: `IsLastDayYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 26 | SnapshotDate | TIMESTAMP | YES | Calendar **`@date`** argument inserted literally; mirrors `DateID`. (Tier 2 — SP_DDR_Fact_AUM) |
| 27 | TotalLiabilityTP | DECIMAL | YES | Total liability from open positions. From `V_Liabilities.Liabilities`. Represents the unrealized obligation (positive = amount owed to customer; negative = customer owes). DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 28 | InProcessCashout | DECIMAL | YES | Pending cashout amount not yet finalized. From `Fact_SnapshotEquity.InProcessCashouts`; excludes statuses 3=Processed, 4=Cancelled, 5, 6. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 29 | NOP | DECIMAL | YES | Total Net Open Position across all asset classes. From `V_Liabilities.NOP`. Net market exposure. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 30 | NOPCrypto | DECIMAL | YES | Net Open Position for crypto instruments. From `V_Liabilities`. Represents the net market exposure in crypto. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 31 | NOPCryptoCFD | DECIMAL | YES | NOP for crypto CFDs specifically (not settled/real crypto). DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 32 | NOPStocks | DECIMAL | YES | Net Open Position for stock instruments. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 33 | NOPStocksCFD | DECIMAL | YES | NOP for stock CFDs specifically. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 34 | TotalRealCryptoLoan | DECIMAL | YES | Total leveraged real crypto loan amount. InitialAmount where `IsSettled=1` AND `InstrumentTypeID=10` AND `Leverage=2`. DDR transform: SUM. (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 35 | Bonus | DECIMAL | YES | Bonus credits (`ActionTypeID=9`). DDR transform: SUM. (Tier 2 — SP_Client_Balance_New) |
| 36 | CopyInvestedAmount | DECIMAL | YES | **`TotalMirrorPositionsAmount`** — mirrored strategy invested notionals aggregated at customer-day grain. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorPositionsAmount) |
| 37 | CopyStockOrders | DECIMAL | YES | **`TotalMirrorStockOrders`** — legacy pathway (documented VL as historically zero since 2019). Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorStockOrders) |
| 38 | CopyPositionPnL | DECIMAL | YES | **`CopyPositionPnL`** mirrored strategy unrealized incremental PnL component from **`Fact_CustomerUnrealized_PnL`** via VL. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.CopyPositionPnL) |
| 39 | StockInvestedAmount | DECIMAL | YES | **`TotalStockPositionAmount`** equities exposure aggregate from **`Fact_SnapshotEquity`** via VL. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalStockPositionAmount) |
| 40 | StockOrders | DECIMAL | YES | **`TotalStockOrders`** equity route (legacy zeros). VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalStockOrders) |
| 41 | StocksPositionPnL | DECIMAL | YES | **`StocksPositionPnL`** discretionary + house stock CFD PnL component from VL / FCUPNL join. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.StocksPositionPnL) |
| 42 | MirrorStockInvestedAmount | DECIMAL | YES | **`TotalMirrorStockPositionAmount`** — stock exposure executed inside copy overlays. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorStockPositionAmount) |
| 43 | MirrorStocksPositionPnL | DECIMAL | YES | **`MirrorStocksPositionPnL`** VL field isolating mirrored stock PnL. Passthrough VL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL) |
| 44 | CryptoManualPositionPnL | DECIMAL | YES | **`ManualCryptoPositionPnL`** from FCUPNL via VL passthrough representing manual-route crypto PnL. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL) |
| 45 | EquityCryptoManual | DECIMAL | YES | **Manual crypto bundle** sums `TotalCryptoManualPosition + ManualCryptoPositionPnL` with DDR null guards. Authored `#vl`. (Tier 2 — SP_DDR_Fact_AUM) |
| 46 | TotalRealCrypto | DECIMAL | YES | **`Fact_SnapshotEquity.TotalRealCrypto`** — outright crypto inventory dollars. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalRealCrypto) |
| 47 | TotalRealStocks | DECIMAL | YES | **`Fact_SnapshotEquity.TotalRealStocks`** — shares / cash equities inventories. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalRealStocks) |
| 48 | CreditTP | DECIMAL | YES | Promotional **`Credit`** component from VL / `Fact_SnapshotEquity.Credit`; column renamed **`CreditTP`** for DDR clarity while identical numeric semantics. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit) |
| 49 | ActualNWA | DECIMAL | YES | VL-computed capped net-worth share: **`CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END`** where `NetEquity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0)` (VL §2.2). Passthrough VL. (Tier 2 — DWH_dbo.V_Liabilities) |
| 50 | TotalLiabilityGlobal | DECIMAL | YES | **`TotalLiabilityTP + IBANBalance + OptionsTotalEquity`** verbatim from `#final`. (Tier 2 — SP_DDR_Fact_AUM) |
| 51 | UpdateDate | TIMESTAMP | YES | **GETDATE()`** stamp aligning insert batch concurrency control. (Tier 2 — SP_DDR_Fact_AUM) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_AUM.md` |
| `main.bi_output.bi_output_vg_date` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
main.bi_output.bi_output_vg_date
        │
        ▼
main.etoro_kpi.ddr_aum_v   ←── this object
        │
        ▼
main.etoro_kpi.customer_segments_v
main.etoro_kpi.v_raf
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=52 runtime=52 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_AUM.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi.customer_segments_v`
- `main.etoro_kpi.v_raf`

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 52 | Tiers: 15 T1, 37 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 52/52 | Source: view_definition*
