---
object: Dealing_dbo.Dealing_DailySpreadsAggregated
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_DailySpreadsAggregated

## ETL Chain

```
CopyFromLake.PricesFromProvider_MarketCurrencyPrice
  (bid-ask prices from LPs by instrument, timestamped)
  Hardcoded LP-to-instrument mapping (20 LPs in SP)
  → SP_DailySpreadsAggregated (@Date)
    GROUP BY Instrument × LP
    PIVOT: AVG(bid-ask spread) per UTC hour
    PIVOT: COUNT(ticks) per UTC hour
    → Dealing_dbo.Dealing_DailySpreadsAggregated
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics from CopyFromLake price feed.

## Column Lineage

| Column | Source |
|--------|--------|
| Date | SP parameter @Date |
| InstrumentName, InstrumentTypeID, InstrumentID | Hardcoded LP-instrument mapping in SP |
| LiquidityAccountID | Hardcoded LP-instrument mapping in SP |
| Name | Hardcoded LP short name |
| hour0–hour23 | AVG(Ask − Bid) per UTC hour from PricesFromProvider_MarketCurrencyPrice |
| count_hour0–count_hour23 | COUNT(*) price ticks per UTC hour |
| updateDate | GETDATE() at SP execution time |
| AvgAskAt23 | AVG(Ask) during UTC hours 14–16 (mid-session) |

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ STALE since 2025-02-17 — CopyFromLake.PricesFromProvider_MarketCurrencyPrice feed disruption
