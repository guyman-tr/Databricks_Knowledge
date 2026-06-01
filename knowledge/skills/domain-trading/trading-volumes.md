---
name: domain-trading
description: "Notional trading volume, invested amounts, and transaction counts. Two anchors with a documented semantic divergence: (1) the per-event `fact_customeraction_w_metrics` (~9.1B rows, Lake-built Delta in `main.de_output`) — the AUTHORITATIVE source for volume and amount lineage, lineage chain `Fact_CustomerAction → v_fact_customeraction_enriched → v_fact_customeraction_w_metrics → de_output_etoro_kpi_fact_customeraction_w_metrics`, columns are signed by wallet-flow convention (`InvestedAmountIn` NEGATIVE on opens, `InvestedAmountOut` POSITIVE on closes), `VolumeOnOpen` is QA-recomputed from `InitialUnits × InitForexRate × InitConversionRate`; (2) the aggregated DDR `Fact_Trading_Volumes_And_Amounts` (~793M rows, partitioned by etr_ymd, 17 dimension flags) — convenient pre-aggregated by date × flag combo but its `InvestedAmountClosed` answers a different question than w_metrics' `InvestedAmountOut` (DDR uses `Dim_Position.Amount` = original cash invested on positions that closed today; w_metrics uses `Fact_CustomerAction.Amount` = actual cash returned to wallet on close — live divergence runs $5-12M per day on big trading days). When DDR build switches to a DBX SP, this divergence will close — until then, w_metrics is the source of truth. Covers the 17 dimension flags on the DDR fact, the BIGINT-money type quirks, the two big asymmetry traps (`IsOpenedFromIBAN` STRING vs `IsClosedToIBAN` INT, `IsLeverage` vs `IsLeveraged`), real vs CFD breakdown, volume by asset class, copy/recurring trade identification. Broker-side."
triggers:
  - trading volume
  - notional volume
  - invested amount
  - InvestedAmountOpen
  - InvestedAmountClosed
  - InvestedAmountIn
  - InvestedAmountOut
  - cash deployed
  - cash returned
  - capital deployed
  - capital deployment
  - capital flow
  - net invested
  - trade count
  - number of trades
  - active trader count
  - real vs CFD
  - asset class volume
  - copy trades
  - copy volume
  - recurring investment
  - IBAN trades
  - IsOpenedFromIBAN
  - IsClosedToIBAN
  - smart portfolio volume
  - airdrop
  - C2P
  - IsC2P
  - margin trade
  - IsMarginTrade
  - IsLeverage
  - IsBuy
  - leveraged volume
  - buy volume
  - sell volume
  - long short
  - TotalVolume
  - VolumeOpen
  - VolumeClose
  - VolumeOnOpen
  - VolumeOnClose
  - CountTotalTransactions
  - DDR volumes
  - Fact_Trading_Volumes_And_Amounts
  - w_metrics
  - fact_customeraction_w_metrics
  - VolumeQA
  - QA recomputed volume
  - signed amount
  - signed flow
  - wallet flow
required_tables:
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
  - main.etoro_kpi_prep.v_dim_instrument_enriched
  - main.etoro_kpi_prep.v_fact_customeraction_w_metrics
version: 3
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Trading Volumes & Amounts

eToro's daily trading volume — the headline KPI for the trading platform — exists at **two grains** with a documented semantic divergence:

1. **`fact_customeraction_w_metrics`** (`main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`) — per-event grain, ~9.1B rows. **AUTHORITATIVE source for volume and invested-amount lineage.** Built on Databricks via the chain `Fact_CustomerAction → v_fact_customeraction_enriched → v_fact_customeraction_w_metrics → de_output_etoro_kpi_fact_customeraction_w_metrics`. When the broker side and the DDR fact disagree, **trust w_metrics**.
2. **`bi_db_ddr_fact_trading_volumes_and_amounts`** (`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts`) — pre-aggregated at **customer × date × 16 position-flag dimensions**, ~793M rows. Convenient for "how much was traded by flag" questions and the only place where the 17 dimension flags come pre-bucketed. Currently still Synapse-sourced via `Function_Trading_Volume_PositionLevel`; **slated to be re-built as a Databricks SP on top of `w_metrics`**, at which point its `InvestedAmountClosed` semantics will align with w_metrics.

It is the **wrong table** in either case for "what state was this position in at open" — for that, see [`position-state-and-grain.md`](position-state-and-grain.md).

**Side classification**: **broker-side**. Both tables derive from broker-side artifacts (`Fact_CustomerAction` + `Dim_Position` + 6 broker-side enrichment tables). No dealer-side data (no LP/execution/hedge fields).

## When to Use

Load when the question is about:

- "Total trading volume this quarter", "how much was traded this month?"
- "Real vs CFD breakdown", "settled vs derivative volume"
- "Volume by asset class", "crypto vs stocks volume", "forex volume"
- "How many people traded?", "unique traders", "active trader count" *(trade-based, not the official Active Trader SCD segment)*
- "Long vs short volume", "buy vs sell breakdown" (`IsBuy`)
- "Leveraged vs unleveraged volume" (`IsLeverage`)
- "Margin trade volume" (`IsMarginTrade` — `SettlementTypeID = 5`)
- "Copy-trade volume", "Smart Portfolio volume", "recurring investment volume", "AirDrop volume"
- "IBAN trade volume" (opens — note STRING type!) or "IBAN-closed volume" (closes — INT type)
- "Net invested amount" / "capital deployment trend"
- "Volume QA / position-level audit" — points to `BI_DB_VolumeQA` (Synapse-only, not in UC)

Do **not** load for:

- The official "Active Trader" segment definition (SCD-based, includes Options) → `../domain-customer-and-identity/customer-populations-and-lifecycle.md`
- Position state at open / lifecycle / MirrorID at open / partial-close mechanics → [`position-state-and-grain.md`](position-state-and-grain.md)
- AUM / NOP / equity (end-of-day stock) → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Revenue from a trade → `domain-revenue-and-fees`
- Filtering by ticker / asset (the two-part filter rule) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) (this skill USES that skill's filter rules)
- LP-side / execution-side volume (hedge volumes, LP recon) → dealer-side sub-skills

## Scope

In scope: notional volume (`TotalVolume`, `VolumeOpen`, `VolumeClose` — all BIGINT), invested amounts (`InvestedAmountOpen`, `InvestedAmountClosed`, `NetInvestedAmount` — all DECIMAL(19,4) converted from Synapse `money`), transaction counts (`CountTotalTransactions`, `CountOpenTransactions`, `CountCloseTransactions`), the **17 dimension flags** (`InstrumentTypeID`, `IsSettled`, `IsCopy`, `IsBuy`, `IsLeverage`, `IsFuture`, `IsCopyFund`, `IsOpenedFromIBAN`, `IsClosedToIBAN`, `IsRecurring`, `IsAirDrop`, `IsSQF`, `IsMarginTrade`, `IsC2P`), real vs CFD breakdown, asset-class combos, partial-close `VolumeOpen = 0` convention, the `IsOpenedFromIBAN` STRING / `IsClosedToIBAN` INT asymmetry, the `IsLeverage` (no 'd') vs `IsLeveraged` (other DDR tables) naming quirk, the BIGINT volume / DECIMAL money type quirks, partition strategy, daily DELETE/INSERT refresh semantics, the `BI_DB_VolumeQA` parallel position-level dump.

Out of scope: position state at event time (`position-state-and-grain.md`), end-of-day equity / NOP / unrealized PnL (`portfolio-value-aum-pnl.md`), revenue per trade (`domain-revenue-and-fees`), instrument filter pattern (`instruments-and-asset-classes.md`), Spaceship / MoneyFarm / Apex volumes (acquired-platform sub-skills under `domain-revenue-and-fees`), dealer-side hedge volumes.

Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `w_metrics` is the authoritative source for invested amounts; DDR `InvestedAmountClosed` answers a DIFFERENT question.** This is the single most important fact in this skill, confirmed by reviewer Guy 2026-05-11 and reproduced on live data:
   - **DDR `InvestedAmountClosed`** (via `Function_Trading_Volume_PositionLevel`): `SUM(CAST(Dim_Position.Amount AS FLOAT))` over the close legs of that date. Because `Dim_Position.Amount` is the *original open amount* of the position (capital deployed at open), this column is really "**how much capital had been originally invested in positions that closed today**". It looks BACKWARD to the open.
   - **`w_metrics.InvestedAmountOut`**: `CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN fca.Amount ELSE 0` where `fca.Amount` is the `Fact_CustomerAction.Amount` on the close event — sourced from `History.Credit` — i.e., **the actual cash that returned to the customer's wallet on close**. This is real flow accounting and FORWARD-looking.
   - The two differ by the realized P&L of the closed positions. On a winning portfolio: w_metrics > DDR; on a losing portfolio: w_metrics < DDR. Live diff on the eToro book (May 2026 sample, ABS values):

     | DateID | w_metrics `InvestedAmountOut` | DDR `InvestedAmountClosed` | Diff (w_metrics − DDR) |
     |---|---:|---:|---:|
     | 2026-05-01 | $242.47M | $237.05M | **+$5.43M** |
     | 2026-05-02 | $3.85M | $4.13M | -$0.28M |
     | 2026-05-04 | $311.00M | $299.55M | **+$11.45M** |
     | 2026-05-06 | $438.35M | $438.26M | +$0.08M |

   - **Volumes and `InvestedAmountOpen` essentially match** between the two (cent-level rounding only) because both use `Dim_Position`-sourced values for opens and for volume.
   - **Action**: for any question about "money returned to the customer on close" / "capital flow out of positions" / "what did closes pay back this period?" use w_metrics. For "how much volume / how many trades by flag combo" the DDR fact is still the most convenient. **Planned correction**: when the DDR SP is rebuilt on Databricks (`SP_DDR_Fact_Trading_Volumes_And_Amounts` → DBX SP on top of `w_metrics`), DDR `InvestedAmountClosed` will adopt the `History.Credit.Amount` semantics — this divergence will go away. **Until then**: w_metrics is the source of truth and the DDR fact's `InvestedAmountClosed` should be **labeled as "capital originally invested in closed positions"**, not "cash returned on close".

2. **Tier 1 — `w_metrics` uses a SIGNED wallet-flow convention; DDR uses unsigned magnitudes.** Same `Fact_CustomerAction.Amount` lineage, opposite sign treatment:
   - In `w_metrics`: `InvestedAmountIn` is **NEGATIVE** on opens (cash leaving the wallet to fund the position — e.g., 2026-05-01 SUM = -$226.79M). `InvestedAmountOut` is **POSITIVE** on closes (cash returning to the wallet — SUM +$242.47M). Net wallet flow = `SUM(InvestedAmountIn) + SUM(InvestedAmountOut)`.
   - In the DDR fact: `InvestedAmountOpen` and `InvestedAmountClosed` are both stored as **positive magnitudes** (function pipes them through `InitialAmountCents/100.0` and `CAST(Amount AS FLOAT)` — no sign carried).
   - When you switch between the two tables, **wrap w_metrics in `ABS(...)`** if you want unsigned magnitudes, or pay attention to the sign convention if you want true cash flow accounting. The DDR fact's `NetInvestedAmount = SUM(open − closed)` is approximately equivalent in magnitude to `SUM(-InvestedAmountIn - InvestedAmountOut)` from w_metrics (signs work out to the same answer for "did customers deploy more capital than they pulled out?").

3. **Tier 1 — `WHERE IsOpenedFromIBAN = 1` (integer) returns zero rows on the DDR fact.** The column is **STRING** (`varchar(100)` in Synapse, `STRING` in UC). Use `WHERE IsOpenedFromIBAN = '1'`. **AND**: the sibling column `IsClosedToIBAN` is **INT** — they have asymmetric types. So `WHERE IsClosedToIBAN = 1` (integer) is correct for the close side. This is the second most common gotcha on this table. (On `w_metrics` the column is named `IsOpenFromIBAN` — no past tense — and it is INT.)

4. **Tier 1 — `IsLeverage` (no 'd') is unique to the DDR fact.** Every other DDR table uses `IsLeveraged` (with 'd'). Semantics are identical (`CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`). If you copy a query from another DDR sub-skill, **rename `IsLeveraged` → `IsLeverage`** when you bring it here. **`w_metrics` doesn't have either** — it carries the raw `Leverage` column, derive on the fly.

5. **Tier 1 — `TotalVolume / InvestedAmountOpen` is NOT leverage.** They aggregate at different grains and are not directly divisible. If you need leverage, read it from `Dim_Position.Leverage` or `w_metrics.Leverage` (or use the `IsLeverage` boolean on the DDR fact, which is already pre-bucketed). Same caveat for any "ratio of two columns" approach.

6. **Tier 1 — `TotalVolume ≠ SUM(VolumeOpen) + SUM(VolumeClose)` at the aggregated level (DDR fact).** `TotalVolume` is computed per-position as `(VolumeOpen + VolumeClose)` THEN summed. `SUM(VolumeOpen) + SUM(VolumeClose)` is the column-wise sum. They diverge whenever a position contributes to BOTH the open and close sides within the same group (e.g. opened and closed the same day under the same flag combo). Pick one and stick with it; do NOT compute the difference and treat it as a bug.

7. **Tier 1 — Type quirks across the two anchors.**

   | Concept | DDR fact type | w_metrics type | Notes |
   |---|---|---|---|
   | `VolumeOpen` / `VolumeClose` / `TotalVolume` | `BIGINT` | `DECIMAL(38,6)` | DDR truncates fractional cents; w_metrics keeps 6 decimals (more precise for QA). |
   | `InvestedAmountOpen` / `InvestedAmountClosed` (DDR) / `InvestedAmountIn` / `InvestedAmountOut` (w_metrics) | `DECIMAL(19,4)` | `DECIMAL(12,2)` | w_metrics is dollars-and-cents (matching FCA `Amount`); DDR is `money`-derived. |
   | `IsBuy` | `INT` 0/1 | `BOOLEAN` | Cast carefully when joining. |

8. **Tier 2 — `w_metrics.VolumeOnOpen` is QA-recomputed; the DDR fact uses persisted `Dim_Position.Volume`.** The lake-side enriched view (`v_fact_customeraction_enriched`) computes `VolumeOnOpen = CAST(ROUND(dp.InitialUnits * dp.InitForexRate * dp.InitConversionRate) AS DECIMAL(38,6))` (intentional comment in the view: "use ORIGINAL volume, not pro-rated post partial close"). The DDR fact via `Function_Trading_Volume_PositionLevel` uses the persisted `Dim_Position.Volume` (which the dim populates as `ROUND(AmountInUnitsDecimal * InitForexRate * USD_conversion, 0)`). For full closes these are identical. For partial-close children the w_metrics value reflects the ORIGINAL position size while DDR sets `VolumeOpen = 0` for the children — but the totals match because the DDR distributes the QA-recomputed equivalent across the parent. Live aggregate diff on 2026-05-04: $19,702 on a $1.93B daily flow (0.001%). Treat them as equivalent in aggregate.

9. **Tier 2 — Neither table defines the official "Active Trader" segment.** The official Active Trader population is SCD-based (`Fact_SnapshotCustomer.ActiveTraded = 1`) and includes Options. Either of these tables gives trade-based counts only — `COUNT(DISTINCT RealCID) WHERE CountOpenTransactions > 0` (DDR) or `COUNT(DISTINCT RealCID) WHERE ActionTypeID IN (1,2,3,39)` (w_metrics) is a *proxy* for trade-active customers in the date range, not the official population.

10. **Tier 2 — `VolumeOpen = 0` for partial-close children on the DDR fact is a convention, not a bug.** Partial-close children are the residual positions left when a customer closes only part of an open position. The SP source function gives them `VolumeOpen = 0` AND `CountOpenTransactions = 0` to avoid double-counting against the parent open volume. They contribute only on the close side. **Don't filter `VolumeOpen > 0` thinking it removes bad rows** — you'll lose legitimate close-side data. On `w_metrics` the children appear as their own rows with their own (QA-recomputed) `VolumeOpen` — different mechanic, same end result.

11. **Tier 2 — Daily refresh is DELETE/INSERT BY DateID for the DDR fact.** A given DateID can be regenerated by the SP without affecting other dates. Latency is typically T+1 (yesterday's data appears in the morning). The `UpdateDate` column reflects the SP run time, not anything semantically meaningful. `w_metrics` is built daily by the DE pipeline (Spark on `v_fact_customeraction_w_metrics` view) and partitioned by `etr_ymd`.

12. **Tier 2 — DDR is derived FROM the same broker-side stack as w_metrics, not from real-time event streams.** The at-event-time semantics apply: `IsCopy = 1` on a DDR volume row means the position was opened as a copy AT OPEN (via the `MirrorID > 0` rule in `Function_Trading_Volume_PositionLevel`), regardless of whether it's since been detached. The fact-vs-dim trap is already baked in by the function. See [`position-state-and-grain.md`](position-state-and-grain.md) Warning #1.

13. **Tier 2 — `IsSQF` semantic is ambiguous between this skill family and sibling [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md).** The instruments sub-skill documents IsSQF as `GroupID = 59` in `Trade.InstrumentGroups`. The DDR fact wiki expands it as "Sustainable & Quality-Focused". Live data shows only 8 instruments flagged IsSQF=1 (4 indices + 4 crypto, all also `IsFuture=1`) — consistent with a UK regulatory designation rather than ESG marketing. Treat as a small, rarely-needed flag.

14. **Tier 3 — Both tables are very large.** ALWAYS filter by partition columns: DDR fact uses `etr_ymd` in `YYYY-MM-DD` STRING format (despite the DateID being `YYYYMMDD` INT — different formats in different columns of the same table!); `w_metrics` uses `etr_ymd` in `YYYY-MM-DD` STRING format. A query without the partition filter scans 793M / 9.1B rows and is rejected by most warehouse policies.

15. **Tier 3 — `BI_DB_VolumeQA` parallel dump exists (Synapse only, not in UC).** The Synapse SP writes position-level detail to `BI_DB_VolumeQA` alongside each refresh of the DDR fact. Use only for data-quality investigations against Synapse — it is NOT exposed in UC and is NOT a reporting table. With `w_metrics` available in UC, the VolumeQA need is largely retired for Databricks-side analytics.

---

## The w_metrics lineage chain — authoritative source

Captured from live UC view definitions 2026-05-11:

```
main.dwh.gold_..._fact_customeraction          ← canonical fact (11B rows)
   │  sources: History.Credit, Trade.OpenPositionEndOfDay, History.ClosePositionEndOfDay,
   │           STS audit, Customer.CustomerStatic
   ▼
main.etoro_kpi_prep.v_fact_customeraction_enriched          ← VIEW
   │  PASSIVE branch (ActionType 35, 32, 19, 36 w/ CompReason 56/117/118):
   │     VolumeOnOpen=NULL, VolumeOnClose=NULL  (prevent agg dup)
   │  ACTIVE branch (everything else):
   │     VolumeOnOpen  = CAST(ROUND(dp.InitialUnits * dp.InitForexRate * dp.InitConversionRate) AS DECIMAL(38,6))
   │     VolumeOnClose = CAST(dp.VolumeOnClose AS DECIMAL(38,6))     (persisted)
   │  COALESCES position state (InstrumentID/Leverage/IsSettled/MirrorID/IsAirDrop/
   │     SettlementTypeID/IsBuy) where dp has a value
   ▼
main.etoro_kpi_prep.v_fact_customeraction_w_metrics         ← VIEW
   │  Adds 30+ derived columns. The four that matter here:
   │     InvestedAmountIn  = CASE WHEN ActionTypeID IN (1,2,3,39)    THEN fca.Amount        ELSE 0
   │     InvestedAmountOut = CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN fca.Amount        ELSE 0
   │     VolumeOpen        = CASE WHEN ActionTypeID IN (1,2,3,39)    THEN fca.VolumeOnOpen  ELSE 0
   │     VolumeClose       = CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN fca.VolumeOnClose ELSE 0
   │  Plus: 22 fee/adjustment columns (RollOverFee, Dividend, SDRT, AdminFee,
   │     SpotAdjustFee, ConversionFee*, CashoutFee*, TransferCoinFee, DormantFee,
   │     ShareLendingFee*, ShareLendingGrossAmount, CashoutAdjustment,
   │     NewCopyAmount/StopCopyAmount/AddToCopyAmount/RemoveFromCopyAmount,
   │     CryptoToPosition, BonusCompensation, PnLAdjustment, TicketFeeOpen/Close,
   │     FullCommissionCloseAdjustment, CommissionCloseAdjustment,
   │     FullCommissionTotal, CommissionTotal); 8 flag columns (IsActiveTrade, IsSQF,
   │     Is_245_Instrument, IsCopyFund, IsOpenFromIBAN, IsClosedToIBAN, IsRecurring, IsC2P);
   │     ParentCID + ParentUserName (copy leader)
   │  Joins: v_dim_instrument_enriched, bi_db_depositwithdrawfee(_Reversals),
   │     dim_mirror, bi_output_finance_tables_bi_db_positions_(opened_from|closed_to)_iban,
   │     bronze_recurringinvestment_recurringinvestment_planinstances,
   │     bronze_etoro_trade_adminpositionlog
   │  Filter: ActionTypeID NOT IN (14, 41)   ← drops logins & registrations
   ▼
main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics  ← MATERIALIZED Delta
       9.1B rows, EXTERNAL, deletion vectors enabled, partitioned etr_y/etr_ym/etr_ymd
```

**What this means for volumes/amounts**:

- `w_metrics.InvestedAmountIn` = `Fact_CustomerAction.Amount` (signed, negative on opens) for `ActionTypeID IN (1,2,3,39)`.
- `w_metrics.InvestedAmountOut` = `Fact_CustomerAction.Amount` (signed, positive on closes) for `ActionTypeID IN (4,5,6,28,40)`.
- `w_metrics.VolumeOpen` = QA-recomputed (`InitialUnits × InitForexRate × InitConversionRate`) on open events; 0 elsewhere.
- `w_metrics.VolumeClose` = `Dim_Position.VolumeOnClose` on close events; 0 elsewhere.
- `w_metrics.Amount` (no In/Out suffix) is the raw signed FCA Amount — useful when you don't want to filter by ActionTypeID.

**Where the DDR fact diverges**: DDR's `InvestedAmountClosed = SUM(Dim_Position.Amount)` (the OPEN amount of the position) per close-leg of the date; w_metrics' `InvestedAmountOut` is the actual `History.Credit.Amount` (cash returned to wallet). Same upstream, different downstream choice. The planned DBX SP rebuild for the DDR will adopt w_metrics' choice.

## Tables

| Table | Grain | Use For |
|---|---|---|
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | **per event** (~9.1B rows) | **AUTHORITATIVE for volumes and invested amounts.** Per-event truth, signed cash flow, QA-recomputed volumes, full instrument FK. The only place to ask "what was the actual cash returned on close?" / per-ticker volume / per-event audit. Partition prune on `etr_ymd` (STRING `YYYY-MM-DD`). |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | **RealCID × DateID × 17 flags** (~793M rows) | Convenient for "volume / count by flag combination by date" questions where you don't want to GROUP BY 17 dimensions yourself. **`InvestedAmountClosed` here is `Dim_Position.Amount`-based**, NOT `History.Credit`-based — see Warning #1. Partition prune on `etr_ymd` (STRING `YYYY-MM-DD`); note `DateID` column is INT `YYYYMMDD`. |
| `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` | view onto the materialized table | The Databricks view that materializes `de_output_etoro_kpi_fact_customeraction_w_metrics`. Read for the latest data without waiting for the materialization (rarely needed in practice — the materialized table is fast). |
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | per InstrumentID | Required for the two-part filter pattern (Symbol + InstrumentTypeID). See `instruments-and-asset-classes.md`. |

**DDR fact**: ~793M rows; partitioned `etr_y/etr_ym/etr_ymd`. Daily DELETE/INSERT by DateID via `SP_DDR_Fact_Trading_Volumes_And_Amounts`, which calls `BI_DB_dbo.Function_Trading_Volume_PositionLevel(@dateID, @dateID, 0)` (32-col position-level TVF) then GROUPs by 17 dims, SUMs 9 measures. SP authored 2025-04-20; IsSQF (2025-06), IsMarginTrade (2025-10), IsC2P (2025-12) added. **Planned**: rebuild on Databricks SP over `w_metrics` (closes Warning #1 divergence).

**w_metrics**: 9.1B rows, date range 2007-08-27 → present. Delta, EXTERNAL, deletion vectors enabled. Location `abfss://analysis@.../DE_OUTPUT/Etoro_KPI/Fact_CustomerAction_W_Metrics`. Partitions all STRING `YYYY-MM-DD`. Built daily by Spark on `v_fact_customeraction_w_metrics`. Input filter excludes `ActionTypeID IN (14, 41)` (logins, registrations).

---

## Core Concepts

### Measure columns (9, DDR fact)

| Column | Type | What it is |
|---|---|---|
| `TotalVolume` | BIGINT | Notional (leveraged) value of opens + closes. Per-position `(VolumeOpen + VolumeClose)` then SUM. **Primary trading volume KPI**. |
| `VolumeOpen` / `VolumeClose` | BIGINT | Notional from opens / closes that day. `SUM(CAST(Dim_Position.Volume[OnClose] AS BIGINT))`. Partial-close children: VolumeOpen=0. |
| `InvestedAmountOpen` | DECIMAL(19,4) | Cash deployed at open, pre-leverage. `Dim_Position.InitialAmountCents / 100.0`. Children=0. **Capital deployed**. |
| `InvestedAmountClosed` | DECIMAL(19,4) | **Original** capital invested in positions that closed today. `CAST(Dim_Position.Amount AS FLOAT)` — see Warning #1 for w_metrics divergence. |
| `NetInvestedAmount` | DECIMAL(19,4) | `SUM(per-position (InvestedAmountOpen − InvestedAmountClosed))`. Positive = customer deploying more capital that day. |
| `CountOpenTransactions` / `CountCloseTransactions` / `CountTotalTransactions` | INT | Opens / closes / total counts. Open count excludes partial-close children. |

### Dimension flags (17)

| Flag | Type | Meaning | Source |
|---|---|---|---|
| `RealCID` | INT | Customer ID (hash distribution key in Synapse). Renamed from `Function.CID`. | Dim_Position |
| `DateID` | INT | YYYYMMDD. DELETE/INSERT partition. | Function (open or close date) |
| `Date` | TIMESTAMP | `CONVERT(DATE, DateID, 112)`. | SP-derived |
| `InstrumentTypeID` | INT | 1=Forex, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. See [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) for the full map and TypeID 9 (Options) caveat. **Live data shows 9 has no rows in recent periods.** | Dim_Instrument via function |
| `IsSettled` | INT 0/1 | 1 = real asset (real stock, real crypto, real ETF, real futures — actual ownership). 0 = CFD (synthetic price exposure). Regulators track CFD vs real volume separately. | Dim_Position.IsSettled |
| `IsCopy` | INT 0/1 | `CASE WHEN Dim_Position.MirrorID > 0 THEN 1 ELSE 0`. Captures state AT OPEN (Warning #9). | function-computed |
| `IsBuy` | INT 0/1 | 1 = long, 0 = short. | Dim_Position.IsBuy |
| `IsLeverage` | INT 0/1 | **Note: no 'd' — see Warning #2.** `CASE WHEN Leverage > 1 THEN 1 ELSE 0`. | function-computed |
| `IsFuture` | INT 0/1 | Futures contract flag. | Dim_Instrument.IsFuture (GroupID=25) |
| `IsCopyFund` | INT 0/1 | 1 = Smart Portfolio (`MirrorTypeID = 4`). Distinct from `IsCopy` (which catches all copy types). | `BI_DB_CopyFund_Positions` lookup |
| `IsOpenedFromIBAN` | **STRING** `'0'`/`'1'` | 1 = position opened directly from the customer's eMoney IBAN/wallet. **Filter as `= '1'`!** | `BI_DB_Positions_Opened_From_IBAN` lookup |
| `IsClosedToIBAN` | **INT** 0/1 | 1 = position close proceeds went to the customer's eMoney IBAN. **Filter as `= 1`** (asymmetry with the opens flag!). | `BI_DB_Positions_Closed_To_IBAN` lookup |
| `IsRecurring` | INT 0/1 | 1 = auto-invest / Recurring Investment feature. | `BI_DB_RecurringInvestment_Positions` lookup |
| `IsAirDrop` | INT 0/1 | 1 = free promotional share (referral / campaign giveaway). | Dim_Position.IsAirDrop |
| `IsSQF` | INT 0/1 | "Sustainable & Quality-Focused" per DDR fact wiki; `Trade.InstrumentGroups GroupID = 59` per instruments wiki. **8 instruments total** flagged in the catalogue (Warning #10). | `Function_Instrument_Snapshot_Enriched` |
| `IsMarginTrade` | INT 0/1 | `CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0`. Margin-trading positions. | function-computed |
| `IsC2P` | INT 0/1 | "Copy-to-Portfolio" — position was migrated from a stopped copy relationship into the customer's own portfolio (kept the position, dropped the copy overhead). | `V_C2P_Positions` lookup |

### Asset class combos (live counts, April-May 2026)

| Asset class (TypeID, IsSettled) | Rows | TotalVolume | Asset class (TypeID, IsSettled) | Rows | TotalVolume |
|---|---:|---:|---|---:|---:|
| Real Stocks (5, 1) | 4.17M | 7.26B | CFD Stocks (5, 0) | 848K | 5.79B |
| Real Crypto (10, 1) | 763K | 501M | CFD Crypto (10, 0) | 86K | 162M |
| Real ETFs (6, 1) | 443K | 499M | CFD ETFs (6, 0) | 738K | 889M |
| Commodities CFD (2, 0) | 1.22M | 57.1B | Commodities Real (2, 1) | 2.5K | 524M |
| Indices CFD (4, 0) | 630K | 34.7B | Forex CFD (1, 0) | 163K | 10.8B |

**Live observations**: Commodities/Indices CFDs dominate notional (high leverage); Real Stocks have most rows (retail); Real Crypto >> CFD Crypto on row count (eToro crypto is now mostly real-custody); TypeID 9 (Options) has ZERO rows in recent data despite wiki claims.

---

## Query Patterns

### Pattern 1 — Total volume
```sql
SELECT SUM(TotalVolume) AS total_volume
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "total trading volume", "how much was traded?", "volume this quarter"

### Pattern 2 — Real vs CFD breakdown
```sql
SELECT IsSettled,
       SUM(TotalVolume) AS vol,
       SUM(InvestedAmountOpen) AS invested,
       COUNT(DISTINCT RealCID) AS traders
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY IsSettled;
```
**Use when:** "real vs CFD volume", "settled vs derivative", "how much is real assets?"

### Pattern 3 — Volume by instrument type
```sql
SELECT InstrumentTypeID, IsSettled,
       SUM(TotalVolume) AS volume,
       SUM(CountTotalTransactions) AS trades
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY InstrumentTypeID, IsSettled ORDER BY volume DESC;
```
**Use when:** "volume by asset class", "crypto vs stocks volume", "forex volume", "real vs CFD per asset class"

### Pattern 4 — Volume from a specific ticker (joins through enriched view)
```sql
SELECT f.etr_ym, SUM(f.TotalVolume) AS volume
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts f
JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i
  ON f.InstrumentTypeID = i.InstrumentTypeID    -- this fact has TypeID, not InstrumentID
WHERE i.Symbol LIKE 'TSLA%'
  AND i.InstrumentTypeID = 5
  AND i.IsFuture = 0
  AND i.Tradeable = 1
  AND f.etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY f.etr_ym
ORDER BY f.etr_ym;
```
**WARNING (Pattern 4 caveat)**: this fact aggregates by `InstrumentTypeID`, NOT by `InstrumentID`. **You cannot get per-ticker volume from this table directly** — only per-type. For per-ticker volume, route to `fact_customeraction_w_metrics` (see Pattern 4-alt below). Pattern 4 as shown returns the volume aggregate for the ASSET CLASS that contains the ticker, not the ticker itself.

### Pattern 4-alt — Per-ticker volume from the granular w_metrics fact
```sql
SELECT f.DateID,
       SUM(f.VolumeOpen)           AS notional_open,        -- leveraged notional from QA recomputation
       SUM(ABS(f.InvestedAmountIn)) AS cash_deployed_at_open -- unsigned capital deployed
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics f
JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i ON f.InstrumentID = i.InstrumentID
WHERE i.Symbol LIKE 'TSLA%'
  AND i.InstrumentTypeID = 5
  AND i.IsFuture = 0
  AND i.Tradeable = 1
  AND f.etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
  AND f.ActionTypeID IN (1, 2, 3, 39)   -- opening actions; see position-state-and-grain.md
GROUP BY f.DateID
ORDER BY f.DateID;
```
**Use when:** "Tesla trading volume", "BTC volume by month", "volume for ticker X" — the DDR fact aggregates at TypeID level, so per-ticker MUST go through `w_metrics`. **Always partition-prune on `etr_ymd`** (STRING `YYYY-MM-DD` on w_metrics).

### Pattern 5 — Active traders count (trade-based, NOT the official segment)
```sql
SELECT COUNT(DISTINCT RealCID) AS active_traders
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE CountOpenTransactions > 0
  AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "how many people traded?", "unique traders this quarter". **Not** the official Active Trader segment — for that route to `../domain-customer-and-identity/customer-populations-and-lifecycle.md`.

### Pattern 6 — Copy / Smart-Portfolio / C2P breakdown
```sql
SELECT IsCopy, IsCopyFund, IsC2P,
       SUM(TotalVolume) AS volume,
       SUM(CountTotalTransactions) AS trades,
       COUNT(DISTINCT RealCID) AS traders
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY IsCopy, IsCopyFund, IsC2P
ORDER BY IsCopy, IsCopyFund, IsC2P;
```
**Use when:** "fraction of volume from copy / Smart Portfolio / C2P", "manual vs copy split". Stack the three flags: `IsCopy=0, IsCopyFund=0, IsC2P=0` = pure manual; `IsCopy=1` includes both regular copy + CopyFund; `IsCopyFund=1` is the Smart Portfolio subset; `IsC2P=1` is the "kept after stopping copy" subset.

### Pattern 7 — IBAN-originated trade volume (note the STRING!)
```sql
SELECT etr_ym, SUM(TotalVolume) AS iban_volume
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE IsOpenedFromIBAN = '1'   -- STRING, not INT!
  AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY etr_ym
ORDER BY etr_ym;

-- And the close-side, which is INT (asymmetry!):
SELECT etr_ym, SUM(TotalVolume) AS iban_close_volume
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE IsClosedToIBAN = 1       -- INT, not STRING!
  AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY etr_ym
ORDER BY etr_ym;
```
**Use when:** "IBAN trade volume", "volume opened from wallet", "volume closed to wallet". Compare both: net IBAN flow into trading = `IsOpenedFromIBAN='1'` - `IsClosedToIBAN=1`.

### Pattern 8 — Net invested amount trend
```sql
SELECT etr_ym, SUM(NetInvestedAmount) AS net_invested
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-12-31'
GROUP BY etr_ym
ORDER BY etr_ym;
```
**Use when:** "are customers deploying or repatriating capital?", "net investment flow trend"

### Pattern 9 — Leverage / direction / margin breakdown (DDR fact)
```sql
SELECT IsLeverage, IsBuy, IsMarginTrade,
       SUM(TotalVolume) AS volume,
       SUM(CountTotalTransactions) AS trades
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
  AND InstrumentTypeID = 5     -- e.g. stocks only
GROUP BY IsLeverage, IsBuy, IsMarginTrade
ORDER BY volume DESC;
```
**Use when:** "leveraged vs unleveraged volume", "long vs short stock volume", "margin trade volume". Remember `IsLeverage` has no 'd' — Warning #4.

### Pattern 10 — Authoritative cash-flow accounting from w_metrics (signed)
```sql
SELECT etr_ym,
       SUM(InvestedAmountIn)                       AS net_cash_deployed,   -- NEGATIVE: wallet → positions
       SUM(InvestedAmountOut)                      AS net_cash_returned,   -- POSITIVE: positions → wallet
       SUM(InvestedAmountIn) + SUM(InvestedAmountOut) AS net_wallet_flow,  -- + = customers net pulled out; - = net deployed
       SUM(VolumeOpen)  AS notional_opened,
       SUM(VolumeClose) AS notional_closed
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
  AND ActionTypeID IN (1, 2, 3, 4, 5, 6, 28, 39, 40)   -- opens and closes only
GROUP BY etr_ym
ORDER BY etr_ym;
```
**Use when:** "what was the actual cash flow between wallets and positions?", "did customers deploy or repatriate capital?", "wallet-to-trading book net flow". **This is the truthful version** — it uses `Fact_CustomerAction.Amount` (signed from `History.Credit`) and answers in real-cash-flow terms. The DDR fact's `NetInvestedAmount` is the closest equivalent but it uses `Dim_Position.Amount` (original investment) for closes, so it understates the cash returned on profitable closes and overstates on losers — see Warning #1.

### Pattern 11 — Reconcile DDR `InvestedAmountClosed` against w_metrics `InvestedAmountOut`
```sql
-- Sanity check: does the DDR fact agree with the authoritative source today?
WITH wm AS (
    SELECT DateID,
           SUM(InvestedAmountOut) AS wm_out_signed,
           SUM(ABS(InvestedAmountOut)) AS wm_out_abs
    FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
    WHERE etr_ymd BETWEEN '2026-05-01' AND '2026-05-07'
      AND ActionTypeID IN (4, 5, 6, 28, 40)
    GROUP BY DateID
),
ddr AS (
    SELECT DateID, SUM(InvestedAmountClosed) AS ddr_closed
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
    WHERE etr_ymd BETWEEN '2026-05-01' AND '2026-05-07'
    GROUP BY DateID
)
SELECT wm.DateID,
       wm.wm_out_abs                AS w_metrics_cash_returned,
       ddr.ddr_closed               AS ddr_original_capital_in_closed_positions,
       ddr.ddr_closed - wm.wm_out_abs AS diff_realized_pnl_approx
FROM wm
LEFT JOIN ddr USING (DateID)
ORDER BY DateID;
```
**Use when:** auditing the divergence, presenting the case for the DDR rebuild, validating that today's data still shows the expected divergence pattern (negative `diff` = customers net profitable on closes that day; positive `diff` = customers net lost on closes).

---

## Cross-references

- Instrument filter rules (used by Pattern 4-alt) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Position state, copy detection at the row level → [`position-state-and-grain.md`](position-state-and-grain.md)
- End-of-day stock (AUM, NOP, equity) → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Revenue from these trades → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Official Active Trader segment → `../domain-customer-and-identity/customer-populations-and-lifecycle.md`
- Margin-trade economics, the `SettlementTypeID = 5` rule → `position-state-and-grain.md` (SettlementTypeID map)

## Sources Consulted (per `/speckit.skill` Phase 2.5)

`Class`: S = Synapse-first, H = Hybrid (lake-built on top of DWH). `Tier`: 1a wiki, 1b UC comment, 2 view definition, 3 SP/lineage, 4 live distincts/sample. All UC reads dated 2026-05-11.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| w_metrics | H | 2 | live `information_schema.views.view_definition` for `v_fact_customeraction_w_metrics` + `v_fact_customeraction_enriched` | Full lineage chain captured. Reveals `InvestedAmountIn/Out = fca.Amount` (signed) split by ActionTypeID and `VolumeOpen/Close = VolumeOnOpen/OnClose` from enriched view, with `VolumeOnOpen = CAST(ROUND(InitialUnits * InitForexRate * InitConversionRate) AS DECIMAL(38,6))`. PASSIVE actions (35, 32, 19, 36 w/ CompReason 56/117/118) zero out volume to prevent agg dup. Filter: `ActionTypeID NOT IN (14, 41)`. |
| w_metrics | H | 1b + 4 | UC `DESCRIBE TABLE EXTENDED` + live agg by ActionTypeID + day | Full schema (98 data + 3 partition cols), Delta, EXTERNAL, deletion vectors. Types: `InvestedAmountIn/Out` DECIMAL(12,2); `VolumeOpen/Close` DECIMAL(38,6); `IsBuy` BOOLEAN. 9.1B rows; date range 2007-08-27 → 2026-05-10; etr_ymd STRING `YYYY-MM-DD`. **Signed convention confirmed**: ActionTypeID 1 (-$205.3M), 2 (-$21.5M), 3 (-$1.2K) opens; 4 (+$222.6M), 5 (+$19.7M), 6 (+$0.18M) closes (2026-05-01). |
| Fact_CustomerAction (upstream) | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md | 407 lines, 71 cols. Canonical ActionTypeID map. Wiki claims `Amount >= 0`; live UC `fact_customeraction.Amount` carries signed values per ActionTypeID — wiki text predates lake-side enrichment. **Operational stance**: trust live signed values. |
| DDR fact | S | 1a | knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.{md,lineage.md} + Functions/Function_Trading_Volume_PositionLevel.md | 25-col reference; SP_DDR + Function_Trading_Volume_PositionLevel pipeline; SP authored 2025-04-20; IsSQF (2025-06), IsMarginTrade (2025-10), IsC2P (2025-12) additions. The TVF is source of `IsLeverage`/`IsCopy`/`IsMarginTrade` derivations AND the critical `InvestedAmountClosed = CAST(Dim_Position.Amount AS FLOAT)` formula that drives Warning #1. |
| DDR fact | S | 1b | UC `information_schema.columns` (live) | 30 cols (27 data + 3 partition). Type asymmetry confirmed: `IsOpenedFromIBAN`=STRING / `IsClosedToIBAN`=INT. BIGINT volumes vs DECIMAL(19,4) money. `etr_ymd` STRING `YYYY-MM-DD` despite `DateID` INT `YYYYMMDD`. |
| Reconciliation | H | 4 | UC live cross-join (DDR vs w_metrics) for 2026-05-01..05-07 + per-position drill-down | **The smoking gun.** Day-by-day invested-amount-close gap up to $11.45M (2026-05-04); positive-gap pattern dominant in May 2026 (bull-market profit harvesting). Volume diffs <$20K on $1.9B daily flow. Open `InvestedAmount*` diffs <$3.3K (rounding). Per-position spot check (PositionID=906066878 close 2026-05-01): w_metrics.InvestedAmountOut=$323.98 (close cash) vs dim_position.Amount=$600.00 (open cash); InitialUnits=AmountInUnitsDecimal=1.306307 (full close, not partial) — confirms DDR uses dim, w_metrics uses fca.Amount. |

## Provenance

v3 (2026-05-11) — major content correction per user direction *"take a hard look at the w_metrics lineage in UC for volume and amounts — its the best source so if you see conflicts — its the best one (invested amount close calculation is somewhat different). when we switch ddr build to dbx sp, it will also correct it there".*

**v2 → v3 deltas**:

- Description rewritten to lead with the two-anchor model (w_metrics authoritative + DDR convenient) and the semantic divergence.
- `+10` new triggers (`InvestedAmountIn`/`Out`, `cash deployed`/`returned`, `wallet flow`, `signed flow`, `QA recomputed volume`, `w_metrics`, `fact_customeraction_w_metrics`, `VolumeOnOpen`/`Close`); `required_tables` now leads with `de_output_etoro_kpi_fact_customeraction_w_metrics` + the source view.
- Critical Warnings expanded from 12 to 15, with two NEW Tier 1 at the top — **#1 w_metrics authoritative / DDR `InvestedAmountClosed` semantic divergence** (live multi-day diff table; planned DBX SP rebuild) and **#2 signed wallet-flow convention**. Warnings #7 (cross-anchor type quirks) and #8 (QA-recomputed vs persisted Volume) also new.
- New top-level "w_metrics lineage chain" section with full ASCII derivation flow.
- Tables section restructured as comparative table; Pattern 4-alt fixed (broken column names → actual `VolumeOpen`/`InvestedAmountIn`); Pattern 10 NEW (authoritative cash-flow accounting); Pattern 11 NEW (DDR vs w_metrics reconciliation audit).
- Sources Consulted expanded 4 → 9 entries with live view definitions, schema EXTENDED, signed-convention sample, reconciliation cross-join, per-position drill-down.

**v1 → v2 (2026-05-11)**: incorporated DE workspace-root skill + BI_DB DDR fact wiki + Function_Trading_Volume_PositionLevel wiki + live UC schema/distinct verifications. Added IsOpenedFromIBAN/IsClosedToIBAN type asymmetry, IsLeverage naming quirk, TotalVolume ≠ SUM aggregation, BIGINT vs DECIMAL(19,4) types, IsSQF ambiguity, BI_DB_VolumeQA dump (Synapse-only). 6 new dimension columns documented. Live asset-class row-count table. Pattern 4-alt + 6 + 9 added.
