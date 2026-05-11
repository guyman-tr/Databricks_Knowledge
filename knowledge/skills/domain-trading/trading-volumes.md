---
id: trading-volumes
name: "Trading Volumes & Amounts"
description: "Notional trading volume, invested amounts, and transaction counts with position flags (InstrumentType, IsSettled, IsCopy, IsCopyFund, IsRecurring, IsAirDrop, IsOpenedFromIBAN). Covers real vs CFD breakdown, volume by asset class, copy/recurring trade identification, the partial-close VolumeOpen=0 convention, and the IsOpenedFromIBAN STRING gotcha. Anchored on the DDR volumes fact (~793M rows, partitioned by etr_ymd)."
triggers:
  - trading volume
  - notional volume
  - invested amount
  - InvestedAmountOpen
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
  - smart portfolio volume
  - airdrop
  - C2P
  - TotalVolume
  - VolumeOpen
  - VolumeClose
  - CountTotalTransactions
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
  - main.etoro_kpi_prep.v_dim_instrument_enriched
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Trading Volumes & Amounts

eToro's daily trading volume — the headline KPI for the trading platform — is reported at customer × date × position-flags grain in the DDR volumes fact. The table is **~793M rows** at the time of this writing, partitioned three ways (`etr_y`, `etr_ym`, `etr_ymd`). It is the right table for "how much was traded" / "how many people traded" / "real vs CFD" / "by asset class" questions. It is the **wrong table** for "what state was this position in at open" — for that, see [`position-state-and-grain.md`](position-state-and-grain.md) and use `fact_customeraction_w_metrics`.

## When to Use

Load when the question is about:

- "Total trading volume this quarter", "how much was traded this month?"
- "Real vs CFD breakdown", "settled vs derivative volume", "how much is real assets?"
- "Volume by asset class", "crypto vs stocks volume", "forex volume"
- "How many people traded?", "unique traders", "active trader count" *(trade-based, not the official Active Trader SCD segment)*
- "Copy-trade volume", "Smart Portfolio volume", "recurring investment volume"
- "IBAN trade volume" (the trade originated from the eMoney wallet)
- "Net invested amount" / "capital deployment trend"

Do **not** load for:

- The official "Active Trader" segment definition (SCD-based, includes Options) → `domain-customer-and-identity` (the DE workspace skill `customer-populations`)
- Position state at open / lifecycle / MirrorID at open → [`position-state-and-grain.md`](position-state-and-grain.md)
- AUM / NOP / equity (end-of-day stock) → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Revenue from a trade → `domain-revenue-and-fees`
- Filtering by ticker / asset → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) (this skill USES that skill's filter rules)

## Scope

In scope: notional volume (`TotalVolume`, `VolumeOpen`, `VolumeClose`), invested amounts (`InvestedAmountOpen`, `InvestedAmountClose`, `NetInvestedAmount`), transaction counts (`CountTotalTransactions`, `CountOpenTransactions`, `CountCloseTransactions`), position flags (`IsSettled`, `IsCopy`, `IsCopyFund`, `IsRecurring`, `IsAirDrop`, `IsC2P`, `IsOpenedFromIBAN`), real vs CFD breakdown, asset-class combos, partial-close `VolumeOpen = 0` convention, the `IsOpenedFromIBAN` STRING type gotcha, partition strategy.
Out of scope: position state at event time (`position-state-and-grain.md`), end-of-day equity / NOP / unrealized PnL (`portfolio-value-aum-pnl.md`), revenue per trade (`domain-revenue-and-fees`), instrument filter pattern (`instruments-and-asset-classes.md`), Spaceship / MoneyFarm / Apex volumes (acquired-platform sub-skills under `domain-revenue-and-fees`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `WHERE IsOpenedFromIBAN = 1` (integer) returns zero rows.** The column is STRING. Use `WHERE IsOpenedFromIBAN = '1'` (quoted). This is the most common gotcha on this table.
2. **Tier 1 — `TotalVolume / InvestedAmountOpen` is NOT leverage.** They aggregate at different grains and are not directly divisible. If you need leverage, read it from `Dim_Position.Leverage` directly. Same caveat for any "ratio of two columns" approach.
3. **Tier 2 — This table does NOT define the official "Active Trader" segment.** The official Active Trader population is SCD-based (`Fact_SnapshotCustomer.ActiveTraded = 1`) and includes Options. The volumes fact gives trade-based counts only — `COUNT(DISTINCT RealCID) WHERE CountOpenTransactions > 0` is a *proxy* for trade-active customers in the date range, not the official population.
4. **Tier 2 — `VolumeOpen = 0` for partial-close children is a convention, not a bug.** When a position is partially closed, the residual gets `VolumeOpen = 0` to avoid double-counting against the original open volume. Don't filter `VolumeOpen > 0` thinking it removes bad rows.
5. **Tier 3 — Table has ~793M rows.** ALWAYS filter by `etr_ymd` (or `etr_ym` / `etr_y`) for partition pruning. A query without the partition filter scans the entire table and is rejected by most warehouse policies.
6. **Tier 3 — This table is derived FROM `fact_customeraction_w_metrics`, not from `Dim_Position`.** So the at-event-time semantics apply: `IsCopy = 1` on a volume row means the position was opened as a copy AT OPEN, regardless of whether it's been detached since. No fact-vs-dim trap here — the fact-vs-dim rule from `position-state-and-grain.md` is already baked in.

## Table

`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts`

- **Grain**: `RealCID × DateID × <position flags>`. One row per (customer, date, flag combination) — flags include `IsSettled`, `InstrumentTypeID`, `IsCopy`, `IsCopyFund`, `IsRecurring`, `IsAirDrop`, `IsOpenedFromIBAN`, `IsC2P`.
- **Row count**: ~793M.
- **Partitions**: `etr_y`, `etr_ym`, `etr_ymd`.

---

## Core Concepts

| Concept | What It Is | Aliases |
|---|---|---|
| **TotalVolume** | Notional (leveraged) value of opens + closes. $100 at 5× leverage = $500 notional. Primary KPI for "trading volume". | trading volume, notional volume |
| **VolumeOpen / VolumeClose** | Notional from positions opened / closed that day. Sum to `TotalVolume`. | open volume, close volume |
| **InvestedAmountOpen** | Actual cash deployed (before leverage). Single source of truth for "capital deployed". | invested amount, capital deployed |
| **NetInvestedAmount** | InvestedAmountOpen − InvestedAmountClose. Positive = customer deploying more capital that day. | net investment, capital flow |
| **CountTotalTransactions** | Number of trades (opens + closes) for that customer × date × flag combo. | trade count, number of trades |
| **CountOpenTransactions** | Number of opens only. Useful for "did this customer trade today?" — `> 0` ⇒ yes. | open count |
| **CountCloseTransactions** | Number of closes only. | close count |

### Position flags

| Flag | Type | Meaning | Aliases |
|---|---|---|---|
| `IsSettled` | INT 0/1 | 1 = real asset (real stock, real crypto, real futures). 0 = CFD / derivative. | real vs CFD, settled |
| `IsCopy` | INT 0/1 | 1 = auto-opened by copying another trader. (Flag captures state AT OPEN — see Critical Warning #6.) | copy trade, social trading |
| `IsCopyFund` | INT 0/1 | 1 = Smart Portfolio (`MirrorTypeID = 4`). | smart portfolio, copy fund |
| `IsRecurring` | INT 0/1 | 1 = auto-invest / recurring investment. | recurring, scheduled investment |
| `IsC2P` | INT 0/1 | 1 = was a copy, customer kept the position after stopping the copy relationship. | copy to portfolio |
| `IsAirDrop` | INT 0/1 | 1 = free promotional share (e.g. referral or campaign giveaway). | free share, promotion |
| `IsOpenedFromIBAN` | **STRING** `'0'`/`'1'` | 1 = position opened directly from the customer's eMoney wallet. **Filter as `= '1'`!** | IBAN trade |

### Asset class combos

| Asset class | InstrumentTypeID | IsSettled | Notes |
|---|---|---|---|
| Real Stocks | 5 | 1 | Real US/EU/UK equity |
| CFD Stocks | 5 | 0 | Leveraged stock CFDs |
| Real Crypto | 10 | 1 | Customer owns the coin (eToro custody) |
| Crypto CFDs | 10 | 0 | Leveraged crypto |
| Real ETFs | 6 | 1 | ETF holdings |
| Forex | 1 | 0 | FX pairs — always CFD |
| Commodities | 2 | 0 | Gold, oil, etc. — always CFD |
| Indices | 4 | 0 | SPX500, DJ30 — always CFD |
| Real Futures | 5 or 4 | 1 | `SettlementTypeID = 4` |

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
       SUM(InvestedAmountOpen) AS invested
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY IsSettled;
```
**Use when:** "real vs CFD volume", "settled vs derivative", "how much is real assets?"

### Pattern 3 — Volume by instrument type
```sql
SELECT InstrumentTypeID, SUM(TotalVolume) AS volume
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY InstrumentTypeID ORDER BY volume DESC;
```
**Use when:** "volume by asset class", "crypto vs stocks volume", "forex volume"

### Pattern 4 — Volume from a specific ticker (joins through enriched view)
```sql
SELECT f.etr_ym, SUM(f.TotalVolume) AS volume
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts f
JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i
  ON f.InstrumentID = i.InstrumentID
WHERE i.Symbol LIKE 'TSLA%'
  AND i.InstrumentTypeID = 5
  AND i.IsFuture = 0
  AND i.Tradeable = 1
  AND f.etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY f.etr_ym
ORDER BY f.etr_ym;
```
**Use when:** "Tesla trading volume", "BTC volume by month", "volume for ticker X". Uses the two-part filter pattern from [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md).

### Pattern 5 — Active traders count (trade-based, not official segment)
```sql
SELECT COUNT(DISTINCT RealCID) AS active_traders
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE CountOpenTransactions > 0
  AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "how many people traded?", "unique traders this quarter". **Not** the official Active Trader segment — for that route to `domain-customer-and-identity` and the `customer-populations` DE workspace skill.

### Pattern 6 — Copy-trade volume share
```sql
SELECT IsCopy,
       SUM(TotalVolume) AS volume,
       SUM(CountTotalTransactions) AS trades
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY IsCopy;
```
**Use when:** "what fraction of volume is copy?", "manual vs copy split"

### Pattern 7 — IBAN-originated trade volume (note the STRING!)
```sql
SELECT etr_ym, SUM(TotalVolume) AS iban_volume
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE IsOpenedFromIBAN = '1'   -- STRING, not INT
  AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY etr_ym
ORDER BY etr_ym;
```
**Use when:** "IBAN trade volume", "volume opened from wallet". `IsOpenedFromIBAN = 1` (integer) silently returns zero rows.

### Pattern 8 — Net invested amount trend
```sql
SELECT etr_ym, SUM(NetInvestedAmount) AS net_invested
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE etr_ymd BETWEEN '2026-01-01' AND '2026-12-31'
GROUP BY etr_ym
ORDER BY etr_ym;
```
**Use when:** "are customers deploying or repatriating capital?", "net investment flow trend"

---

## Cross-references

- Instrument filter rules (used by Pattern 4) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Position state, copy detection at the row level → [`position-state-and-grain.md`](position-state-and-grain.md)
- End-of-day stock (AUM, NOP, equity) → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Revenue from these trades → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Official Active Trader segment → `customer-populations` DE workspace skill (load via `../domain-customer-and-identity/SKILL.md`)

## Provenance

This sub-skill deeply incorporates the DataPlatform DE workspace-root skill `trading-volumes` (`/Workspace/.assistant/skills/trading-volumes/SKILL.md`, version 1, `last_validated_at` 2026-05-07). The original is scheduled for removal once this incorporated version is validated. Row counts and partition strategy verified against the source skill on 2026-05-11.
