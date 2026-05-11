---
id: portfolio-value-aum-pnl
name: "Portfolio Value — AUM, NOP & PnL"
description: "End-of-day portfolio snapshots and daily PnL deltas across the trading platform. Two DDR fact tables: the AUM fact for snapshot state (TotalEquityTP, NOP, invested, unrealized) and the PnL fact for daily changes (UnrealizedPnLChange, NetProfit). Covers copy vs manual equity split, NOP-sub-columns-don't-sum gotcha, and the snapshot-vs-delta aggregation rule (never SUM AUM across dates; do SUM PnL deltas across dates)."
triggers:
  - AUM
  - equity
  - NOP
  - net open position
  - portfolio value
  - account value
  - assets under management
  - total equity
  - TotalEquityTP
  - RealizedEquityTP
  - market exposure
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
  - mark to market
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Portfolio Value — AUM, NOP & PnL

The trading platform's end-of-day state lives in **two** DDR fact tables, and the difference between them is the difference between a *snapshot* and a *delta*. The AUM fact stores one row per customer per day = end-of-day state (equity, exposure, invested, unrealized PnL cumulative). The PnL fact stores one row per customer per day per instrument × copy × settled = the daily *change* in unrealized PnL and the daily realized profit. Mixing them up — summing AUM across dates, summing daily PnL changes only on a single date — is the most common analytical mistake on this dataset.

## When to Use

Load when the question is about:

- "What's our AUM?", "total platform equity", "how much do customers hold?"
- "NOP trend this month", "market exposure over time", "open position exposure"
- "PnL by asset class", "which instruments are profitable?", "crypto unrealized PnL"
- "How much is in copy?", "copy vs manual equity split"
- "Pending cashouts", "InProcessCashout total"
- Any question about end-of-day portfolio state or daily profit/loss changes

Do **not** load for:

- Position state at open / lifecycle / MirrorID-at-open → [`position-state-and-grain.md`](position-state-and-grain.md)
- Daily flow / capital deployment (`InvestedAmountOpen` as a flow, not a stock) → [`trading-volumes.md`](trading-volumes.md)
- The official "funded customer" segment definition (`TotalEquityTP > $X` threshold) → `customer-populations` DE workspace skill under `domain-customer-and-identity`
- Per-trade revenue / fees → `domain-revenue-and-fees`
- Filtering by ticker → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) (this skill uses those rules)

## Scope

In scope: end-of-day snapshot (TotalEquityTP, RealizedEquityTP, NOP and NOP sub-columns, TotalInvestedAmount, EquityCopy, InProcessCashout, TotalPositionPNL), daily PnL delta (UnrealizedPnLChange, NetProfit) at customer × date × instrument × copy × settled grain, partition strategy (AUM has no `etr_ymd` — use `DateID`; PnL has `etr_ymd`), snapshot-vs-delta aggregation rule, copy vs manual equity split, NOP sub-column completeness caveat, IsLeveraged-vs-IsLeverage column naming inconsistency across tables.
Out of scope: position-event detail (`position-state-and-grain.md`), volume / invested flow (`trading-volumes.md`), funded population segment (`customer-populations`), revenue (`domain-revenue-and-fees`), acquired-platform AUM (Spaceship, MoneyFarm, Apex — those live in `domain-revenue-and-fees` per-product sub-skills).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `SUM(TotalEquityTP)` across multiple `DateID`s gives N× actual AUM.** AUM is *snapshot* data — one row per (customer, date) is the customer's full equity at end-of-day. Summing across N days inflates the total N times. Use a single `DateID` or compute `AVG(TotalEquityTP_per_date)` for an average. **Same rule applies to NOP, TotalInvestedAmount, TotalPositionPNL, EquityCopy, InProcessCashout** — every column on the AUM fact is a snapshot.
2. **Tier 1 — `UnrealizedPnLChange` is today's CHANGE only.** It's the day-over-day mark-to-market movement. To get TOTAL unrealized PnL across all open positions, use `TotalPositionPNL` from the AUM fact (cumulative). To get unrealized PnL for a date range, `SUM(UnrealizedPnLChange)` across the range — that does sum (it's a delta).
3. **Tier 2 — `NOPCrypto + NOPStocks + NOPRealStocks + ... ≠ NOP`.** The NOP sub-columns miss some asset classes (Forex, Commodities, Indices, ETFs). Use `NOP` directly for total exposure. Use the sub-columns only when you want a single-class breakdown and know they're incomplete for "everything else".
4. **Tier 2 — AUM table has no `etr_ymd` partition.** Use `DateID` (integer YYYYMMDD) directly. The PnL fact DOES have `etr_ymd` partitions. The two tables are partitioned differently — be careful when joining.
5. **Tier 3 — Column naming inconsistency: `IsLeveraged` (PnL table) vs `IsLeverage` (Volumes table).** Same concept, different spellings across tables. Always check the schema before authoring a join across the volumes and PnL facts.
6. **Tier 3 — The DDR AUM table is the reporting layer.** The underlying source tables (`bi_db_client_balance_cid_level_new`, `emoneyclientbalance`, `v_options_aum`) are used internally by the `v_population_funded` view to compute the funded segment. Don't query those directly — they have different grain and different exclusion rules. Stay on the DDR fact.

## Tables

| Table | Grain | Partitions | Use For |
|---|---|---|---|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | 1 row per customer × `DateID` = end-of-day snapshot | **none** (use `DateID`) | Equity, NOP, invested, unrealized PnL cumulative, copy equity, pending cashouts |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | 1 row per customer × `DateID` × instrument × copy × settled = daily delta | `etr_y`, `etr_ym`, `etr_ymd` | Daily PnL changes (unrealized + realized) — DOES sum across dates |

---

## Core Concepts

### AUM (snapshot — each `DateID` = end-of-day state)

| Concept | What It Is | Aliases |
|---|---|---|
| **TotalEquityTP** | End-of-day equity on the Trading Platform. Sum across all customers (single date) = platform AUM. | total equity, portfolio value, account value |
| **RealizedEquityTP** | Realized equity (cash + closed PnL; excludes unrealized). | realized equity, cash equity |
| **NOP** | Net Open Position — total market exposure from open positions. | market exposure, open exposure |
| **NOPCrypto**, **NOPStocks**, **NOPRealStocks**, etc. | Per-asset-class NOP. **Do NOT sum to NOP** — see Critical Warning #3. | per-class exposure |
| **TotalInvestedAmount** | Capital allocated to open positions (before leverage). | invested amount, capital at risk |
| **EquityCopy** | Portion of `TotalEquityTP` allocated to copy relationships (social trading). | copy equity, copy AUM |
| **InProcessCashout** | Pending cashout amount not yet finalized. | pending withdrawal |
| **TotalPositionPNL** | Total unrealized PnL across all open positions, **cumulative** (not daily change). | unrealized PnL, paper gains |

### PnL (daily delta — the CHANGE that day, not cumulative total)

| Concept | What It Is | Aliases |
|---|---|---|
| **UnrealizedPnLChange** | Day-over-day change in unrealized PnL (mark-to-market movement). | paper gains change, MTM change |
| **NetProfit** | Realized profit from positions closed on that date. | realized PnL, closed profit |

### Snapshot vs delta — the unit cheat-sheet

| Source | Type | Aggregation rule | Example |
|---|---|---|---|
| `TotalEquityTP` (AUM) | Snapshot | Single date, or `AVG` over dates | "AUM on March 1" / "avg AUM in March" |
| `NOP` (AUM) | Snapshot | Single date, or `AVG` over dates | "NOP today" / "avg NOP this week" |
| `TotalPositionPNL` (AUM) | Snapshot | Single date, or `AVG` over dates | "unrealized PnL right now" |
| `UnrealizedPnLChange` (PnL) | Daily delta | `SUM` across rows + dates | "unrealized PnL gained this month" |
| `NetProfit` (PnL) | Daily delta | `SUM` across rows + dates | "realized profit this quarter" |

---

## Query Patterns

### Pattern 1 — Total AUM on a date
```sql
SELECT SUM(TotalEquityTP) AS total_aum
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260401;
```
**Use when:** "what's our AUM?", "total platform equity", "how much do customers hold?"

### Pattern 2 — AUM and NOP time series
```sql
SELECT DateID,
       SUM(TotalEquityTP) AS aum,
       SUM(NOP) AS nop,
       SUM(TotalPositionPNL) AS unrealized_pnl
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID BETWEEN 20260301 AND 20260331
GROUP BY DateID
ORDER BY DateID;
```
**Use when:** "AUM trend", "equity over time", "NOP trend this month". Each row is a snapshot at that DateID; do not sum across dates.

### Pattern 3 — PnL by instrument type (daily)
```sql
SELECT InstrumentTypeID,
       SUM(UnrealizedPnLChange) AS unrealized_change,
       SUM(NetProfit) AS realized
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE etr_ymd = '2026-04-01'
GROUP BY InstrumentTypeID
ORDER BY realized DESC;
```
**Use when:** "PnL by asset class", "which instruments are profitable today?", "crypto PnL today"

### Pattern 4 — PnL trend over a quarter
```sql
SELECT etr_ym,
       SUM(UnrealizedPnLChange) AS unrealized_quarterly,
       SUM(NetProfit) AS realized_quarterly
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY etr_ym
ORDER BY etr_ym;
```
**Use when:** "PnL trend this quarter", "monthly profit / loss summary". Deltas DO sum.

### Pattern 5 — Copy vs manual equity split
```sql
SELECT SUM(EquityCopy) AS copy_equity,
       SUM(TotalEquityTP) - SUM(EquityCopy) AS manual_equity,
       SUM(TotalEquityTP) AS total_equity
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260401;
```
**Use when:** "how much is in copy?", "copy vs manual AUM", "social trading equity share"

### Pattern 6 — PnL on a specific ticker (joins through enriched view)
```sql
SELECT p.etr_ym,
       SUM(p.UnrealizedPnLChange) AS unrealized_change,
       SUM(p.NetProfit) AS realized
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl p
JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i
  ON p.InstrumentID = i.InstrumentID
WHERE i.Symbol LIKE 'TSLA%'
  AND i.InstrumentTypeID = 5
  AND i.IsFuture = 0
  AND i.Tradeable = 1
  AND p.etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY p.etr_ym
ORDER BY p.etr_ym;
```
**Use when:** "Tesla PnL this quarter", "BTC unrealized change last month". Uses the two-part instrument filter from [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md).

### Pattern 7 — Pending cashouts
```sql
SELECT SUM(InProcessCashout) AS pending_cashouts
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260401;
```
**Use when:** "how much is in process for cashout?", "pending withdrawals". The MIMO domain owns the cashout flow itself (`domain-payments`); this column shows the snapshot dollar amount sitting in the queue at end-of-day.

---

## Cross-references

- Instrument filter rules (used by Pattern 6) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Position state, copy detection at the row level → [`position-state-and-grain.md`](position-state-and-grain.md)
- Volume / invested flow (vs end-of-day stock) → [`trading-volumes.md`](trading-volumes.md)
- Revenue from these positions → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Cashout / withdrawal flow → [`../domain-payments/SKILL.md`](../domain-payments/SKILL.md)
- Funded segment definition → `customer-populations` DE workspace skill (load via `../domain-customer-and-identity/SKILL.md`)

## Provenance

This sub-skill deeply incorporates the DataPlatform DE workspace-root skill `portfolio-value` (`/Workspace/.assistant/skills/portfolio-value/SKILL.md`, version 2, `last_validated_at` 2026-05-07). The original is scheduled for removal once this incorporated version is validated. Grain, partition strategy, and the funded-population caveat verified against the source skill on 2026-05-11.
