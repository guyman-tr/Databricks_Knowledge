---
object: Dealing_dbo.Dealing_DailySpreadsAggregatedFX
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_DailySpreadsAggregatedFX

## ETL Chain

```
CopyFromLake.PricesFromProvider_MarketCurrencyPrice
  (FX instruments only — filtered subset)
  Hardcoded LP-to-FX-instrument mapping in SP
  → SP_DailySpreadsAggregated (@Date) [FX branch]
    → Dealing_dbo.Dealing_DailySpreadsAggregatedFX
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics. FX-only variant of Dealing_DailySpreadsAggregated.

## Column Lineage

Identical to `Dealing_DailySpreadsAggregated`. See [that table's lineage](Dealing_DailySpreadsAggregated.lineage.md).

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ STALE since 2024-04-10 — FX branch removed from SP_DailySpreadsAggregated
