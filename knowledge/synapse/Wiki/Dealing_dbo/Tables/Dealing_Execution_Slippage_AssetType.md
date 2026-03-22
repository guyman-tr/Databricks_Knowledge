# Dealing_Execution_Slippage_AssetType

## 1. Business Meaning

Daily execution slippage aggregated by asset type and hedging mode. Produced by `SP_Execution_Slippage` alongside `Dealing_Execution_Slippage` — this table collapses individual trade-level slippage into 12 rows per day (6 instrument types × 2 hedging modes: CBH / HBC), giving a high-level view of where eToro earns or loses on execution quality by market segment.

> **PIPELINE STALE**: Last populated **2024-10-03** (5+ months stale as of 2026-03-21). Same root cause as `Dealing_Execution_Slippage`: the Kusto LP price feed (`CopyFromLake.PricesFromProvider_MarketCurrencyPrice`) stopped supplying data. Use `Dealing_Execution_Slippage_AssetType_RequestTime` for current slippage-by-asset-type data (last updated 2025-01-11).

**Hedging modes present:**
- `CBH` — Clearing Broker Hedging: STP execution routed to Apex or BNY Mellon.
- `HBC` — Hedge By Company: eToro internalizes the position and hedges directly.

**Instrument types:** Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF.

**Rows per day:** ~12 (one per InstrumentType × HedgingMode combination when activity exists).

**Slippage sign convention:** Positive = eToro gains (LP executed at better rate than eToro's price). Negative = eToro cost.

## 2. Business Logic

### 2.1 Aggregation from Trade-Level

Populated from `#AssetType` temp table within `SP_Execution_Slippage`:

```sql
SUM(
  (CASE WHEN IsBuy = 1 THEN 1.0 ELSE -1.0 END)
  * (eToro_Price - ExecutionRate)
  * Units * FX_Rate
) AS SlippageInDollar
GROUP BY InstrumentType, HedgingMode
```

Where:
- `eToro_Price` = eToro's quoted price at the time the hedge order was sent (Ask for buys, Bid for sells), from `CopyFromLake.PriceLog_History_CurrencyPrice` matched by `RateIDAtSent`
- `ExecutionRate` = actual LP fill rate from `Dealing_staging.Etoro_Hedge_ExecutionLog`
- `FX_Rate` = USD conversion factor from `DWH_dbo.Fact_CurrencyPriceWithSplit`

### 2.2 Kusto Dependency

Unlike the _RequestTime variant, this table's pipeline requires a valid Kusto price record per trade (via `CROSS APPLY` on `CopyFromLake.PricesFromProvider_MarketCurrencyPrice`). If the Kusto feed is empty, `#KustoPrices` has no rows, `#Total` is empty, and therefore `#AssetType` is empty → no data written.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN. Cross-node broadcast for JOINs is negligible given the tiny row count (~12/day).

**Typical usage:**
```sql
-- Daily slippage by asset class and hedge mode
SELECT Date, InstrumentType, HedgingMode,
       SlippageInDollar,
       SUM(SlippageInDollar) OVER (PARTITION BY InstrumentType ORDER BY Date ROWS 29 PRECEDING) AS rolling_30d
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType
WHERE Date >= '2024-01-01'
ORDER BY Date DESC, SlippageInDollar ASC
```

**Gotcha — stale data:** Any dashboard using this table will show a 5-month gap after Oct 2024. Prefer `Dealing_Execution_Slippage_AssetType_RequestTime` as the active equivalent.

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC) for which slippage is aggregated. Equals the ExecutionTime date from `Etoro_Hedge_ExecutionLog`. (Tier 2 — SP_Execution_Slippage) |
| InstrumentType | varchar(50) | Asset class label from `DWH_dbo.Dim_Instrument.InstrumentType`. Values: Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF. (Tier 2 — SP_Execution_Slippage via Dim_Instrument) |
| HedgingMode | varchar(10) | Routing mode for the execution batch. CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company (eToro internal). Determined by presence in `Dealing_staging.Etoro_Hedge_HBCOrderLog`. (Tier 2 — SP_Execution_Slippage) |
| SlippageInDollar | money | Sum of USD slippage across all trades in the (Date, InstrumentType, HedgingMode) bucket. Formula: `SUM((IsBuy=1?1:-1)×(eToro_Price−ExecutionRate)×Units×FX_Rate)`. Positive = eToro gains; negative = eToro cost. (Tier 2 — SP_Execution_Slippage) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE() at SP run time). Not a business date. (Tier 2 — SP_Execution_Slippage) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_staging.Etoro_Hedge_ExecutionLog` | Trade execution records (ExecutionRate, Units, IsBuy, SendTime) |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro quoted price matched by RateIDAtSent |
| `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` | Kusto LP market price — REQUIRED for this pipeline (stale since Oct 2024) |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Daily FX rates for USD conversion |
| `DWH_dbo.Dim_Instrument` | InstrumentType lookup |
| `Dealing_staging.Etoro_Hedge_HBCOrderLog` | HedgingMode: CBH vs HBC |

**ETL:** `Dealing_dbo.SP_Execution_Slippage` → `Dealing_dbo.Dealing_Execution_Slippage_AssetType`

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Execution_Slippage` | Parent table; this is its aggregation by InstrumentType + HedgingMode |
| `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime` | Parallel table using RequestTime price reference instead of SendTime Kusto price — ACTIVE |
| `Dealing_dbo.Dealing_Execution_Slippage_RequestTime` | Row-level RequestTime variant; source of the _RequestTime aggregation |

## 7. Sample Queries

```sql
-- Compare CBH vs HBC slippage by asset class for a month
SELECT
    InstrumentType,
    HedgingMode,
    SUM(SlippageInDollar) AS total_slippage_usd,
    COUNT(*) AS trading_days
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType
WHERE Date BETWEEN '2024-09-01' AND '2024-09-30'
GROUP BY InstrumentType, HedgingMode
ORDER BY total_slippage_usd DESC

-- Rolling 30-day net slippage by asset type
SELECT Date, InstrumentType,
    SUM(SlippageInDollar) OVER (
        PARTITION BY InstrumentType ORDER BY Date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_usd
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType
ORDER BY Date DESC, InstrumentType
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
