# Dealing_Execution_Slippage_RequestTime

## 1. Business Meaning

Row-level daily execution slippage using the **RequestTime price** as the eToro reference point. For each (InstrumentID × RequestTime × ExecutionTime × IsBuy × ExecutionRate × HedgingMode) combination, records the eToro price at the moment the hedge order was received (`RequestTime`) versus the LP's actual fill rate (`ExecutionRate`), along with USD-denominated P&L impact.

This is the most granular and actively-maintained slippage table in the batch — 29.6M rows across ~2 years, covering 7,477 instruments. It does **not** require the Kusto LP market feed (unlike the non-suffixed `Dealing_Execution_Slippage`), so it continues populating when that feed is broken.

**Last updated:** 2025-01-11 (~2.5 months stale as of 2026-03-21). SP scheduling issue suspected.

**Slippage sign convention:**
- `Slippage` (points) positive = LP charged more than eToro expected = eToro cost.
- `SlippageInDollar` positive = eToro gained (LP rate better than eToro's RequestTime price).

**"RequestTime" definition:** The timestamp of the most recent eToro price event in `CopyFromLake.PriceLog_History_CurrencyPrice` with `Occurred <= ExecutionTime`. This is the last known eToro price just before LP execution.

## 2. Business Logic

### 2.1 Price Matching

For each execution record, the SP uses a `CROSS APPLY` to find the most recent eToro price:
```sql
CROSS APPLY (
  SELECT TOP 1 Occurred, Bid, Ask
  FROM CopyFromLake.PriceLog_History_CurrencyPrice E
  WHERE E.partition_date = @Date
    AND E.InstrumentID = D.InstrumentID
    AND E.Occurred <= D.ExecutionTime
  ORDER BY Occurred DESC
) A
```

`eToro_RequestTimePrice` = `Ask` (IsBuy=1) or `Bid` (IsBuy=0).

### 2.2 Slippage Formulas

```
Slippage         = (IsBuy=1 ? +1 : -1) × (ExecutionRate − eToro_RequestTimePrice)
SlippageInDollar = (IsBuy=1 ? +1 : -1) × (eToro_RequestTimePrice − ExecutionRate) × Units × FX_Rate
Slippage_Percent = (IsBuy=1 ? +1 : -1) × (ExecutionRate − eToro_RequestTimePrice) / eToro_RequestTimePrice
```

Note: `Slippage` and `SlippageInDollar` have **opposite signs** — Slippage (points) positive means eToro cost; SlippageInDollar positive means eToro gain. This is intentional: both are "from eToro's perspective."

### 2.3 USD Conversion

FX rate is computed from `DWH_dbo.Fact_CurrencyPriceWithSplit`:
- Instrument denominated in USD (`SellCurrencyID=1`): FX_Rate = 1
- Instrument with USD as buy currency: FX_Rate = 1 / (Bid or Ask of the instrument)
- GBX instruments: FX_Rate = instrument FX / 100 (pence conversion)
- Cross-currency: FX_Rate = 1 / (cross rate to USD) or cross rate from USD

### 2.4 Aggregation

Multiple raw execution log entries with the same (InstrumentID, RequestTime, ExecutionTime, IsBuy, ExecutionRate, HedgingMode, FX_Rate) are summed into one row:
- `Units` = SUM(Units)
- `ProviderAmount_USD` = SUM(Units × ExecutionRate × FX_Rate)
- `eToro_RequestTimeAmountUSD` = SUM(Units × eToro_RequestTimePrice × FX_Rate)
- `NumberofTransaction` = COUNT(*)

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 29.6M rows. Full scans will be heavy — filter by Date always.

**RequestTime ≠ SendTime:** RequestTime here is the eToro price event time, not the hedge order send time. For execution latency analysis use `DATEDIFF(ms, RequestTime, ExecutionTime)`.

**Typical join:** To get asset type, JOIN to `DWH_dbo.Dim_Instrument ON InstrumentID`.

```sql
-- Summarize daily slippage by HedgingMode for a week
SELECT Date, HedgingMode,
       SUM(SlippageInDollar) AS net_slippage_usd,
       SUM(Units) AS total_units,
       COUNT(*) AS execution_groups
FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime
WHERE Date BETWEEN '2025-01-01' AND '2025-01-11'
GROUP BY Date, HedgingMode
ORDER BY Date DESC

-- Instruments with worst slippage in a given month
SELECT TOP 20
    rt.InstrumentID, di.InstrumentName,
    SUM(rt.SlippageInDollar) AS net_slippage_usd
FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime rt
JOIN DWH_dbo.Dim_Instrument di ON rt.InstrumentID = di.InstrumentID
WHERE rt.Date BETWEEN '2024-12-01' AND '2024-12-31'
GROUP BY rt.InstrumentID, di.InstrumentName
ORDER BY net_slippage_usd ASC
```

**Performance:** ROUND_ROBIN distribution means no skew but full cross-node scan. For heavy aggregations, consider materializing into a temp table first or using the aggregate `_AssetType_RequestTime` table.

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC). Equals the ExecutionTime date from `Etoro_Hedge_ExecutionLog`. Partition filter — always include in WHERE. (Tier 2 — SP_Execution_Slippage) |
| InstrumentID | int | FK to `DWH_dbo.Dim_Instrument`. Identifies the hedged instrument. (Tier 1 — upstream wiki, Trade.Instrument) |
| RequestTime | datetime | Timestamp of the last eToro price event (Occurred) in `PriceLog_History_CurrencyPrice` with `Occurred ≤ ExecutionTime`. Millisecond precision. (Tier 2 — SP_Execution_Slippage) |
| ExecutionTime | datetime | Actual LP fill timestamp from `Etoro_Hedge_ExecutionLog`. Millisecond precision. (Tier 2 — SP_Execution_Slippage) |
| IsBuy | bit | 1 = buy (long) position, 0 = sell (short). Determines slippage sign direction. (Tier 2 — SP_Execution_Slippage) |
| Units | decimal(16,6) | Total units traded in this execution group. `SUM(Units)` from raw execution records. (Tier 2 — SP_Execution_Slippage) |
| ExecutionRate | decimal(16,6) | LP fill rate in instrument currency. (Tier 2 — SP_Execution_Slippage) |
| eToro_RequestTimePrice | decimal(16,6) | eToro's last quoted price just before LP execution. Ask for buys, Bid for sells. Source: `PriceLog_History_CurrencyPrice`. (Tier 2 — SP_Execution_Slippage) |
| ProviderAmount_USD | decimal(16,6) | Total LP cost in USD: `SUM(Units × ExecutionRate × FX_Rate)`. (Tier 2 — SP_Execution_Slippage) |
| eToro_RequestTimeAmountUSD | decimal(16,6) | eToro expected cost at RequestTime in USD: `SUM(Units × eToro_RequestTimePrice × FX_Rate)`. (Tier 2 — SP_Execution_Slippage) |
| FX_Rate | decimal(16,6) | FX conversion factor to USD. 1.0 for USD-denominated instruments. From `DWH_dbo.Fact_CurrencyPriceWithSplit`. (Tier 2 — SP_Execution_Slippage) |
| Slippage | decimal(16,6) | Price-unit slippage: `(IsBuy=1?+1:-1)×(ExecutionRate−eToro_RequestTimePrice)`. Positive = eToro cost (LP worse than expected). (Tier 2 — SP_Execution_Slippage) |
| SlippageInDollar | decimal(16,6) | USD slippage: `(IsBuy=1?+1:-1)×(eToro_RequestTimePrice−ExecutionRate)×Units×FX_Rate`. Positive = eToro gains. Note: **opposite sign** to `Slippage`. (Tier 2 — SP_Execution_Slippage) |
| Slippage_Percent | decimal(16,6) | Relative slippage: `(IsBuy=1?+1:-1)×(ExecutionRate−eToro_RequestTimePrice)/eToro_RequestTimePrice`. Same sign convention as `Slippage`. (Tier 2 — SP_Execution_Slippage) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE() at SP run time). (Tier 2 — SP_Execution_Slippage) |
| HedgingMode | varchar(10) | CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company. (Tier 2 — SP_Execution_Slippage) |
| NumberofTransaction | int | Count of raw `Etoro_Hedge_ExecutionLog` records summed into this row. (Tier 2 — SP_Execution_Slippage) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_staging.Etoro_Hedge_ExecutionLog` | Execution records (ExecutionRate, Units, IsBuy, ExecutionTime, HedgeOrderID) |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro price at RequestTime (CROSS APPLY: latest Occurred ≤ ExecutionTime) |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Daily FX rates for USD conversion |
| `DWH_dbo.Dim_Instrument` | InstrumentType, CCY1, BuyCurrencyID, SellCurrencyID |
| `Dealing_staging.Etoro_Hedge_HBCOrderLog` | HedgingMode lookup |

**ETL:** `Dealing_dbo.SP_Execution_Slippage` → `Dealing_dbo.Dealing_Execution_Slippage_RequestTime`

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Execution_Slippage` | SendTime counterpart; stale since Oct 2024; uses Kusto LP price instead |
| `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime` | Aggregation of this table by InstrumentType + HedgingMode |
| `DWH_dbo.Dim_Instrument` | FK on InstrumentID; join for InstrumentName, AssetTypeID |

## 7. Sample Queries

```sql
-- Execution latency distribution (ms) by HedgingMode
SELECT HedgingMode,
    AVG(DATEDIFF(ms, RequestTime, ExecutionTime)) AS avg_latency_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY DATEDIFF(ms, RequestTime, ExecutionTime))
        OVER (PARTITION BY HedgingMode) AS p95_latency_ms
FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime
WHERE Date = '2025-01-10'
GROUP BY HedgingMode

-- Zero-slippage rate (perfect fill rate)
SELECT Date,
    SUM(CASE WHEN Slippage = 0 THEN NumberofTransaction ELSE 0 END) * 1.0
        / SUM(NumberofTransaction) AS zero_slippage_pct
FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime
WHERE Date BETWEEN '2025-01-01' AND '2025-01-11'
GROUP BY Date
ORDER BY Date
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
