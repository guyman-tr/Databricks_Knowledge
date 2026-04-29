# Dealing_dbo.Dealing_Execution_Slippage

> 4.78M-row daily execution slippage table measuring the difference between eToro's SendTime quoted price and the LP's actual fill rate, per (InstrumentID × Occurred × ExecutionTime × IsBuy × ExecutionRate × HedgingMode) execution group. Covers 2023-01-01 to 2024-10-03. Produced by `SP_Execution_Slippage`. **PIPELINE STALE**: last populated 2024-10-03 — the Kusto LP price feed (`CopyFromLake.PricesFromProvider_MarketCurrencyPrice`) stopped supplying data. Use `Dealing_Execution_Slippage_RequestTime` for current slippage data.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging.Etoro_Hedge_ExecutionLog + CopyFromLake.PriceLog_History_CurrencyPrice + CopyFromLake.PricesFromProvider_MarketCurrencyPrice via SP_Execution_Slippage |
| **Refresh** | Daily (per-date delete+insert via @Date parameter) — STALE since 2024-10-03 |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| | |
| **UC Target** | _Not_Migrated (no Generic Pipeline mapping) |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`Dealing_dbo.Dealing_Execution_Slippage` captures row-level daily execution slippage using the **SendTime price** as the eToro reference point. For each execution group — defined as a unique combination of (InstrumentID, Occurred, ExecutionTime, IsBuy, ExecutionRate, HedgingMode, FX_Rate, KustoTime, Kusto_Price, BidSpreaded, AskSpreaded) — the table records the eToro quoted price at the moment the hedge order was sent (`Occurred` via `RateIDAtSent`) versus the LP's actual fill rate (`ExecutionRate`), along with the Kusto LP market price at execution time and USD-denominated P&L impact.

This is the SendTime variant of the slippage pipeline. Its counterpart, `Dealing_Execution_Slippage_RequestTime`, uses the most recent eToro price event before ExecutionTime instead. Both are produced by a single SP (`SP_Execution_Slippage`) in the same daily run.

**Pipeline dependency**: This table requires a valid Kusto LP market price per trade via `CROSS APPLY` on `CopyFromLake.PricesFromProvider_MarketCurrencyPrice`. When the Kusto feed has no data for a given date, the `#KustoPrices` temp table is empty, making `#Total` empty, and no rows are inserted. This is why the pipeline stopped producing data after 2024-10-03 while the RequestTime variant (which does not use Kusto) continued until 2025-01-11.

Data covers 2023-01-01 to 2024-10-03 with approximately 4.78M rows across ~7,500+ distinct instruments. In 2023, both CBH (Clearing Broker Hedging) and HBC (Hedge By Company) hedging modes were present; in 2024, only CBH remains in the data. Typical daily volume is 500–700 execution groups, with ~2 raw execution log records aggregated per group. The sell-side (IsBuy=0) dominates at ~92% of rows.

**Slippage sign convention**:
- `Slippage` (points): positive = eToro cost (LP fill worse than eToro's SendTime price)
- `SlippageInDollar`: positive = eToro gains (opposite sign to Slippage — both from eToro's perspective)
- `Slippage_Percent`: same sign convention as Slippage

---

## 2. Business Logic

### 2.1 SendTime Price Matching

**What**: The eToro reference price is determined by the `RateIDAtSent` foreign key from the execution log, which points to a specific price record in `CopyFromLake.PriceLog_History_CurrencyPrice`.

**Columns Involved**: `Occurred`, `eToro_Price`, `BidSpreaded`, `AskSpreaded`

**Rules**:
- The SP joins `#ExecutionRate` to `PriceLog_History_CurrencyPrice` on `PriceRateID = RateIDAtSent`
- `eToro_Price` = Ask (for IsBuy=1) or Bid (for IsBuy=0) from that price record
- `Occurred` = the timestamp of that price record (when the price was observed)
- `BidSpreaded` and `AskSpreaded` are passed through from the same price record

### 2.2 Kusto LP Price Matching

**What**: The Kusto market price captures what the liquidity provider's market was showing at the time of execution, sourced from `PricesFromProvider_MarketCurrencyPrice`.

**Columns Involved**: `KustoTime`, `Kusto_Price`

**Rules**:
- Via CROSS APPLY: find the most recent `OccurredAtServer` in `PricesFromProvider_MarketCurrencyPrice` where `OccurredAtServer <= ExecutionTime` for the same InstrumentID
- `KustoTime` = that `OccurredAtServer` timestamp
- `Kusto_Price` = AskKusto (for IsBuy=1) or BidKusto (for IsBuy=0)
- If no Kusto price exists for the instrument/date, the CROSS APPLY produces no row → the entire execution is excluded from this table

### 2.3 Slippage Computation

**What**: Three slippage measures computed from the difference between eToro's quoted price and the LP's actual fill rate.

**Columns Involved**: `Slippage`, `SlippageInDollar`, `Slippage_Percent`

**Rules**:
- `Slippage = (IsBuy=1 ? +1 : -1) × (ExecutionRate − eToro_Price)` — in price units
- `SlippageInDollar = (IsBuy=1 ? +1 : -1) × (eToro_Price − ExecutionRate) × Units × FX_Rate` — in USD
- `Slippage_Percent = (IsBuy=1 ? +1 : -1) × (ExecutionRate − eToro_Price) / eToro_Price` — relative
- Note: Slippage and SlippageInDollar have **opposite signs** — both are "from eToro's perspective" but one measures cost (points) and the other measures gain (dollars)

**Diagram**:
```
For each execution group:
  Slippage (points):  +ve = LP filled worse than eToro quoted = eToro COST
  SlippageInDollar:   +ve = LP filled better than eToro quoted = eToro GAIN
  Slippage_Percent:   same direction as Slippage (points)
```

### 2.4 USD Conversion (FX_Rate)

**What**: Converts instrument-currency slippage amounts into USD using cross-currency logic from `Fact_CurrencyPriceWithSplit`.

**Columns Involved**: `FX_Rate`, `ProviderAmount_USD`, `eToro_AmountUSD`, `SlippageInDollar`

**Rules**:
- If `SellCurrencyID = 1` (USD is quote currency): FX_Rate = 1.0
- If `BuyCurrencyID = 1` (USD is base currency): FX_Rate = 1 / Bid (buy) or 1 / Ask (sell)
- If `SellCurrencyID = 666` (GBX — pence sterling): FX_Rate = 100 × cross-rate (pence-to-pounds conversion)
- Otherwise: cross-rate via a USD-paired instrument, with COALESCE fallback to 1.0
- GBX instruments get an additional ÷100 adjustment in `#ExecutionRate`

### 2.5 Execution Group Aggregation

**What**: Multiple raw execution log entries with identical (InstrumentID, Occurred, ExecutionTime, IsBuy, ExecutionRate, HedgingMode, FX_Rate, eToro_Price, KustoTime, Kusto_Price, BidSpreaded, AskSpreaded) are summed into one row.

**Columns Involved**: `Units`, `ProviderAmount_USD`, `eToro_AmountUSD`, `NumberofTransaction`

**Rules**:
- `Units` = SUM(Units) from raw records
- `ProviderAmount_USD` = SUM(Units × ExecutionRate × FX_Rate)
- `eToro_AmountUSD` = SUM(Units × eToro_Price × FX_Rate)
- `NumberofTransaction` = COUNT(*) — typically 2 per group (min=2, max=4 in recent data)

### 2.6 Hedging Mode Classification

**What**: Each execution is classified as CBH or HBC based on whether a matching record exists in the HBC order log.

**Columns Involved**: `HedgingMode`

**Rules**:
- `CBH` (Clearing Broker Hedging): execution routed to external clearing broker (Apex/BNY Mellon) — default
- `HBC` (Hedge By Company): eToro internalizes the position — determined by `LEFT JOIN Dealing_staging.Etoro_Hedge_HBCOrderLog ON OrderID = HedgeID`
- If the HBCOrderLog contains the OrderID → HBC; otherwise → CBH
- In 2023 both modes are present (~90% CBH, ~10% HBC). In 2024 only CBH appears

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `[Date]`. Always include `Date` in WHERE clauses for efficient range scans. ROUND_ROBIN means no data skew but full cross-node broadcast for JOINs — acceptable given typical analytical query patterns.

### 3.1b UC (Databricks) Storage & Partitioning

Not migrated to Unity Catalog. No Generic Pipeline mapping exists.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily net slippage by hedging mode | `SELECT Date, HedgingMode, SUM(SlippageInDollar) ... GROUP BY Date, HedgingMode WHERE Date BETWEEN ...` |
| Worst-slippage instruments in a period | `GROUP BY InstrumentID` with `SUM(SlippageInDollar) ORDER BY ... ASC` + JOIN Dim_Instrument |
| Execution latency analysis | `DATEDIFF(ms, Occurred, ExecutionTime)` — time from eToro price event to LP fill |
| Compare SendTime vs RequestTime slippage | JOIN to `Dealing_Execution_Slippage_RequestTime` on Date + InstrumentID + ExecutionTime |
| Use the aggregate view by asset class | Query `Dealing_Execution_Slippage_AssetType` instead |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, type, asset class |
| Dealing_dbo.Dealing_Execution_Slippage_RequestTime | ON Date + InstrumentID + ExecutionTime | Compare SendTime vs RequestTime slippage for same executions |
| Dealing_dbo.Dealing_Execution_Slippage_AssetType | ON Date | Compare to aggregated slippage by asset type |

### 3.4 Gotchas

- **PIPELINE STALE since 2024-10-03**: The Kusto LP price feed (`PricesFromProvider_MarketCurrencyPrice`) stopped supplying data. Use `Dealing_Execution_Slippage_RequestTime` for current data (last updated 2025-01-11).
- **Slippage and SlippageInDollar have opposite signs**: Slippage (points) positive = eToro cost; SlippageInDollar positive = eToro gain. This is intentional — both from eToro's perspective but measuring different things.
- **NumberofTransaction is typically 2**: Each row aggregates ~2 raw execution log records. The total raw trade count is `SUM(NumberofTransaction)`, not `COUNT(*)`.
- **HBC hedging mode disappeared in 2024**: Only CBH rows exist after 2023-12-19. HBC-specific analysis should filter to 2023 data.
- **KustoTime and Kusto_Price are REQUIRED**: Unlike the RequestTime variant, this table's pipeline requires a valid Kusto LP price per trade. If Kusto data is missing for an instrument on a date, those executions are silently excluded.
- **Oct 3 2024 is a partial day**: Only 52 rows vs typical ~600–700, suggesting the pipeline ran but Kusto data was already degraded.
- **ExecutionRate = 0 records are excluded**: The SP filters `WHERE er.ExecutionRate <> 0` and `HedgeServerID <> 5000`.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 — domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 — upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 — SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 — live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 — inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date (UTC) for which slippage is computed. Equals the @Date parameter passed to SP_Execution_Slippage. Clustered index key — always include in WHERE for efficient range scans. (Tier 2 — SP_Execution_Slippage) |
| 2 | InstrumentID | int | YES | Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Identifies the hedged instrument. 75 distinct instruments in recent data (Sep–Oct 2024). (Tier 1 — Trade.Instrument) |
| 3 | Occurred | datetime | YES | Timestamp of the eToro price event at SendTime, from CopyFromLake.PriceLog_History_CurrencyPrice matched by RateIDAtSent. This is when eToro's quoted price was recorded. Millisecond precision. (Tier 2 — SP_Execution_Slippage) |
| 4 | ExecutionTime | datetime | YES | Actual LP fill timestamp from Dealing_staging.Etoro_Hedge_ExecutionLog. Millisecond precision. Use `DATEDIFF(ms, Occurred, ExecutionTime)` for execution latency analysis. (Tier 2 — SP_Execution_Slippage) |
| 5 | IsBuy | bit | YES | 1 = buy (long) position, 0 = sell (short). Determines slippage sign direction and which price column (Ask vs Bid) is used for eToro_Price and Kusto_Price. ~92% sells in recent data. (Tier 2 — SP_Execution_Slippage) |
| 6 | Units | decimal(16,6) | YES | Total units traded in this execution group. SUM(Units) from raw Etoro_Hedge_ExecutionLog records. Average ~1,035 units per group in recent data. (Tier 2 — SP_Execution_Slippage) |
| 7 | ExecutionRate | decimal(16,6) | YES | LP fill rate in instrument currency from Etoro_Hedge_ExecutionLog. Non-zero (SP filters ExecutionRate <> 0). Group-by key — identical across aggregated raw records. (Tier 2 — SP_Execution_Slippage) |
| 8 | eToro_Price | decimal(16,6) | YES | eToro's quoted price at SendTime. Ask for buys (IsBuy=1), Bid for sells (IsBuy=0). Source: CopyFromLake.PriceLog_History_CurrencyPrice matched via RateIDAtSent. Compare to ExecutionRate for slippage. (Tier 2 — SP_Execution_Slippage) |
| 9 | ProviderAmount_USD | decimal(16,6) | YES | Total LP cost in USD: SUM(Units × ExecutionRate × FX_Rate). What eToro actually paid the LP for this execution group in USD terms. (Tier 2 — SP_Execution_Slippage) |
| 10 | eToro_AmountUSD | decimal(16,6) | YES | eToro expected cost at SendTime in USD: SUM(Units × eToro_Price × FX_Rate). What eToro expected to pay based on its quoted price. Difference from ProviderAmount_USD is the slippage. (Tier 2 — SP_Execution_Slippage) |
| 11 | FX_Rate | decimal(16,6) | YES | USD conversion factor. 1.0 for USD-denominated instruments. Computed from DWH_dbo.Fact_CurrencyPriceWithSplit via cross-currency logic: SellCurrencyID=1 → 1.0; BuyCurrencyID=1 → 1/Bid or 1/Ask; GBX → ÷100 adjustment; else cross-rate with COALESCE fallback to 1.0. (Tier 2 — SP_Execution_Slippage) |
| 12 | Slippage | decimal(16,6) | YES | Price-unit slippage: (IsBuy=1 ? +1 : -1) × (ExecutionRate − eToro_Price). Positive = eToro cost (LP fill worse than eToro's SendTime price). Opposite sign to SlippageInDollar. (Tier 2 — SP_Execution_Slippage) |
| 13 | SlippageInDollar | decimal(16,6) | YES | USD slippage: (IsBuy=1 ? +1 : -1) × (eToro_Price − ExecutionRate) × Units × FX_Rate. Positive = eToro gains (LP executed at better rate). Note: opposite sign to Slippage. Average −$0.004 per group in recent data. (Tier 2 — SP_Execution_Slippage) |
| 14 | Slippage_Percent | decimal(16,6) | YES | Relative slippage: (IsBuy=1 ? +1 : -1) × (ExecutionRate − eToro_Price) / eToro_Price. Same sign convention as Slippage (points). Dimensionless ratio. (Tier 2 — SP_Execution_Slippage) |
| 15 | UpdateDate | datetime | YES | Row insertion timestamp (GETDATE() at SP run time). Not a business date — use Date for temporal filtering. (Tier 2 — SP_Execution_Slippage) |
| 16 | HedgingMode | varchar(10) | YES | Routing mode for the execution. CBH = Clearing Broker Hedging (Apex/BNY Mellon); HBC = Hedge By Company (eToro internal). Determined by LEFT JOIN to Dealing_staging.Etoro_Hedge_HBCOrderLog: if OrderID found → HBC, else → CBH. HBC absent from 2024 data. (Tier 2 — SP_Execution_Slippage) |
| 17 | KustoTime | datetime | YES | Timestamp of the Kusto LP market price event (OccurredAtServer from PricesFromProvider_MarketCurrencyPrice). Latest Kusto price with OccurredAtServer ≤ ExecutionTime via CROSS APPLY. Required — rows without a Kusto match are excluded. (Tier 2 — SP_Execution_Slippage) |
| 18 | Kusto_Price | decimal(16,6) | YES | Kusto LP market price at KustoTime. Ask for buys (IsBuy=1), Bid for sells (IsBuy=0). Source: PricesFromProvider_MarketCurrencyPrice. Compare to eToro_Price for cross-source price validation. (Tier 2 — SP_Execution_Slippage) |
| 19 | BidSpreaded | decimal(16,6) | YES | Spread-adjusted bid price from CopyFromLake.PriceLog_History_CurrencyPrice at SendTime. The bid price with broker spread applied. Passed through from the same price record as eToro_Price. (Tier 2 — SP_Execution_Slippage) |
| 20 | AskSpreaded | decimal(16,6) | YES | Spread-adjusted ask price from CopyFromLake.PriceLog_History_CurrencyPrice at SendTime. The ask price with broker spread applied. Passed through from the same price record as eToro_Price. (Tier 2 — SP_Execution_Slippage) |
| 21 | NumberofTransaction | int | YES | Count of raw Etoro_Hedge_ExecutionLog records summed into this execution group. Typically 2 per row (min=2, max=4 in recent data). Use SUM(NumberofTransaction) for total trade count, not COUNT(*). (Tier 2 — SP_Execution_Slippage) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP parameter | @Date | Direct assignment |
| InstrumentID | Dealing_staging.Etoro_Hedge_ExecutionLog | InstrumentID | Passthrough |
| Occurred | CopyFromLake.PriceLog_History_CurrencyPrice | Occurred | Passthrough (via RateIDAtSent JOIN) |
| ExecutionTime | Dealing_staging.Etoro_Hedge_ExecutionLog | ExecutionTime | Passthrough |
| IsBuy | Dealing_staging.Etoro_Hedge_ExecutionLog | IsBuy | Passthrough |
| Units | Dealing_staging.Etoro_Hedge_ExecutionLog | Units | SUM per execution group |
| ExecutionRate | Dealing_staging.Etoro_Hedge_ExecutionLog | ExecutionRate | Passthrough (group-by key) |
| eToro_Price | CopyFromLake.PriceLog_History_CurrencyPrice | Ask / Bid | CASE IsBuy=1 THEN Ask ELSE Bid |
| ProviderAmount_USD | Computed | Units, ExecutionRate, FX_Rate | SUM(Units × ExecutionRate × FX_Rate) |
| eToro_AmountUSD | Computed | Units, eToro_Price, FX_Rate | SUM(Units × eToro_Price × FX_Rate) |
| FX_Rate | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid, Ask | Cross-currency CASE logic |
| Slippage | Computed | ExecutionRate, eToro_Price, IsBuy | (±1) × (ExecutionRate − eToro_Price) |
| SlippageInDollar | Computed | eToro_Price, ExecutionRate, Units, FX_Rate | (±1) × (eToro_Price − ExecutionRate) × Units × FX_Rate |
| Slippage_Percent | Computed | ExecutionRate, eToro_Price, IsBuy | (±1) × (ExecutionRate − eToro_Price) / eToro_Price |
| UpdateDate | ETL-computed | — | GETDATE() |
| HedgingMode | Dealing_staging.Etoro_Hedge_HBCOrderLog | OrderID presence | CASE: found → HBC, else → CBH |
| KustoTime | CopyFromLake.PricesFromProvider_MarketCurrencyPrice | OccurredAtServer | Passthrough (CROSS APPLY latest ≤ ExecutionTime) |
| Kusto_Price | CopyFromLake.PricesFromProvider_MarketCurrencyPrice | Ask / Bid | CASE IsBuy=1 THEN AskKusto ELSE BidKusto |
| BidSpreaded | CopyFromLake.PriceLog_History_CurrencyPrice | BidSpreaded | Passthrough from SendTime record |
| AskSpreaded | CopyFromLake.PriceLog_History_CurrencyPrice | AskSpreaded | Passthrough from SendTime record |
| NumberofTransaction | Computed | — | COUNT(*) per execution group |

### 5.2 ETL Pipeline

```
Dealing_staging.Etoro_Hedge_ExecutionLog (hedge execution records)
  + CopyFromLake.PriceLog_History_CurrencyPrice (eToro SendTime prices, via RateIDAtSent)
  + CopyFromLake.PricesFromProvider_MarketCurrencyPrice (Kusto LP prices, CROSS APPLY)
  + DWH_dbo.Fact_CurrencyPriceWithSplit (FX rates for USD conversion)
  + DWH_dbo.Dim_Instrument (instrument type, currency pair)
  + Dealing_staging.Etoro_Hedge_HBCOrderLog (HedgingMode classification)
    |
    v
  SP_Execution_Slippage(@Date)
    |-- #ExecutionRate1: filter Success=1, ExecutionRate<>0, HedgeServerID<>5000
    |-- #FX_Rate: cross-currency USD conversion via Fact_CurrencyPriceWithSplit + Dim_Instrument
    |-- #ExecutionRate: join FX_Rate, apply GBX ÷100
    |-- #eToroPrice: join PriceLog via RateIDAtSent → SendTime prices
    |-- #KustoAll_ExecutionSlippage: all Kusto prices for relevant instruments
    |-- #KustoPrices: CROSS APPLY latest Kusto price ≤ ExecutionTime
    |-- #Total: GROUP BY execution group, compute aggregates
    |
    v
  DELETE FROM Dealing_dbo.Dealing_Execution_Slippage WHERE Date = @Date
  INSERT ... (slippage formulas computed inline)
    |
    v
  Dealing_dbo.Dealing_Execution_Slippage (4.78M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Dealing_staging.Etoro_Hedge_ExecutionLog | Raw hedge execution records |
| Price (SendTime) | CopyFromLake.PriceLog_History_CurrencyPrice | eToro quoted prices matched by RateIDAtSent |
| Price (Kusto) | CopyFromLake.PricesFromProvider_MarketCurrencyPrice | LP market prices (STALE since Oct 2024) |
| FX Rates | DWH_dbo.Fact_CurrencyPriceWithSplit | Daily Bid/Ask for cross-currency conversion |
| Instrument | DWH_dbo.Dim_Instrument | InstrumentType, BuyCurrencyID, SellCurrencyID |
| HBC Classification | Dealing_staging.Etoro_Hedge_HBCOrderLog | Determines CBH vs HBC routing mode |
| ETL | Dealing_dbo.SP_Execution_Slippage | Per-date delete+insert with slippage computation |
| Target | Dealing_dbo.Dealing_Execution_Slippage | Final slippage table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, symbol, type, asset class |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_dbo.Dealing_Execution_Slippage_AssetType | Aggregation | Aggregated by InstrumentType + HedgingMode; same SP produces both |
| Dealing_dbo.Dealing_Execution_Slippage_RequestTime | Sibling | RequestTime variant; same SP, different price reference |
| Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime | Sibling aggregation | RequestTime aggregation by InstrumentType + HedgingMode |

---

## 7. Sample Queries

### 7.1 Daily net slippage by hedging mode

```sql
SELECT
    Date,
    HedgingMode,
    SUM(SlippageInDollar) AS net_slippage_usd,
    SUM(Units) AS total_units,
    COUNT(*) AS execution_groups,
    SUM(NumberofTransaction) AS raw_trades
FROM [Dealing_dbo].[Dealing_Execution_Slippage]
WHERE Date BETWEEN '2024-09-01' AND '2024-10-03'
GROUP BY Date, HedgingMode
ORDER BY Date DESC;
```

### 7.2 Instruments with worst slippage in a month

```sql
SELECT TOP 20
    s.InstrumentID,
    di.InstrumentDisplayName,
    di.InstrumentType,
    SUM(s.SlippageInDollar) AS net_slippage_usd,
    SUM(s.Units) AS total_units,
    COUNT(*) AS execution_groups
FROM [Dealing_dbo].[Dealing_Execution_Slippage] s
JOIN [DWH_dbo].[Dim_Instrument] di ON s.InstrumentID = di.InstrumentID
WHERE s.Date BETWEEN '2024-09-01' AND '2024-09-30'
GROUP BY s.InstrumentID, di.InstrumentDisplayName, di.InstrumentType
ORDER BY net_slippage_usd ASC;
```

### 7.3 Execution latency distribution

```sql
SELECT
    HedgingMode,
    AVG(DATEDIFF(ms, Occurred, ExecutionTime)) AS avg_latency_ms,
    MIN(DATEDIFF(ms, Occurred, ExecutionTime)) AS min_latency_ms,
    MAX(DATEDIFF(ms, Occurred, ExecutionTime)) AS max_latency_ms
FROM [Dealing_dbo].[Dealing_Execution_Slippage]
WHERE Date = '2024-10-02'
GROUP BY HedgingMode;
```

---

## 8. Atlassian Knowledge Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

---

*Generated: 2026-04-28 | Quality: 8.0/10 (★★★★☆) | Phases: 12/14*
*Tiers: 1 T1, 20 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 21/21, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_Execution_Slippage | Type: Table | Production Source: Dealing_staging.Etoro_Hedge_ExecutionLog + CopyFromLake via SP_Execution_Slippage*
