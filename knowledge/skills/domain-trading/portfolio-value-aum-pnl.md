---
name: domain-trading
description: "End-of-day portfolio snapshots and daily PnL deltas across the trading platform. Two DDR fact tables: BI_DB_DDR_Fact_AUM (43 columns, 7.4B rows, 1 row per customer per day = end-of-day snapshot across TP + IBAN + Options) and BI_DB_DDR_Fact_PnL (18 columns, 8.8B rows, 1 row per customer × date × InstrumentTypeID × 8 position flags = daily delta). Covers the snapshot-vs-delta aggregation rule (never SUM AUM across dates; PnL deltas DO sum), the TP-vs-Global naming convention (TotalEquityTP = TP only; EquityGlobal = TP + IBAN + Options), copy vs manual stock/crypto equity decomposition (EquityCopy / EquityStocksManual / EquityCryptoManual), the NOP-sub-columns-don't-sum gotcha (only 4 sub-columns: NOPCrypto, NOPCryptoCFD, NOPStocks, NOPStocksCFD — Forex/Commodities/Indices/ETFs missing), the IsLeveraged/IsLeverage cross-table naming inconsistency, the zero-equity-row-exclusion filter, the ActualNWA bonus-cap formula, the Options data-lag caveat, and the legacy-always-zero columns (CopyStockOrders, StockOrders — 0 since 2019)."
triggers:
  - equity
  - NOP
  - net open position
  - portfolio value
  - account value
  - total equity
  - RealizedEquityTP
  - RealizedEquityGlobal
  - market exposure
  - NOPCrypto
  - NOPStocks
  - unrealized PnL
  - paper gains
  - paper losses
  - realized PnL
  - daily PnL
  - copy equity
  - EquityCopy
  - InProcessCashout
  - TotalPositionPNL
  - UnrealizedPnLChange
  - NetProfit
  - CountPositions
  - mark to market
  - ActualNWA
  - bonus credit
  - manual stock equity
  - manual crypto equity
  - IsLeveraged
  - CreditTP
  - CreditGlobal
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Portfolio Value — AUM, NOP & PnL

The trading platform's end-of-day state lives in **two** DDR fact tables, and the difference between them is the difference between a *snapshot* and a *delta*. The **AUM fact** stores 1 row per customer per day = end-of-day state across **all eToro platforms** (Trading Platform + IBAN/eMoney + Options/Apex). The **PnL fact** stores 1 row per customer × date × `InstrumentTypeID` × 8 flags = the daily *change* in unrealized PnL and the daily realized profit. Mixing them up — summing AUM across dates, summing daily PnL changes only on a single date — is the most common analytical mistake on this dataset.

**Side classification**: **broker-side**. Both tables are derived from broker-side artifacts (`BI_DB_Client_Balance_CID_Level_New`, `V_Liabilities`, `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument`). The IBAN balance comes from `eMoney_dbo.eMoneyClientBalance` (also broker-side — it's the customer-visible eMoney wallet). The Options equity comes from `External_Sodreconciliation_apex_EXT981_BuyPowerSummary` — an *Apex broker-side* sync, not a dealer-side execution feed.

## When to Use

Load when the question is about:

- "What's our AUM?", "total platform equity", "how much do customers hold?" (use `EquityGlobal` for the multi-platform total; `TotalEquityTP` for TP only)
- "NOP trend this month", "market exposure over time"
- "PnL by asset class", "which instruments are profitable?", "crypto unrealized PnL"
- "How much is in copy?", "copy vs manual stock equity", "copy vs manual crypto equity"
- "Pending cashouts", "InProcessCashout total"
- "Bonus credit currently outstanding", "ActualNWA" (bonus-capped net worth)
- "IBAN balance trend", "Options/Apex equity trend"
- "Real vs CFD AUM" (`TotalRealCrypto` / `TotalRealStocks` cuts vs total)
- Any question about end-of-day portfolio state or daily profit/loss changes

Do **not** load for:

- Position state at open / lifecycle / MirrorID-at-open → [`position-state-and-grain.md`](position-state-and-grain.md)
- Daily flow / capital deployment (`InvestedAmountOpen` as a flow, not a stock) → [`trading-volumes.md`](trading-volumes.md)
- The official "funded customer" segment definition (`TotalEquityTP > $X` threshold) → `../domain-customer-and-identity/customer-populations-and-lifecycle.md`
- Per-trade revenue / fees → `domain-revenue-and-fees`
- Filtering by ticker (the two-part instrument-filter rule is owned elsewhere) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Spaceship / MoneyFarm AUM (those are acquired-platform products with separate facts) → `domain-revenue-and-fees` per-product sub-skills
- Apex stock-options trading P&L decomposition → not exposed in DDR; trade-level Options PnL lives in External_Sodreconciliation_apex_*

## Scope

In scope: end-of-day snapshot (43 AUM columns), daily PnL delta (18 PnL columns), the 9 PnL dimension flags (`InstrumentTypeID`, `IsCopy`, `IsSettled`, `IsFuture`, `IsLeveraged`, `IsBuy`, `IsCopyFund`, `IsSQF`), TP-vs-Global column conventions, copy-vs-manual equity decomposition (`EquityCopy`, `EquityStocksManual`, `EquityCryptoManual`), the partition mismatch (AUM uses `DateID` integer; PnL uses `etr_ymd` string partition), the snapshot-vs-delta aggregation rule, NOP sub-column completeness caveat (only 4 of 6 asset classes covered), the `IsLeveraged`/`IsLeverage` cross-table naming inconsistency, the legacy-always-zero columns, the zero-equity-row exclusion filter, the Options date-lag caveat, the multi-source `FULL OUTER JOIN` semantics on CID.

Out of scope: position-event detail (`position-state-and-grain.md`), volume / invested flow (`trading-volumes.md`), funded population segment (`../domain-customer-and-identity/customer-populations-and-lifecycle.md`), revenue (`domain-revenue-and-fees`), acquired-platform AUM (Spaceship/MoneyFarm — separate facts under `domain-revenue-and-fees`), trade-level Apex Options P&L decomposition.

Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `SUM(TotalEquityTP)` across multiple `DateID`s gives N× actual AUM.** AUM is *snapshot* data — one row per (customer, date) is the customer's full equity at end-of-day. Summing across N days inflates the total N times. Use a single `DateID` or compute `AVG(per-date total)` for an average. **Same rule applies to every column on the AUM fact** — NOP, TotalInvestedAmount, TotalPositionPNL, EquityCopy, EquityGlobal, IBANBalance, OptionsTotalEquity, ActualNWA, InProcessCashout — all snapshots, all break under `SUM` across dates.

2. **Tier 1 — `EquityGlobal ≠ TotalEquityTP`. The TP-vs-Global naming convention is load-bearing.** Columns ending in `*TP` are Trading Platform only. Columns ending in `*Global` aggregate across TP + IBAN/eMoney + Options/Apex. The full equation: `EquityGlobal = TotalEquityTP + IBANBalance + OptionsTotalEquity`. For total platform AUM headline numbers, use `EquityGlobal`. For TP-only metrics, use `TotalEquityTP`. **Watch out**: `RealizedEquityGlobal = RealizedEquityTP + IBANBalance` only (Options *excluded*, because Options cannot differentiate invested vs PnL). `CreditGlobal = CreditTP + IBANBalance + OptionsCashEquity` (uses options *cash* component, not total).

3. **Tier 1 — `UnrealizedPnLChange` is today's CHANGE only; `TotalPositionPNL` is cumulative.** `UnrealizedPnLChange` (PnL fact) = day-over-day mark-to-market movement. `TotalPositionPNL` (AUM fact) = total unrealized PnL across all open positions, cumulative. To answer "total unrealized PnL right now" use `TotalPositionPNL` from the AUM fact at the latest DateID. To answer "unrealized PnL gained this month" use `SUM(UnrealizedPnLChange)` from the PnL fact across the date range — that does sum because it's a delta.

4. **Tier 1 — Partition mismatch: AUM uses `DateID` (INT, YYYYMMDD); PnL uses `etr_ymd` (STRING partition).** When joining the two facts on (CID, date), you have to bridge the partition forms — `WHERE a.DateID = CAST(REPLACE(p.etr_ymd, '-', '') AS INT)` — and remember neither side has the other's partition column. Authoring queries that span both tables: always filter EACH side with its own partition column for performance.

5. **Tier 1 — `NOPCrypto + NOPCryptoCFD + NOPStocks + NOPStocksCFD ≠ NOP`.** The AUM fact has only **4 NOP sub-columns** — Crypto, CryptoCFD, Stocks, StocksCFD. **Forex, Commodities, Indices, ETF NOP exposure is MISSING from the sub-columns**. Use `NOP` directly for total exposure. Use the sub-columns only when you specifically want a single-class breakdown and accept that "everything else" is not represented.

6. **Tier 2 — `IsLeveraged` (with 'd') in the PnL fact vs `IsLeverage` (no 'd') in the volumes fact.** Same semantics (`CASE WHEN Leverage > 1`), different spellings. If you copy a query from `trading-volumes.md`, **rename `IsLeverage` → `IsLeveraged`** when you bring it to the PnL fact. See [`trading-volumes.md`](trading-volumes.md) Warning #2 for the reverse.

7. **Tier 2 — The AUM table EXCLUDES rows where `EquityGlobal = 0`.** `SP_DDR_Fact_AUM` filters `WHERE NOT (EquityGlobal = 0)` before insert. `COUNT(DISTINCT RealCID) WHERE DateID = X` is NOT total customers — it's customers with non-zero global equity. For a true "funded customer" count, use the official segment definition in `../domain-customer-and-identity/customer-populations-and-lifecycle.md`.

8. **Tier 2 — `CopyStockOrders` and `StockOrders` are always 0 since 2019** — legacy columns retained for schema stability. Don't reference them in new queries.

9. **Tier 2 — `IBANBalance` is USD-converted via `USDApproxRate`, not spot rate.** Sourced as `SUM(ClosingBalanceBO × USDApproxRate)` from `eMoneyClientBalance`. For tight FX reconciliation, query `eMoneyClientBalance` directly with `eMoney_dbo.spot_rate_table` instead of relying on this column. Excludes GCID=0 and NULL GCID rows.

10. **Tier 2 — Options/Apex date lag: `OptionsTotalEquity` uses the latest available Apex date ≤ @dateID.** If Apex's daily sync is late, today's Options equity may be yesterday's number. The wiki claim: "may lag by 1+ days." Excludes house accounts (`4GS43999`, `4GS00100-104`).

11. **Tier 3 — `TotalEquityTP = SUM(TotalLiability + ActualNWA)` per CID/DateID** — not a raw passthrough. `ActualNWA` (Non-Withdrawable Amount) is bonus-capped net worth: `CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END`. This is the formula that drives "what the customer can withdraw" calculations.

12. **Tier 3 — PnL fact wiki has an InstrumentTypeID typo: it claims `6=Commodities, 12=ETFs, 73=Currencies`.** This is WRONG. The canonical map (live-verified in [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)) is `1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto`. Both the AUM and PnL DDR facts use this canonical map (via join to `Dim_Instrument`). When in doubt, join to the enriched view and let it resolve.

13. **Tier 3 — AUM table is ~7.4B rows, PnL fact is ~8.8B rows.** ALWAYS filter by `DateID` (AUM) or `etr_ymd` / `DateID` (PnL). Both facts span 2007-present (pre-DDR data backfilled when the DDR framework was created in July 2024).

## Tables

| Table | Rows | Grain | Partitions | Use For |
|---|---|---|---|---|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | ~7.4B | 1 row per customer × `DateID` = end-of-day snapshot | **none** (use `DateID` INT) | Equity, NOP, invested, unrealized PnL (cumulative), copy equity decomposition, IBAN balance, Options equity, pending cashouts, bonus, ActualNWA |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | ~8.8B | 1 row per customer × `DateID` × `InstrumentTypeID` × 8 flags = daily delta | `etr_y`, `etr_ym`, `etr_ymd` (STRING) | Daily PnL changes (unrealized + realized) — DOES sum across dates |

---

## AUM column reference (43 columns)

### TP balance metrics (from `BI_DB_Client_Balance_CID_Level_New`)

| Column | Type | What it is |
|---|---|---|
| `RealizedEquityTP` | DECIMAL(16,6) | TP realized equity (cash + closed PnL; excludes unrealized) |
| `TotalLiabilityTP` | DECIMAL(16,6) | TP total liability |
| `InProcessCashout` | DECIMAL(16,6) | TP in-process cashout amount (pending withdrawal at EOD) |
| `NOP` | DECIMAL(16,6) | Net Open Position — total notional exposure from open positions |
| `NOPCrypto`, `NOPCryptoCFD`, `NOPStocks`, `NOPStocksCFD` | DECIMAL(16,6) | NOP for those 4 asset slices. **Do NOT sum to NOP** (Warning #5). |
| `TotalRealCryptoLoan` | DECIMAL(16,6) | Real crypto loan amount |
| `TotalPositionPNL` | DECIMAL(16,6) | **Total unrealized PnL, CUMULATIVE** across all open positions (use this — not `UnrealizedPnLChange` from the PnL fact — for "total unrealized PnL right now") |
| `TotalInvestedAmount` | DECIMAL(16,6) | Capital allocated to open positions (pre-leverage) |
| `TotalEquityTP` | DECIMAL(16,6) | TP total equity = `SUM(TotalLiability + ActualNWA)` |
| `Bonus` | DECIMAL(16,6) | Promotional bonus amount |

### Copy / Stock / Crypto equity decomposition (from `V_Liabilities`)

| Column | Type | What it is |
|---|---|---|
| `CashInCopy` | DECIMAL | Cash allocated to copy trades (= TotalMirrorCash) |
| `CopyInvestedAmount` | DECIMAL | Invested amount in copy (= TotalMirrorPositionsAmount) |
| `CopyStockOrders` | DECIMAL | **Legacy — always 0 since 2019** (Warning #8) |
| `CopyPositionPnL` | DECIMAL | Unrealized PnL on copy positions |
| `EquityCopy` | DECIMAL | **Total copy equity** = CashInCopy + CopyInvestedAmount + CopyStockOrders + CopyPositionPnL |
| `InvestedAmountCopy` | DECIMAL | EquityCopy excluding cash (the "non-cash" copy capital) |
| `StockInvestedAmount` | DECIMAL | Total stock position amount (real + copy) |
| `StockOrders` | DECIMAL | **Legacy — always 0 since 2019** (Warning #8) |
| `StocksPositionPnL` | DECIMAL | Unrealized PnL on stock positions (real + copy) |
| `MirrorStockInvestedAmount` | DECIMAL | Stock invested via copy trades |
| `MirrorStocksPositionPnL` | DECIMAL | Stock unrealized PnL via copy trades |
| `EquityStocksManual` | DECIMAL | Manual (non-copy) stock equity = `StockInvested + StockOrders + StocksPnL - MirrorStockInvested - MirrorStocksPnL` |
| `InvestedAmountStocksManual` | DECIMAL | Manual stock invested = `StockInvested + StockOrders - MirrorStockInvested` |
| `InvestedAmountCryptoManual` | DECIMAL | Manual crypto invested = total - mirror crypto |
| `CryptoManualPositionPnL` | DECIMAL | Manual crypto unrealized PnL |
| `EquityCryptoManual` | DECIMAL | Manual crypto total equity |
| `TotalRealCrypto` | DECIMAL | Total real (non-CFD) crypto position amount |
| `TotalRealStocks` | DECIMAL | Total real (non-CFD) stock position amount |
| `CreditTP` | DECIMAL | TP promotional credit |
| `ActualNWA` | DECIMAL | Non-Withdrawable Amount, bonus-capped net worth (Warning #11) |

### Multi-platform extensions

| Column | Type | What it is |
|---|---|---|
| `IBANBalance` | DECIMAL | eMoney IBAN balance in USD (FX-converted, not spot — Warning #9) |
| `RealizedEquityGlobal` | DECIMAL | `RealizedEquityTP + IBANBalance` (Options EXCLUDED — Warning #2) |
| `TotalLiabilityGlobal` | DECIMAL | `TotalLiabilityTP + IBANBalance + OptionsTotalEquity` |
| `EquityGlobal` | DECIMAL | `TotalEquityTP + IBANBalance + OptionsTotalEquity` (the **true total AUM**) |
| `CreditGlobal` | DECIMAL | `CreditTP + IBANBalance + OptionsCashEquity` (uses options *cash*, not total) |
| `OptionsTotalEquity` | DECIMAL(18,6) | Apex options total equity, latest available ≤ DateID (Warning #10) |

---

## PnL column reference (18 columns)

### Dimensions (9)

| Column | Type | Notes |
|---|---|---|
| `DateID` | INT | YYYYMMDD. DELETE/INSERT key. |
| `Date` | TIMESTAMP | Same as DateID, as DATE type |
| `RealCID` | INT | Customer ID. Hash distribution key in Synapse. |
| `InstrumentTypeID` | INT | Use canonical map from [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) (Warning #12 — wiki typo). |
| `IsCopy` | INT 0/1 | `CASE WHEN MirrorID > 0`. State at open. |
| `IsSettled` | INT 0/1 | 1=real, 0=CFD. |
| `IsFuture` | INT 0/1 | `ISNULL(IsFuture, 0)`. |
| `IsLeveraged` | INT 0/1 | **`CASE WHEN Leverage > 1`. With 'd' — Warning #6.** |
| `IsBuy` | INT 0/1 | 1=long, 0=short. |
| `IsCopyFund` | INT 0/1 | Smart Portfolio (`MirrorTypeID = 4`). Independent from IsCopy. |
| `IsSQF` | INT 0/1 | "Sustainable & Quality-Focused" instrument (8 instruments — see `instruments-and-asset-classes.md`). |

### Measures (3)

| Column | Type | What it is |
|---|---|---|
| `UnrealizedPnLChange` | DECIMAL(16,6) | Day-over-day mark-to-market delta. **DOES sum across dates.** |
| `NetProfit` | DECIMAL(16,6) | Realized profit from positions closed on this date. **Zero for groups with no closes.** |
| `CountPositions` | INT | Count of positions contributing to this row. `COUNT(PositionID)` within the group. |

### Snapshot vs delta — the unit cheat-sheet

| Source | Type | Aggregation rule | Example question |
|---|---|---|---|
| `TotalEquityTP` (AUM) | Snapshot | Single date, or AVG over dates | "AUM on March 1" / "avg AUM in March" |
| `EquityGlobal` (AUM) | Snapshot | Single date, or AVG over dates | "Total AUM today including IBAN + Options" |
| `NOP` (AUM) | Snapshot | Single date, or AVG over dates | "NOP today" / "avg NOP this week" |
| `TotalPositionPNL` (AUM) | Snapshot | Single date, or AVG over dates | "Total unrealized PnL right now" |
| `IBANBalance`, `OptionsTotalEquity` (AUM) | Snapshot | Single date, or AVG over dates | "IBAN cash held this week" |
| `UnrealizedPnLChange` (PnL) | Delta | SUM across rows + dates | "Unrealized PnL gained this month" |
| `NetProfit` (PnL) | Delta | SUM across rows + dates | "Realized profit this quarter" |
| `CountPositions` (PnL) | Snapshot-of-day (count) | Single date, or AVG over dates | "How many positions held on date X" |

---

## Query Patterns

### Pattern 1 — Total platform AUM (Global vs TP split)
```sql
SELECT SUM(EquityGlobal)       AS aum_global,
       SUM(TotalEquityTP)      AS aum_tp,
       SUM(IBANBalance)        AS aum_iban,
       SUM(OptionsTotalEquity) AS aum_options,
       COUNT(DISTINCT RealCID) AS active_customers
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260401;
```
**Use when:** "what's our AUM today?", "total platform equity", "AUM breakdown across TP/IBAN/Options"

### Pattern 2 — AUM and NOP time series
```sql
SELECT DateID,
       SUM(EquityGlobal)       AS aum_global,
       SUM(NOP)                AS nop,
       SUM(TotalPositionPNL)   AS unrealized_pnl_cum,
       SUM(InProcessCashout)   AS pending_cashouts,
       COUNT(DISTINCT RealCID) AS customers
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID BETWEEN 20260301 AND 20260331
GROUP BY DateID
ORDER BY DateID;
```
**Use when:** "AUM trend", "equity over time", "NOP trend this month". Each row is a snapshot at that DateID; do NOT sum across dates.

### Pattern 3 — Copy / Manual / Real stock+crypto equity split
```sql
SELECT SUM(EquityCopy)             AS copy_eq,
       SUM(EquityStocksManual)     AS manual_stocks_eq,
       SUM(EquityCryptoManual)     AS manual_crypto_eq,
       SUM(TotalRealCrypto)        AS real_crypto_amt,
       SUM(TotalRealStocks)        AS real_stocks_amt,
       SUM(TotalEquityTP)          AS tp_total
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260401;
```
**Use when:** "how much is in copy?", "manual stocks vs copy stocks split", "real assets exposure"

### Pattern 4 — PnL by instrument type (daily)
```sql
SELECT InstrumentTypeID,
       SUM(UnrealizedPnLChange) AS unrealized_change,
       SUM(NetProfit) AS realized,
       SUM(CountPositions) AS positions
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE etr_ymd = '2026-04-01'
GROUP BY InstrumentTypeID
ORDER BY realized DESC;
```
**Use when:** "PnL by asset class today", "which instruments are profitable?"

### Pattern 5 — PnL trend over a quarter
```sql
SELECT etr_ym,
       SUM(UnrealizedPnLChange) AS unrealized_quarterly,
       SUM(NetProfit)           AS realized_quarterly,
       SUM(UnrealizedPnLChange + NetProfit) AS total_pnl_quarterly
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY etr_ym
ORDER BY etr_ym;
```
**Use when:** "PnL trend this quarter", "monthly profit summary". Deltas DO sum.

### Pattern 6 — Per-customer PnL detail (drill-down)
```sql
SELECT DateID,
       SUM(UnrealizedPnLChange) AS unrealized_delta,
       SUM(NetProfit) AS realized,
       SUM(UnrealizedPnLChange + NetProfit) AS total_pnl,
       SUM(CountPositions) AS positions
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE RealCID = 12345678
  AND etr_ymd BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY DateID
ORDER BY DateID;
```
**Use when:** "show me customer X's PnL last month", "drill-down a customer's daily performance"

### Pattern 7 — Copy / Smart Portfolio / Leveraged PnL breakdown
```sql
SELECT IsCopy, IsCopyFund, IsLeveraged,
       SUM(UnrealizedPnLChange) AS unrealized_change,
       SUM(NetProfit) AS realized,
       SUM(CountPositions) AS positions
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
  AND InstrumentTypeID = 10              -- e.g. crypto only
GROUP BY IsCopy, IsCopyFund, IsLeveraged
ORDER BY realized DESC;
```
**Use when:** "is copy or manual more profitable on crypto?", "Smart Portfolio vs regular copy PnL". Remember `IsLeveraged` has the 'd' here (Warning #6).

### Pattern 8 — Pending cashouts + bonus exposure
```sql
SELECT SUM(InProcessCashout) AS pending_cashouts,
       SUM(Bonus)            AS outstanding_bonus,
       SUM(ActualNWA)        AS withdrawable_bonus_capped
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260401;
```
**Use when:** "pending withdrawals", "bonus liability", "what's the bonus-capped withdrawable amount?"

### Pattern 9 — PnL for a specific ticker (joins through enriched view)
```sql
-- NOTE: the PnL fact aggregates by InstrumentTypeID, NOT InstrumentID.
-- For per-ticker PnL, route through the granular fact (fact_customeraction_w_metrics)
-- and use the metrics columns there. The DDR PnL fact can only give per-type cuts.
SELECT InstrumentTypeID,
       SUM(UnrealizedPnLChange) AS unrealized_delta,
       SUM(NetProfit) AS realized
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE InstrumentTypeID = 5     -- Stocks (use the canonical map; see Warning #12)
  AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY InstrumentTypeID;
```
**Use when:** "Stock PnL this quarter", "Crypto realized profit". Like the volumes fact (`trading-volumes.md` Pattern 4-alt), per-ticker requires the granular fact.

---

## Cross-references

- Instrument filter rules (for any per-ticker question) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Position state, copy detection at the row level → [`position-state-and-grain.md`](position-state-and-grain.md)
- Volume / invested flow (vs end-of-day stock) → [`trading-volumes.md`](trading-volumes.md)
- Revenue from these positions → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Cashout / withdrawal flow → [`../domain-payments/SKILL.md`](../domain-payments/SKILL.md)
- IBAN/eMoney balance source (the raw eMoneyClientBalance, with proper FX) → `domain-payments` (IBAN sub-skill)
- Funded segment definition → `../domain-customer-and-identity/customer-populations-and-lifecycle.md`

## Sources Consulted (per `/speckit.skill` Phase 2.5)

`Class`: S = Synapse-first. `Tier`: 1a wiki, 1b UC comment, 3 lineage, 4 live distincts.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| BI_DB_DDR_Fact_AUM | S | 1a | knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_AUM.{md,lineage.md} | 43-col reference; SP_DDR_Fact_AUM + 4 source pipelines (Client_Balance, V_Liabilities, eMoneyClientBalance, Function_AUM_OptionsPlatform); zero-equity exclusion; FULL OUTER JOIN semantics; ActualNWA formula |
| BI_DB_DDR_Fact_PnL | S | 1a | knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_PnL.{md,lineage.md} | 18-col reference; Function_PnL_Single_Day → BI_DB_PositionPnL → Dim_Position/Dim_Instrument; 9-dim GROUP BY; ISNULL coercion on IsFuture/IsCopyFund/IsSQF; **wiki has InstrumentTypeID typo** (says 6=Commodities/12=ETFs/73=Currencies — wrong) |
| Both | S | 1b | UC information_schema.columns (live) | AUM 43 cols; PnL 18 + 3 partition cols (etr_y/etr_ym/etr_ymd). All DECIMAL measures, no `Tier 1` UC comments (per-column wiki refs are kept in the Synapse wiki) |
| Both | - | 4 | UC SELECT counts (April 2026 sample) | AUM: 4.4M rows for DateID=20260401 (= active-equity customer count for that day). PnL: row count via etr_ymd needs date-format care (string `YYYY-MM-DD` not `YYYYMMDD`). Both facts span 2007-present (backfilled). |

## Provenance

v2 rebuilt 2026-05-11 per `/speckit.skill` Phase 2.5. Deeply incorporates the DE workspace-root skill `portfolio-value` (v2 from 2026-05-07) and adds two heavy new content sources: the BI_DB DDR AUM fact wiki (43 cols vs the 10 in the original) and the BI_DB DDR PnL fact wiki (18 cols vs the 2 in the original). **Key v2 additions vs v1**: full TP-vs-Global naming-convention exposition (Warning #2); `EquityGlobal` as the "true total AUM" anchor; the `IBANBalance` / `OptionsTotalEquity` multi-platform structure; the FULL OUTER JOIN semantics + zero-equity-row exclusion (Warning #7); `ActualNWA` bonus-cap formula (Warning #11); the partition mismatch between AUM (`DateID` INT) and PnL (`etr_ymd` STRING) (Warning #4); the PnL wiki's `InstrumentTypeID` typo (Warning #12 — defer to instruments-and-asset-classes.md); `CopyStockOrders`/`StockOrders` always-zero-since-2019 caveat (Warning #8); IBAN USD-convert via `USDApproxRate` caveat (Warning #9); Options date-lag caveat (Warning #10); the **CountPositions** measure on the PnL fact (current canonical didn't mention it); the full 9-dimension PnL GROUP BY grain (`IsBuy`, `IsLeveraged`, `IsFuture`, `IsCopyFund`, `IsSQF` were missing from v1); the full 21-column copy/stock/crypto/manual decomposition on the AUM fact (`EquityCopy`, `EquityStocksManual`, `EquityCryptoManual`, `TotalRealCrypto`, `TotalRealStocks`, `CashInCopy`, `CopyInvestedAmount`, `MirrorStockInvestedAmount`, `InvestedAmountStocksManual`, etc.); 9 query patterns (vs 7); broker-side classification explicitly stated.
