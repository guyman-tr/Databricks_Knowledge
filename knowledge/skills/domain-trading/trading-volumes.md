---
id: trading-volumes
name: "Trading Volumes & Amounts"
description: "Notional trading volume, invested amounts, and transaction counts at customer × date × position-flag grain. Anchored on the DDR Fact_Trading_Volumes_And_Amounts (~793M rows, partitioned by etr_ymd). 17 dimension flags total: InstrumentTypeID, IsSettled, IsCopy, IsBuy, IsLeverage, IsFuture, IsCopyFund, IsOpenedFromIBAN, IsClosedToIBAN, IsRecurring, IsAirDrop, IsSQF, IsMarginTrade, IsC2P. Covers real vs CFD breakdown, volume by asset class, copy/recurring trade identification, the partial-close VolumeOpen=0 convention, the BIGINT-money type quirks (VolumeOpen/Close are BIGINT in instrument-units × FX, InvestedAmount is DECIMAL(19,4) converted from Synapse money), and the two big asymmetry traps: `IsOpenedFromIBAN` is STRING but `IsClosedToIBAN` is INT, and `IsLeverage` (no 'd') vs `IsLeveraged` (the sibling DDR tables). Broker-side: derived FROM Dim_Position via Function_Trading_Volume_PositionLevel + 6 enrichment tables, daily DELETE/INSERT by DateID."
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
  - CountTotalTransactions
  - DDR volumes
  - Fact_Trading_Volumes_And_Amounts
  - VolumeQA
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
  - main.etoro_kpi_prep.v_dim_instrument_enriched
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Trading Volumes & Amounts

eToro's daily trading volume — the headline KPI for the trading platform — is reported at **customer × date × 16 position-flag dimensions** grain in the DDR volumes fact. The table is **~793M rows**, partitioned three ways (`etr_y`, `etr_ym`, `etr_ymd`). It is the right table for "how much was traded" / "how many people traded" / "real vs CFD" / "by asset class" / "long vs short" / "leveraged vs unleveraged" / "margin trade" / "auto-invest" questions. It is the **wrong table** for "what state was this position in at open" — for that, see [`position-state-and-grain.md`](position-state-and-grain.md) and use `fact_customeraction_w_metrics`.

**Side classification**: **broker-side**. The data is sourced from `Dim_Position` and 6 broker-side enrichment tables via `Function_Trading_Volume_PositionLevel`, aggregated via `SP_DDR_Fact_Trading_Volumes_And_Amounts` with daily DELETE/INSERT by DateID. No dealer-side data (no LP/execution/hedge fields).

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

- The official "Active Trader" segment definition (SCD-based, includes Options) → `domain-customer-and-identity` (the DE workspace skill `customer-populations`)
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

1. **Tier 1 — `WHERE IsOpenedFromIBAN = 1` (integer) returns zero rows.** The column is **STRING** (`varchar(100)` in Synapse, `STRING` in UC). Use `WHERE IsOpenedFromIBAN = '1'`. **AND**: the sibling column `IsClosedToIBAN` is **INT** — they have asymmetric types. So `WHERE IsClosedToIBAN = 1` (integer) is correct for the close side. This is the single most common gotcha on this table.

2. **Tier 1 — `IsLeverage` (no 'd') is unique to this table.** Every other DDR table uses `IsLeveraged` (with 'd'). Semantics are identical (`CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`). If you copy a query from another DDR sub-skill, **rename `IsLeveraged` → `IsLeverage`** when you bring it here.

3. **Tier 1 — `TotalVolume / InvestedAmountOpen` is NOT leverage.** They aggregate at different grains and are not directly divisible. If you need leverage, read it from `Dim_Position.Leverage` (or use the `IsLeverage` boolean here, which is already pre-bucketed). Same caveat for any "ratio of two columns" approach on this fact.

4. **Tier 1 — `TotalVolume ≠ SUM(VolumeOpen) + SUM(VolumeClose)` at the aggregated level.** `TotalVolume` is computed per-position as `(VolumeOpen + VolumeClose)` THEN summed. `SUM(VolumeOpen) + SUM(VolumeClose)` is the column-wise sum. They diverge whenever a position contributes to BOTH the open and close sides within the same group (e.g. opened and closed the same day under the same flag combo). Pick one and stick with it; do NOT compute the difference and treat it as a bug.

5. **Tier 1 — Volume columns (`VolumeOpen`, `VolumeClose`, `TotalVolume`) are `BIGINT`.** They store notional in *instrument-native units × FX rate* expressed as whole numbers. Fractional cents are truncated. The invested-amount columns (`InvestedAmountOpen`, `InvestedAmountClosed`, `NetInvestedAmount`) are `DECIMAL(19,4)` (Databricks-converted from Synapse `money` type — be aware of precision differences if you join with another `money`-derived column).

6. **Tier 2 — This table does NOT define the official "Active Trader" segment.** The official Active Trader population is SCD-based (`Fact_SnapshotCustomer.ActiveTraded = 1`) and includes Options. The volumes fact gives trade-based counts only — `COUNT(DISTINCT RealCID) WHERE CountOpenTransactions > 0` is a *proxy* for trade-active customers in the date range, not the official population.

7. **Tier 2 — `VolumeOpen = 0` for partial-close children is a convention, not a bug.** Partial-close children are the residual positions left when a customer closes only part of an open position. The SP source function gives them `VolumeOpen = 0` AND `CountOpenTransactions = 0` to avoid double-counting against the parent open volume. They contribute only on the close side. **Don't filter `VolumeOpen > 0` thinking it removes bad rows** — you'll lose legitimate close-side data.

8. **Tier 2 — Daily refresh is DELETE/INSERT BY DateID.** A given DateID can be regenerated by the SP without affecting other dates. Latency is typically T+1 (yesterday's data appears in the morning). The `UpdateDate` column reflects the SP run time, not anything semantically meaningful.

9. **Tier 2 — This table is derived FROM `fact_customeraction_w_metrics`/`Dim_Position`, not from real-time event streams.** The at-event-time semantics apply: `IsCopy = 1` on a volume row means the position was opened as a copy AT OPEN (via the `MirrorID > 0` rule in `Function_Trading_Volume_PositionLevel`), regardless of whether it's since been detached. The fact-vs-dim trap is already baked in by the function. See [`position-state-and-grain.md`](position-state-and-grain.md) Warning #1.

10. **Tier 2 — `IsSQF` semantic is ambiguous between this skill family and the instruments skill.** The instruments wiki documents IsSQF as `GroupID = 59` in `Trade.InstrumentGroups`. The DDR fact wiki expands it as "Sustainable & Quality-Focused". Live data shows only 8 instruments flagged IsSQF=1 (4 indices + 4 crypto, all also `IsFuture=1`) — consistent with a UK regulatory designation rather than ESG marketing. Treat as a small, rarely-needed flag.

11. **Tier 3 — Table has ~793M rows.** ALWAYS filter by `etr_ymd` (or `etr_ym` / `etr_y`) for partition pruning. A query without the partition filter scans the entire table and is rejected by most warehouse policies.

12. **Tier 3 — `BI_DB_VolumeQA` parallel dump exists (Synapse only, not in UC).** The SP writes position-level detail to `BI_DB_VolumeQA` alongside each refresh of this aggregated fact. Use only for data-quality investigations against Synapse — it is NOT exposed in UC and is NOT a reporting table.

## Table

`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts`

- **Grain**: `RealCID × DateID × <17 dimension flags>`. One row per (customer × date × dimension combination). Median rows per customer-day ≈ 1-3; high-activity customers can produce 50+ rows on a single day.
- **Row count**: ~793M (May 2026).
- **Partitions**: `etr_y`, `etr_ym`, `etr_ymd` (parquet partitions on the underlying lake storage).
- **Refresh**: Daily DELETE/INSERT by DateID via `SP_DDR_Fact_Trading_Volumes_And_Amounts`. ETL source is `BI_DB_dbo.Function_Trading_Volume_PositionLevel(@dateID, @dateID, 0)` — a TVF that produces 32 columns of position-level open/close detail. The SP aggregates with `GROUP BY` on the 17 dimension columns and `SUM` on the 9 measure columns.
- **SP authored**: 2025-04-20. Material additions: IsSQF (2025-06-23), IsMarginTrade (2025-10-23), IsC2P (2025-12-14), source-function replacement to position-level + QA dump (2026-01-15).

---

## Core Concepts

### Measure columns (9)

| Column | Type | What it is | Aliases |
|---|---|---|---|
| `TotalVolume` | BIGINT | Notional (leveraged) value of opens + closes. $100 at 5× leverage = $500 notional. **Primary trading volume KPI**. Per-position sum of (VolumeOpen + VolumeClose), then SUM in the SP. | trading volume, notional volume |
| `VolumeOpen` | BIGINT | Notional from positions opened that day. Partial-close children contribute 0. `SUM(CAST(Dim_Position.Volume AS BIGINT))` on open legs. | open volume |
| `VolumeClose` | BIGINT | Notional from positions closed that day. `SUM(CAST(Dim_Position.VolumeOnClose AS BIGINT))` on close legs. | close volume |
| `InvestedAmountOpen` | DECIMAL(19,4) | Actual cash deployed at open, pre-leverage. From `Dim_Position.InitialAmountCents / 100.0`. Partial-close children contribute 0. **Single source of truth for "capital deployed".** | invested amount, capital deployed |
| `InvestedAmountClosed` | DECIMAL(19,4) | Cash returned on close. From `CAST(Dim_Position.Amount AS FLOAT)`. | invested closed |
| `NetInvestedAmount` | DECIMAL(19,4) | `SUM(per-position (InvestedAmountOpen − InvestedAmountClosed))`. Positive = customer deploying more capital that day. | net investment, capital flow |
| `CountTotalTransactions` | INT | Number of trades (opens + closes) for that customer × date × flag combo. | trade count |
| `CountOpenTransactions` | INT | Number of opens only. Useful for "did this customer trade today?" — `> 0` ⇒ yes. Excludes partial-close children. | open count |
| `CountCloseTransactions` | INT | Number of closes only. | close count |

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

| Asset class | InstrumentTypeID | IsSettled | Recent row count | Sample TotalVolume |
|---|---|---|---|---|
| **Real Stocks** | 5 | 1 | 4.17M | 7.26B |
| **CFD Stocks** | 5 | 0 | 848K | 5.79B |
| **Real Crypto** | 10 | 1 | 763K | 501M |
| **CFD Crypto** | 10 | 0 | 86K | 162M |
| **Real ETFs** | 6 | 1 | 443K | 499M |
| **CFD ETFs** | 6 | 0 | 738K | 889M |
| **Commodities (mostly CFD)** | 2 | 0 / 1 | 1.22M / 2.5K | 57.1B / 524M |
| **Indices (CFD)** | 4 | 0 | 630K | 34.7B |
| **Forex (CFD)** | 1 | 0 | 163K | 10.8B |

**Observations from live data**:
- **Commodities and Indices CFDs dominate notional volume** — high leverage drives big notional even with smaller row counts.
- **Real Stocks have the most rows** (4.17M for the month) — many small retail trades.
- **Real Crypto >> CFD Crypto on row count** (763K vs 86K) — eToro's crypto is now mostly real-custody, not synthetic.
- **TypeID 9 (Options) has ZERO rows in recent data** — despite the wiki suggesting options "always real" go here.

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

### Pattern 4-alt — Per-ticker volume from the granular fact
```sql
SELECT f.DateID, SUM(f.PositionAmountOpen) AS volume_open    -- or PositionVolumeOpen if leveraged
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics f
JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i ON f.InstrumentID = i.InstrumentID
WHERE i.Symbol LIKE 'TSLA%'
  AND i.InstrumentTypeID = 5
  AND i.IsFuture = 0
  AND i.Tradeable = 1
  AND f.DateID BETWEEN 20260101 AND 20260331
  AND f.ActionTypeID IN (1, 2, 3, 39)   -- opening actions; see position-state-and-grain.md
GROUP BY f.DateID
ORDER BY f.DateID;
```
**Use when:** "Tesla trading volume", "BTC volume by month", "volume for ticker X" — the DDR fact aggregates at type level, so per-ticker MUST go through `w_metrics`.

### Pattern 5 — Active traders count (trade-based, NOT the official segment)
```sql
SELECT COUNT(DISTINCT RealCID) AS active_traders
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE CountOpenTransactions > 0
  AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "how many people traded?", "unique traders this quarter". **Not** the official Active Trader segment — for that route to `domain-customer-and-identity` and the `customer-populations` DE workspace skill.

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

### Pattern 9 — Leverage / direction / margin breakdown
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
**Use when:** "leveraged vs unleveraged volume", "long vs short stock volume", "margin trade volume". Remember `IsLeverage` has no 'd' — Warning #2.

---

## Cross-references

- Instrument filter rules (used by Pattern 4-alt) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Position state, copy detection at the row level → [`position-state-and-grain.md`](position-state-and-grain.md)
- End-of-day stock (AUM, NOP, equity) → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Revenue from these trades → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Official Active Trader segment → `customer-populations` DE workspace skill (load via `../domain-customer-and-identity/SKILL.md`)
- Margin-trade economics, the `SettlementTypeID = 5` rule → `position-state-and-grain.md` (SettlementTypeID map)

## Sources Consulted (per `/speckit.skill` Phase 2.5)

`Class`: S = Synapse-first. `Tier`: 1a wiki, 1b UC comment, 3 lineage, 4 live distincts.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| Fact_Trading_Volumes_And_Amounts | S | 1a | knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.{md,lineage.md} | 25-col reference; SP_DDR + Function_Trading_Volume_PositionLevel pipeline; SP authored 2025-04-20 with IsSQF/IsMarginTrade/IsC2P additions in 2025-2026; BI_DB_VolumeQA parallel dump |
| Fact_Trading_Volumes_And_Amounts | S | 1a | knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Trading_Volume_PositionLevel.md | The TVF that produces 32 columns per position event — source of the `IsLeverage = CASE WHEN Leverage > 1`, `IsCopy = CASE WHEN MirrorID > 0`, `IsMarginTrade = CASE WHEN SettlementTypeID = 5` derivations |
| Fact_Trading_Volumes_And_Amounts | S | 1b | UC information_schema.columns (live) | 30 cols (27 data + 3 partition). Type asymmetry confirmed: `IsOpenedFromIBAN`=STRING / `IsClosedToIBAN`=INT. BIGINT volumes vs DECIMAL(19,4) money amounts |
| (any) | - | 4 | UC SELECT by TypeID×IsSettled (April-May 2026 sample) | Live row distribution: Real Stocks 4.17M / CFD Stocks 848K / Real Crypto 763K / CFD Crypto 86K / Real ETF 443K / CFD ETF 738K / Commodities 1.22M (mostly CFD) / Indices 630K (all CFD) / Forex 163K. **TypeID 9 has zero rows** — wiki claim that "Options always real" appears here is not currently active |

## Provenance

v2 rebuilt 2026-05-11 per `/speckit.skill` Phase 2.5. Deeply incorporates the DE workspace-root skill `trading-volumes` (v1 from 2026-05-07) and adds three new content sources: the BI_DB DDR fact wiki, the `Function_Trading_Volume_PositionLevel` wiki, and live UC schema + distinct-value verifications. **Key v2 additions vs v1**: Warning #1 expanded with the **`IsOpenedFromIBAN` STRING / `IsClosedToIBAN` INT asymmetry**; Warning #2 new — **`IsLeverage` (no 'd') naming quirk**; Warning #4 new — **`TotalVolume ≠ SUM(Open) + SUM(Close)` at the aggregated level**; Warning #5 new — **BIGINT volume / DECIMAL(19,4) money type quirks**; Warning #10 new — **`IsSQF` semantic ambiguity** between this skill family and the instruments skill; Warning #12 new — **`BI_DB_VolumeQA`** parallel position-level dump (Synapse-only); 6 new dimension columns documented (`IsBuy`, `IsLeverage`, `IsFuture`, `IsClosedToIBAN`, `IsSQF`, `IsMarginTrade`); live asset-class row-count and notional table; Pattern 4-alt (per-ticker volume MUST go through `w_metrics`, not this fact); Pattern 6 (the Copy / Smart Portfolio / C2P three-flag breakdown); Pattern 9 (leverage × direction × margin breakdown). Broker-side classification explicitly stated.
