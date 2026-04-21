# Lineage: eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static

**Generated**: 2026-04-21 | **Writer**: Manual load (no ETL SP) | **Last Updated**: 2022-11-21

## ETL Chain

```
Manual insert (no Generic Pipeline, no SP writer)
  Data: 145 rows mapping 21 currencies to their FX instrument pairs
  Load date: 2022-11-21 (one-time manual population)
  v
eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static (145 rows, static)
  |-- No Generic Pipeline export confirmed ---|
  v
(UC target TBD — no active ETL pipeline detected)
```

## Column Lineage

| # | DWH Column | Source | Transform | Tier |
|---|-----------|--------|-----------|------|
| 1 | Currency | Manual input | ISO 4217 alpha-3 currency code | Tier 2 |
| 2 | CurrencyISO | Manual input | ISO 4217 numeric currency code | Tier 2 |
| 3 | InstrumentID | Manual input | FK to DWH_dbo.Dim_Instrument (matches DWHInstrumentID) | Tier 2 |
| 4 | InstrumentName | Manual input | FX pair name (e.g., 'AUD/EUR', 'GBP/AUD') | Tier 2 |
| 5 | DWHInstrumentID | Manual input | Same as InstrumentID (verified from live data); DWH dimension instrument ID | Tier 2 |
| 6 | BuyCurrencyID | Manual input | Internal DWH currency ID for base (buy) currency | Tier 2 |
| 7 | SellCurrencyID | Manual input | Internal DWH currency ID for quote (sell) currency | Tier 2 |
| 8 | BuyCurrency | Manual input | ISO alpha-3 for base currency (e.g., 'AUD', 'GBP') | Tier 2 |
| 9 | SellCurrency | Manual input | ISO alpha-3 for quote currency (e.g., 'EUR', 'USD') | Tier 2 |
| 10 | UpdateDate | Manual input | Timestamp of manual data load (2022-11-21; static) | Tier 2 |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 10 | All columns (manual static load, no upstream wiki) |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
