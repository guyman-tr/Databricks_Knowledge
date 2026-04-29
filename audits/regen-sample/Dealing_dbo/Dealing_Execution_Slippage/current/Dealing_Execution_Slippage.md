# Dealing_dbo.Dealing_Execution_Slippage

> Position-level daily hedging slippage report comparing the provider's actual execution rate to eToro's prevailing price at the time the order was sent (SendTime vs ExecutionTime method).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging.Etoro_Hedge_ExecutionLog + CopyFromLake.PriceLog_History_CurrencyPrice + CopyFromLake.PricesFromProvider_MarketCurrencyPrice |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table records the daily slippage experienced by eToro's hedging desk at the position level. "Slippage" is the price difference between the rate at which eToro's Liquidity Provider (LP) actually executed a hedge order and the mid-price eToro had in its own price feed at the moment the order was sent. A positive `SlippageInDollar` indicates the LP gave eToro a better price than the eToro book (favorable), while a negative value means eToro paid more than expected (cost).

The data covers two hedging regimes: **CBH** (Clearing Broker Hedging — STP to external clearing brokers such as Apex, BNY VIRTU) and **HBC** (Hedge By Company — eToro acts as direct market maker). Each row represents a group of hedge transactions for a given InstrumentID/Occurred/ExecutionTime/HedgingMode combination, aggregated by `SUM(Units)` and `COUNT(*)` as `NumberofTransaction`.

Data source chain: eToro production server `etoro.Hedge.ExecutionLog` → Dealing_staging.Etoro_Hedge_ExecutionLog (daily copy) → eToro price from `CopyFromLake.PriceLog_History_CurrencyPrice` (per RateIDAtSent) → Kusto LP prices from `CopyFromLake.PricesFromProvider_MarketCurrencyPrice`. SP_Execution_Slippage (author Adar Cahlon, originally Aug 2021; migrated to Synapse Nov 2023, SR-218324) performs FX rate conversion via `DWH_dbo.Fact_CurrencyPriceWithSplit` and `DWH_dbo.Dim_Instrument`.

⚠️ **PIPELINE STALE**: Last row is 2024-10-03 (~5 months behind). Both `Dealing_Execution_Slippage` (SendTime method) and `Dealing_Execution_Slippage_AssetType` stopped updating in Oct 2024, while the RequestTime variants continued until Jan 2025. The most likely cause is a failure in the CopyFromLake.PricesFromProvider_MarketCurrencyPrice data feed (Kusto prices), which is required only by the SendTime calculation. The SP is still deployed; it is the data feed that appears broken.

---

## 2. Business Logic

### 2.1 SendTime vs ExecutionTime Slippage

**What**: Measures the price improvement or deterioration from the moment eToro's system sent the hedge order (Occurred = SendTime, matched via `RateIDAtSent` to get eToro's price from `PriceLog_History_CurrencyPrice`) to when the LP actually executed it (ExecutionTime).

**Columns Involved**: `Occurred`, `ExecutionTime`, `eToro_Price`, `ExecutionRate`, `Slippage`, `SlippageInDollar`, `Slippage_Percent`

**Rules**:
- `eToro_Price` = eToro's Ask (for buy orders) or Bid (for sell orders) from `PriceLog_History_CurrencyPrice` at `RateIDAtSent`
- `ExecutionRate` = the rate at which the LP confirmed execution
- `Slippage` (price diff) = `(IsBuy=1 ? 1 : -1) × (ExecutionRate - eToro_Price)` — in price units
- `SlippageInDollar` = `(IsBuy=1 ? 1 : -1) × (eToro_Price - ExecutionRate) × Units × FX_Rate` — in USD
- **Positive SlippageInDollar = favorable** (LP gave eToro a better price than the book price)
- **Negative SlippageInDollar = cost** (LP executed at a worse price than expected)
- `Slippage_Percent` = `(IsBuy=1 ? 1 : -1) × (ExecutionRate - eToro_Price) / eToro_Price`

### 2.2 Kusto Price Comparison

**What**: Additional data point comparing eToro's spreaded price (from its own system) against the LP's market data at the time of execution (Kusto = the LP's quote feed). Added Jun 2022.

**Columns Involved**: `KustoTime`, `Kusto_Price`, `BidSpreaded`, `AskSpreaded`

**Rules**:
- `Kusto_Price` = LP's Bid or Ask (depending on IsBuy) at the latest Kusto timestamp before ExecutionTime
- `KustoTime` = timestamp of that Kusto price record (via CROSS APPLY TOP 1 ORDER BY OccurredAtServer DESC)
- `BidSpreaded` / `AskSpreaded` = eToro's own spreaded prices at SendTime

### 2.3 FX Rate Conversion

**What**: All slippage amounts are converted to USD regardless of instrument denomination.

**Columns Involved**: `FX_Rate`, `ProviderAmount_USD`, `eToro_AmountUSD`

**Rules**:
- `FX_Rate` = conversion factor from instrument's settlement currency to USD. Derived via `DWH_dbo.Fact_CurrencyPriceWithSplit` and `DWH_dbo.Dim_Instrument` with currency chain logic (SellCurrencyID=1→1.0; BuyCurrencyID=1→1/ForexRate; SellCurrencyID=666/GBX→rate/100)
- `ProviderAmount_USD` = `SUM(Units × ExecutionRate × FX_Rate)` — total value at provider's price
- `eToro_AmountUSD` = `SUM(Units × eToro_Price × FX_Rate)` — total value at eToro's price

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table uses ROUND_ROBIN distribution (no natural key for hash — each row is a per-instrument/occurred/executionTime tuple). The CLUSTERED INDEX is on `Date ASC`, making date-range queries efficient but cross-date joins may produce full scans. Always include a `Date` or date range filter. Avoid joining on `InstrumentID` alone without a date filter (4.78M rows, Jan 2023–Oct 2024).

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, partition by `Date` (daily partition) for efficient date-range access. Z-ORDER on `InstrumentID` within partitions if querying specific instruments across dates.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total daily slippage cost to eToro (by hedging mode) | `SELECT Date, HedgingMode, SUM(SlippageInDollar) FROM Dealing_Execution_Slippage WHERE Date BETWEEN @start AND @end GROUP BY Date, HedgingMode` |
| Per-instrument slippage for a date | `SELECT InstrumentID, SUM(SlippageInDollar), AVG(Slippage_Percent) FROM Dealing_Execution_Slippage WHERE Date = @date GROUP BY InstrumentID` |
| Kusto vs eToro price deviation | Join `KustoTime` / `Kusto_Price` vs `Occurred` / `eToro_Price` for LP transparency analysis |
| Volume-weighted avg slippage % | `SUM(Slippage_Percent * Units) / SUM(Units)` for VWAS |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID = InstrumentID | Resolve InstrumentID to name, type, currency |

### 3.4 Gotchas

- **Pipeline is stale** — max date is 2024-10-03. Do not use for recent slippage analysis; use `Dealing_Execution_Slippage_RequestTime` (last 2025-01-11) or `Dealing_Daily_Slippage_Totals` (last 2025-01-11) for more recent data.
- **Aggregated rows, not one-per-position** — the SP groups by InstrumentID/Occurred/ExecutionTime/ExecutionRate/HedgingMode; `NumberofTransaction` shows how many individual trades were aggregated into each row.
- **HedgingMode 'CBH' = majority** — most rows are CBH (external clearing broker STP); HBC is eToro market-making.
- **GBX instruments** — FX_Rate is divided by 100 for GBX (pence) instruments. `FX_Rate` is already adjusted.
- **`Success=1` filter** — only successful hedge executions are included (`WHERE Success=1 AND HedgeServerID<>5000 AND ExecutionRate<>0`).
- **ROUND_ROBIN distribution** — no data skew but broadcast joins with large dimension tables are expensive in Synapse. Always filter by `Date` first.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — upstream wiki verbatim | `(Tier 1 — upstream wiki, {source})` |
| ★★★ | Tier 2 — Synapse SP code | `(Tier 2 — SP_Execution_Slippage)` |
| ★★ | Tier 3 — live data / DDL structure | `(Tier 3 — live data)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Partition date: the calendar date on which the hedge executions occurred. Used as the daily load key (DELETE WHERE Date = @Date before insert). (Tier 2 — SP_Execution_Slippage) |
| 2 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 — upstream wiki, Trade.Instrument) |
| 3 | Occurred | datetime | YES | eToro's SendTime for the hedge order — the datetime stamp from `PriceLog_History_CurrencyPrice` matched by `RateIDAtSent`. This is the moment eToro's system requested the hedge. Used as the basis for eToro_Price lookup. (Tier 2 — SP_Execution_Slippage) |
| 4 | ExecutionTime | datetime | YES | The datetime at which the LP confirmed execution of the hedge order, per `Dealing_staging.Etoro_Hedge_ExecutionLog`. This is the actual fill timestamp. (Tier 2 — SP_Execution_Slippage) |
| 5 | IsBuy | bit | YES | Direction of the hedge: 1=Buy (eToro is buying from LP), 0=Sell (eToro is selling to LP). For open positions IsBuy follows position direction; for closes it is inverted (`CASE WHEN HP.IsBuy = 1 THEN 0 ELSE 1 END` for closed positions). (Tier 2 — SP_Execution_Slippage) |
| 6 | Units | decimal(16,6) | YES | Total hedged units (size) aggregated across all transactions in this row: `SUM(Units)` where Units is the hedge execution quantity from Etoro_Hedge_ExecutionLog. (Tier 2 — SP_Execution_Slippage) |
| 7 | ExecutionRate | decimal(16,6) | YES | The rate at which the LP actually executed the hedge order, from `Dealing_staging.Etoro_Hedge_ExecutionLog.ExecutionRate`. This is the price eToro received from the provider. (Tier 2 — SP_Execution_Slippage) |
| 8 | eToro_Price | decimal(16,6) | YES | eToro's own price (Ask for buy, Bid for sell) at SendTime, from `CopyFromLake.PriceLog_History_CurrencyPrice` matched by `RateIDAtSent`. This is the reference price against which slippage is measured. Formula: `CASE WHEN IsBuy=1 THEN Ask ELSE Bid END`. (Tier 2 — SP_Execution_Slippage) |
| 9 | ProviderAmount_USD | decimal(16,6) | YES | Total USD value at the provider's execution rate: `SUM(Units × ExecutionRate × FX_Rate)`. Represents what eToro actually paid/received for the hedges. (Tier 2 — SP_Execution_Slippage) |
| 10 | eToro_AmountUSD | decimal(16,6) | YES | Total USD value at eToro's own price: `SUM(Units × eToro_Price × FX_Rate)`. Represents what eToro expected to pay/receive based on its book price. (Tier 2 — SP_Execution_Slippage) |
| 11 | FX_Rate | decimal(16,6) | YES | Currency conversion factor to USD for the instrument's settlement currency. Computed via instrument's SellCurrencyID chain: SellCurrencyID=1(USD)→1.0; BuyCurrencyID=1→1/ForexRate; GBX(666)→rate÷100; other→cross-rate via Fact_CurrencyPriceWithSplit. (Tier 2 — SP_Execution_Slippage) |
| 12 | Slippage | decimal(16,6) | YES | Price-unit slippage: `(IsBuy=1 ? 1 : -1) × (ExecutionRate − eToro_Price)`. Positive = provider's rate was worse than eToro's price (cost); negative = provider gave a better rate (gain). (Tier 2 — SP_Execution_Slippage) |
| 13 | SlippageInDollar | decimal(16,6) | YES | USD monetary slippage: `(IsBuy=1 ? 1 : -1) × (eToro_Price − ExecutionRate) × Units × FX_Rate`. Positive = eToro gained (favorable execution); negative = eToro paid more (cost). (Tier 2 — SP_Execution_Slippage) |
| 14 | Slippage_Percent | decimal(16,6) | YES | Percentage slippage relative to eToro's price: `(IsBuy=1 ? 1 : -1) × (ExecutionRate − eToro_Price) / eToro_Price`. Useful for comparing slippage across instruments of different price scales. (Tier 2 — SP_Execution_Slippage) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Execution_Slippage (`GETDATE()` at insert time). (Tier 2 — SP_Execution_Slippage) |
| 16 | HedgingMode | varchar(10) | YES | Hedging regime: `CBH` (Clearing Broker Hedging — STP to external clearing broker, e.g., Apex, BNY VIRTU) or `HBC` (Hedge By Company — eToro trades directly as market maker). Derived from `Dealing_staging.Etoro_Hedge_HBCOrderLog` lookup: `CASE WHEN hl.OrderID IS NOT NULL THEN 'HBC' ELSE 'CBH' END`. (Tier 2 — SP_Execution_Slippage) |
| 17 | KustoTime | datetime | YES | Timestamp of the most recent LP quote from Kusto (CopyFromLake.PricesFromProvider_MarketCurrencyPrice) at or before ExecutionTime. Fetched via `CROSS APPLY TOP 1 ORDER BY OccurredAtServer DESC`. Used to compare LP's own market data with their execution price. (Tier 2 — SP_Execution_Slippage) |
| 18 | Kusto_Price | decimal(16,6) | YES | LP's market price at KustoTime: `CASE WHEN IsBuy=1 THEN AskKusto ELSE BidKusto END` from PricesFromProvider_MarketCurrencyPrice. Allows comparison of LP's published market rate vs their actual execution rate (true LP slippage). (Tier 2 — SP_Execution_Slippage) |
| 19 | BidSpreaded | decimal(16,6) | YES | eToro's spreaded Bid price at SendTime from CopyFromLake.PriceLog_History_CurrencyPrice. The eToro price after spread markup has been applied. Added Jun 2022. (Tier 2 — SP_Execution_Slippage) |
| 20 | AskSpreaded | decimal(16,6) | YES | eToro's spreaded Ask price at SendTime from CopyFromLake.PriceLog_History_CurrencyPrice. The eToro price after spread markup has been applied. Added Jun 2022. (Tier 2 — SP_Execution_Slippage) |
| 21 | NumberofTransaction | int | YES | Count of individual hedge transactions aggregated into this row: `COUNT(*)` per InstrumentID/Occurred/ExecutionTime/ExecutionRate/HedgingMode group. Added Nov 2023 (SR-220487). (Tier 2 — SP_Execution_Slippage) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ExecutionRate | etoro.Hedge.ExecutionLog (via Dealing_staging) | ExecutionRate | Passthrough |
| ExecutionTime | etoro.Hedge.ExecutionLog | ExecutionTime | Passthrough |
| IsBuy | etoro.Hedge.ExecutionLog | IsBuy | Passthrough |
| Units | etoro.Hedge.ExecutionLog | Units | SUM() per group |
| eToro_Price | etoro.Price.CurrencyPrice (via CopyFromLake.PriceLog_History) | Bid/Ask | CASE IsBuy → Ask/Bid |
| Kusto_Price | CopyFromLake.PricesFromProvider_MarketCurrencyPrice | Bid/Ask | CASE IsBuy → closest time match |
| InstrumentID | etoro.Hedge.ExecutionLog | InstrumentID | Passthrough |

### 5.2 ETL Pipeline

```
etoro.Hedge.ExecutionLog → Dealing_staging.Etoro_Hedge_ExecutionLog (daily copy)
etoro.Price.CurrencyPrice → CopyFromLake.PriceLog_History_CurrencyPrice (Generic Pipeline)
LP MarketData (Kusto) → CopyFromLake.PricesFromProvider_MarketCurrencyPrice
All three → SP_Execution_Slippage (@Date) → Dealing_Execution_Slippage (DELETE+INSERT by Date)
```

| Step | Object | Description |
|------|--------|-------------|
| Source 1 | etoro.Hedge.ExecutionLog | Raw hedge execution events from production |
| Source 2 | etoro.Price.CurrencyPrice | eToro's price log (matched by RateIDAtSent) |
| Source 3 | LP Market Data (Kusto) | LP's own quote feed for reference |
| ETL | SP_Execution_Slippage | FX conversion, slippage computation, aggregation |
| Target | Dealing_Execution_Slippage | Daily position-level slippage, SendTime method |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolve to InstrumentName, InstrumentType, currency |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_Execution_Slippage_AssetType | (derived) | Same SP aggregates by InstrumentType+HedgingMode |

---

## 7. Sample Queries

### 7.1 Daily total slippage cost by hedging mode
```sql
SELECT
    Date,
    HedgingMode,
    SUM(SlippageInDollar) AS TotalSlippage_USD,
    COUNT(*) AS HedgeTrades,
    SUM(NumberofTransaction) AS TotalTransactions
FROM Dealing_dbo.Dealing_Execution_Slippage
WHERE Date BETWEEN '2024-01-01' AND '2024-10-03'
GROUP BY Date, HedgingMode
ORDER BY Date DESC, HedgingMode
```

### 7.2 Worst slippage instruments (negative = cost to eToro)
```sql
SELECT TOP 20
    es.InstrumentID,
    di.Name AS InstrumentName,
    di.InstrumentType,
    SUM(es.SlippageInDollar) AS TotalSlippage_USD,
    AVG(es.Slippage_Percent) AS AvgSlippagePct
FROM Dealing_dbo.Dealing_Execution_Slippage es
JOIN DWH_dbo.Dim_Instrument di ON es.InstrumentID = di.InstrumentID
WHERE es.Date >= '2024-01-01'
GROUP BY es.InstrumentID, di.Name, di.InstrumentType
ORDER BY TotalSlippage_USD ASC -- most negative = worst cost
```

### 7.3 Kusto vs eToro price comparison (LP transparency)
```sql
SELECT
    Date,
    InstrumentID,
    HedgingMode,
    AVG(ABS(Kusto_Price - eToro_Price)) AS AvgKustoVsEtoroPriceDiff,
    SUM(SlippageInDollar) AS SlippageFromEtoroPrice
FROM Dealing_dbo.Dealing_Execution_Slippage
WHERE Date >= '2024-06-01' -- Kusto data added Jun 2022 (SR-257525 changed source Jun 2024)
  AND Kusto_Price IS NOT NULL
GROUP BY Date, InstrumentID, HedgingMode
ORDER BY Date DESC
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| SR-218324 | Jira | Migration to Synapse (Nov 2023) |
| SR-257525 | Jira | Changed price sources to CopyFromLake (Jun 2024) — likely cause of pipeline stale state |
| SR-220487 | Jira | Added NumberofTransaction column; changed aggregation from per-trade to per-group (Nov 2023) |

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★) | Phases: P1/P2/P3/P8/P9/P10.5 (P4/P5/P6/P7/P9B/P10 skipped — no lookup cols, no joined views, no orchestration deps, Atlassian MCP unavailable)*
