---
id: portfolio-value
name: "Portfolio Value (AUM & PnL)"
description: "End-of-day portfolio snapshots: Assets Under Management (AUM), total equity, Net Open Position (NOP) exposure, invested amounts, unrealized PnL, and daily realized profit. Two DDR fact tables — AUM for snapshot state, PnL for daily changes. Covers copy vs manual equity split."
triggers:
  - AUM
  - equity
  - NOP
  - portfolio value
  - unrealized PnL
  - realized PnL
  - net open position
  - market exposure
  - paper gains
  - copy equity
  - account value
  - total equity
  - assets under management
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-07"
---

# Portfolio Value (AUM & PnL)

## When to Use
- "what's our AUM?", "total platform equity", "how much do customers hold?"
- "NOP trend this month", "market exposure over time"
- "PnL by asset class", "which instruments are profitable?"
- "how much is in copy?", "copy vs manual split"
- Any question about end-of-day portfolio state or daily profit/loss changes

## Scope
In scope: End-of-day portfolio snapshots (equity, NOP, invested), daily PnL changes by instrument/copy/settled, copy vs manual equity
Out of scope: Invested amount as daily *flow* (→ `trading-volumes` skill), funded segment definition using equity > 0 threshold (→ `customer-populations` skill), revenue/fees (→ `revenue` skill)
Last verified: 2026-05-07

## Critical Warnings
1. SUM(TotalEquityTP) across multiple DateIDs gives N× actual — AUM is snapshot data. Use single date or AVG.
2. UnrealizedPnLChange is today's CHANGE only — for total unrealized, use `TotalPositionPNL` from the AUM table.
3. NOPCrypto + NOPStocks + ... ≠ NOP — sub-columns miss some asset classes (Forex, Commodities, Indices, ETFs). Use `NOP` directly for total exposure.
4. AUM table has no `etr_ymd` partition — use `DateID` directly. PnL table has `etr_ymd`.
5. IsLeveraged (PnL table) vs IsLeverage (Volumes table) — same concept, different column names across tables.
6. The DDR AUM table is the reporting layer. The underlying source tables (`bi_db_client_balance_cid_level_new`, `emoneyclientbalance`, `v_options_aum`) are used internally by the `v_population_funded` view for the funded segment check.

---

## Tables

| Table | Use For |
|---|---|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | End-of-day portfolio snapshot (equity, NOP, invested). No `etr_ymd` — use `DateID`. |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | Daily PnL changes by instrument/copy/settled. Partitions: `etr_y`, `etr_ym`, `etr_ymd`. |

---

## Core Concepts

### AUM (snapshot — each DateID = end-of-day state)

| Concept | What It Is | Aliases |
|---|---|---|
| **TotalEquityTP** | End-of-day equity on the Trading Platform. Sum across all customers = platform AUM. | total equity, portfolio value, account value |
| **RealizedEquityTP** | Realized equity (cash + closed PnL, excludes unrealized). | realized equity, cash equity |
| **NOP** | Net Open Position — total market exposure from open positions. | market exposure, open exposure |
| **TotalInvestedAmount** | Capital allocated to open positions (before leverage). | invested amount, capital at risk |
| **EquityCopy** | Portion allocated to copy relationships (social trading). | copy equity, copy AUM |
| **InProcessCashout** | Pending cashout amount not yet finalized. | pending withdrawal |
| **TotalPositionPNL** | Total unrealized PnL across all open positions (cumulative, not daily change). | unrealized PnL, paper gains |

### PnL (daily delta — the CHANGE that day, not cumulative total)

| Concept | What It Is | Aliases |
|---|---|---|
| **UnrealizedPnLChange** | Day-over-day change in unrealized P&L (mark-to-market movement). | paper gains change, MTM change |
| **NetProfit** | Realized profit from positions closed on that date. | realized PnL, closed profit |

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
SELECT DateID, SUM(TotalEquityTP) AS aum, SUM(NOP) AS nop
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID BETWEEN 20260301 AND 20260331
GROUP BY DateID ORDER BY DateID;
```
**Use when:** "AUM trend", "equity over time", "NOP trend this month"

### Pattern 3 — PnL by instrument type
```sql
SELECT InstrumentTypeID, SUM(UnrealizedPnLChange) AS unrealized, SUM(NetProfit) AS realized
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE etr_ymd = '2026-04-01'
GROUP BY InstrumentTypeID;
```
**Use when:** "PnL by asset class", "which instruments are profitable?", "crypto PnL today"

### Pattern 4 — Copy vs manual equity split
```sql
SELECT SUM(EquityCopy) AS copy_equity, SUM(TotalEquityTP) - SUM(EquityCopy) AS manual_equity
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260401;
```
**Use when:** "how much is in copy?", "copy vs manual AUM", "social trading equity"
