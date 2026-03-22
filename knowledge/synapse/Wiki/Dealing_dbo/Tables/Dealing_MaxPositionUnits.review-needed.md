---
object: Dealing_MaxPositionUnits
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_MaxPositionUnits — Review Notes

## Auto-Generated Flags

- **"Xaip" in column name**: `[MaxPositionUnitsXaip.LastPrice]` — what does "Xaip" stand for? Is this an acronym for a system/provider (e.g., XAIP = external API)? Understanding the name would clarify whether the price is sourced from a specific provider.
- **LastPrice source**: LastPrice = BidSpreaded from `Fact_CurrencyPriceWithSplit`. Reviewer: confirm this is the correct price source for position-limit USD conversion, especially for instruments priced in non-USD currencies.
- **ProviderID values**: Which providers appear in this table? Is the set the same as NOP_Report LPs (GS, IB, JP, SAXO, etc.) or different?
- **DWH_staging.etoro_Trade_ProviderToInstrument**: Is this staging table loaded from a Lake source? Confirm freshness — if it's loaded once per day, MaxPositionUnits may lag intraday LP contract changes.
- **Column list accuracy**: Column list inferred from SP logic — reviewer should verify against actual DDL for any additional columns (e.g., MinPositionUnits, StepSize).
- **5.7M rows**: At daily cadence, this implies ~thousands of provider × instrument combinations per day. Confirm whether this is expected growth rate.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
