---
object: Dealing_MaxPositionUnits
lineage_type: DWH Staging → Configuration Snapshot
production_source: DWH_staging.etoro_Trade_ProviderToInstrument + Fact_CurrencyPriceWithSplit
---

# Dealing_MaxPositionUnits — Lineage Map

## Data Flow

```
DWH_staging.etoro_Trade_ProviderToInstrument
  │ → MaxPositionUnits per ProviderID × InstrumentID
  │ → Filter: Tradable=1, VisibleInternallyOnly=0
  │
Fact_CurrencyPriceWithSplit
  │ → BidSpreaded → LastPrice (for price-value calculation)
  │
DWH_dbo.Dim_Instrument
  │ → InstrumentName, Currency
  │
  ▼
[MaxPositionUnitsXaip.LastPrice] = MaxPositionUnits × LastPrice
  │
  ▼
Dealing_MaxPositionUnits
```

## Refresh Schedule
Daily — SP_MaxPositionUnits, OpsDB Priority 0, ProcessType 1 (SQL). Active.
