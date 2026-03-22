# Dealing_Execution_Slippage_AssetType_RequestTime

## 1. Business Meaning

Daily execution slippage aggregated by asset type and hedging mode, using the **RequestTime price** as the reference point (rather than the SendTime Kusto LP price used by the non-suffixed variant). Produced by `SP_Execution_Slippage` as the actively-maintained counterpart to the stale `Dealing_Execution_Slippage_AssetType`.

The key difference: slippage is measured as `ExecutionRate vs. the eToro price at the moment the order was received` (i.e., the last known eToro price snapshot before ExecutionTime), sourced purely from `CopyFromLake.PriceLog_History_CurrencyPrice`. Because this calculation does not require the Kusto LP market feed, it remains operational when the Kusto pipeline is broken.

**Last updated:** 2025-01-11 (active, but ~2.5 months stale as of 2026-03-21 — likely a broader SP scheduling gap).

**Rows per day:** ~12 (6 instrument types × 2 hedging modes: CBH / HBC).

**Slippage sign convention:** Positive = eToro gains (LP executed at better rate than eToro's price). Negative = eToro cost.

## 2. Business Logic

### 2.1 RequestTime Price Reference

Compared to the SendTime variant:

| Variant | Price Reference | Source |
|---------|-----------------|--------|
| `Dealing_Execution_Slippage_AssetType` | Kusto LP market price just before ExecutionTime | `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` (STALE) |
| **`Dealing_Execution_Slippage_AssetType_RequestTime`** | **eToro price just before ExecutionTime (from PriceLog)** | `CopyFromLake.PriceLog_History_CurrencyPrice` (ACTIVE) |

### 2.2 Aggregation Formula

```sql
SUM(
  (CASE WHEN IsBuy = 1 THEN 1.0 ELSE -1.0 END)
  * (eToro_RequestTimePrice - ExecutionRate)
  * Units * FX_Rate
) AS SlippageInDollar
GROUP BY InstrumentType, HedgingMode
```

Where `eToro_RequestTimePrice` is the Ask (buy) or Bid (sell) from the PriceLog event with `Occurred <= ExecutionTime` (CROSS APPLY TOP 1 ORDER BY Occurred DESC).

### 2.3 Interpretation

Because the reference price is the eToro spread price (not the raw LP price), this measures how much eToro gained/lost relative to the price it showed to its own hedging system at execution time. This is distinct from pure LP-vs-execution comparison.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN. Negligible data volume (~12 rows/day, ~2693 total rows).

**Prefer this over the non-suffixed variant** for any analysis after Oct 2024, as `Dealing_Execution_Slippage_AssetType` has been stale since then.

```sql
-- Active slippage trend by asset class (last 90 days of available data)
SELECT Date, InstrumentType, HedgingMode, SlippageInDollar
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime
WHERE Date >= DATEADD(DAY, -90, '2025-01-11')
ORDER BY Date DESC, SlippageInDollar ASC
```

**Note:** Both AssetType tables stopped updating at similar times (Oct 2024 vs Jan 2025). The Jan 2025 cutoff likely reflects the SP run schedule rather than a different feed issue.

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC) for which slippage is aggregated. Equals the ExecutionTime date from `Etoro_Hedge_ExecutionLog`. (Tier 2 — SP_Execution_Slippage) |
| InstrumentType | varchar(40) | Asset class label from `DWH_dbo.Dim_Instrument.InstrumentType`. Values: Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF. (Tier 2 — SP_Execution_Slippage via Dim_Instrument) |
| HedgingMode | varchar(10) | Routing mode. CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company. Determined by presence in `Dealing_staging.Etoro_Hedge_HBCOrderLog`. (Tier 2 — SP_Execution_Slippage) |
| SlippageInDollar | money | Sum of USD slippage using eToro's RequestTime price as reference. Formula: `SUM((IsBuy=1?1:-1)×(eToro_RequestTimePrice−ExecutionRate)×Units×FX_Rate)`. Positive = eToro gains; negative = eToro cost. (Tier 2 — SP_Execution_Slippage) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE() at SP run time). Not a business date. (Tier 2 — SP_Execution_Slippage) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_staging.Etoro_Hedge_ExecutionLog` | Trade execution records (ExecutionRate, Units, IsBuy) |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro price at RequestTime (CROSS APPLY: last price with Occurred ≤ ExecutionTime) |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Daily FX rates for USD conversion |
| `DWH_dbo.Dim_Instrument` | InstrumentType lookup |
| `Dealing_staging.Etoro_Hedge_HBCOrderLog` | HedgingMode lookup |

**ETL:** `Dealing_dbo.SP_Execution_Slippage` → `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime`

Note: No Kusto feed dependency — this is why this variant outlived the SendTime tables.

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Execution_Slippage_AssetType` | SendTime variant; stale since Oct 2024; same structure |
| `Dealing_dbo.Dealing_Execution_Slippage_RequestTime` | Row-level source data; this table is its aggregation by InstrumentType + HedgingMode |
| `Dealing_dbo.Dealing_Execution_Slippage` | SendTime row-level source; stale counterpart |

## 7. Sample Queries

```sql
-- Net slippage by asset class (latest available month)
SELECT InstrumentType, HedgingMode,
    SUM(SlippageInDollar) AS total_usd,
    AVG(SlippageInDollar) AS avg_daily_usd
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime
WHERE Date BETWEEN '2024-12-01' AND '2024-12-31'
GROUP BY InstrumentType, HedgingMode
ORDER BY total_usd DESC

-- CBH vs HBC net comparison across all dates
SELECT HedgingMode,
    SUM(SlippageInDollar) AS total_usd,
    MIN(Date) AS first_date,
    MAX(Date) AS last_date
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime
GROUP BY HedgingMode
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
