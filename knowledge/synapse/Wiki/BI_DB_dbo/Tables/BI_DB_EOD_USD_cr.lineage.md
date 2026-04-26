# BI_DB_dbo.BI_DB_EOD_USD_cr — Column Lineage

## Summary

Daily end-of-day USD conversion rates per instrument, computed from DWH_dbo.Fact_CurrencyPriceWithSplit Bid/Ask prices with cross-currency pair resolution via self-joins.

## Source Objects

| # | Source Object | Schema | Role |
|---|--------------|--------|------|
| 1 | DWH_dbo.Fact_CurrencyPriceWithSplit | DWH_dbo | Primary price source — Bid/Ask by InstrumentID and OccurredDateID |
| 2 | DWH_dbo.Dim_Instrument | DWH_dbo | JOIN enrichment — BuyCurrencyID/SellCurrencyID for currency pair identification |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | ETL parameter | @dd | Passthrough — SP input date parameter |
| DateID | ETL-computed | DateToDateID(@dd) | Function call — converts date to YYYYMMDD integer |
| InstrumentID | DWH_dbo.Fact_CurrencyPriceWithSplit | InstrumentID | Passthrough via #prices temp table |
| USD_cr_Long | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | ETL-computed — CASE: SellCurrencyID=1→1.00; BuyCurrencyID=1→1/Bid; else cross-rate via intermediate pair 1/c.Bid or d.Bid |
| USD_cr_Short | DWH_dbo.Fact_CurrencyPriceWithSplit | Ask | ETL-computed — CASE: SellCurrencyID=1→1.00; BuyCurrencyID=1→1/Ask; else cross-rate via intermediate pair 1/c.Ask or d.Ask |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp — set at insert time |

## Lineage Notes

- The SP creates a #prices temp table joining Fact_CurrencyPriceWithSplit with Dim_Instrument to get BuyCurrencyID/SellCurrencyID per instrument.
- The INSERT then self-joins #prices three ways (b, c, d) to resolve cross-currency USD conversion: direct USD pairs use 1.00 or 1/rate, non-USD pairs use a triangulation via an intermediate USD-paired instrument.
- CurrencyID=1 represents USD in the eToro system.
