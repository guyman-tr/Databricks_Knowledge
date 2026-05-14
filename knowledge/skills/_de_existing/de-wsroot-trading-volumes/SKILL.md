---
id: trading-volumes
name: "Trading Volumes & Amounts"
description: "Notional trading volume, invested amounts, and transaction counts with position flags (InstrumentType, IsSettled, IsCopy, IsCopyFund, IsRecurring, IsAirDrop, IBAN). Covers real vs CFD breakdown, volume by asset class, and copy/recurring trade identification."
triggers:
  - trading volume
  - notional volume
  - invested amount
  - trade count
  - number of trades
  - real vs CFD
  - asset class volume
  - copy trades
  - recurring investment
  - IBAN trades
  - smart portfolio
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-07"
---

# Trading Volumes & Amounts

## When to Use
- "total trading volume this quarter", "how much was traded?"
- "real vs CFD breakdown", "how much is real assets?"
- "volume by asset class", "crypto vs stocks volume"
- "how many people traded?", "unique traders"
- Any question about notional volume, invested capital, or trade-level flag breakdowns

## Scope
In scope: Notional volume, invested amounts (open/close/net), transaction counts, position flags (IsSettled, IsCopy, IsCopyFund, IsRecurring, IsAirDrop, IsOpenedFromIBAN), asset class combos
Out of scope: Official "Active Trader" segment (→ `customer-populations` skill). This table gives trade-based counts only.
Last verified: 2026-05-07

## Critical Warnings
1. `WHERE IsOpenedFromIBAN = 1` (integer) returns no rows — column is STRING, use `= '1'`.
2. TotalVolume / InvestedAmountOpen is NOT leverage — they aggregate differently and are not directly divisible.
3. This table does NOT define the official "Active Trader" segment — official uses SCD table (`ActiveTraded=1`) which includes Options. This is TP only.
4. VolumeOpen = 0 for partial-close children — this avoids double-counting, not a bug.
5. Table has ~793M rows — always filter by `etr_ymd` (or `etr_ym`/`etr_y`) for partition pruning.

---

## Table

`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts`
- **Grain**: RealCID × DateID × flags. ~793M rows. Partitions: `etr_y`, `etr_ym`, `etr_ymd`.

---

## Core Concepts

| Concept | What It Is | Aliases |
|---|---|---|
| **TotalVolume** | Notional (leveraged) value of opens + closes. $100 at 5x = $500. Primary KPI. | trading volume, notional volume |
| **VolumeOpen / VolumeClose** | Notional from positions opened / closed that day. | open volume, close volume |
| **InvestedAmountOpen** | Actual cash deployed (before leverage). | invested amount, capital deployed |
| **NetInvestedAmount** | Open minus Closed invested. Positive = deploying more. | net investment, capital flow |
| **CountTotalTransactions** | Number of trades (opens + closes). | trade count, number of trades |

### Position Flags

| Flag | Meaning | Aliases |
|---|---|---|
| **IsSettled** | 1 = real asset. 0 = CFD. | real vs CFD |
| **IsCopy** | 1 = auto-opened by copying another trader. | copy trade, social trading |
| **IsCopyFund** | 1 = Smart Portfolio (managed product). | smart portfolio |
| **IsRecurring** | 1 = auto-invest. | recurring investment |
| **IsC2P** | 1 = was copy, customer kept position after stopping. | copy to portfolio |
| **IsAirDrop** | 1 = free promotional share. | free share, promotion |
| **IsOpenedFromIBAN** | 1 = from eMoney wallet. **STRING — use `= '1'`!** | IBAN trade |

### Asset Class Combos
- Real Stocks: InstrumentTypeID=5, IsSettled=1
- Crypto CFDs: InstrumentTypeID=10, IsSettled=0
- Forex: InstrumentTypeID=1 (always CFD)

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
SELECT IsSettled, SUM(TotalVolume) AS vol, SUM(InvestedAmountOpen) AS invested
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

### Pattern 4 — Active traders count
```sql
SELECT COUNT(DISTINCT RealCID) AS active_traders
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE CountOpenTransactions > 0 AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "how many people traded?", "unique traders", "active trader count"
