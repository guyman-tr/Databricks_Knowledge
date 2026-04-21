# Lineage: eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic

**Generated**: 2026-04-21 | **Writer**: Manual load (no ETL SP) | **Last Updated**: 2025-11-26

## ETL Chain

```
Manual insert (no Generic Pipeline, no SP writer)
  Data: 4 rows mapping eToro Money currencies to legal entities and DWH instruments
  Initial load: 2025-09-29 (AUD, GBP, EUR rows)
  DKK row added: 2025-11-26 (manual update by DBA)
  v
eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic (4 rows, semi-static)
  |-- No Generic Pipeline export confirmed ---|
  v
(UC target TBD — no active ETL pipeline detected)
```

**Note**: A commented-out UPDATE block exists in SP_eMoney_ClientBalance (lines 56–63) that
sets InstrumentID values by CurrencyISO. This block is wrapped in /*** ***/ and is NOT executed
at runtime — it is a development artifact showing the original instrument ID assignment logic.
The table is maintained by direct DBA INSERT/UPDATE outside of any SP.

## Column Lineage

| # | DWH Column | Source | Transform | Tier |
|---|-----------|--------|-----------|------|
| 1 | CurrencyISO | Manual input | ISO 4217 numeric currency code (36=AUD, 208=DKK, 826=GBP, 978=EUR) | Tier 2 |
| 2 | CurrencyName | Manual input | ISO 4217 alpha-3 currency name ('AUD', 'DKK', 'GBP', 'EUR') | Tier 2 |
| 3 | Entity | Manual input | eToro Money legal entity responsible for this currency ('eToro Money UK', 'eToro Money Malta', 'eToro Money AUS') | Tier 2 |
| 4 | InstrumentID | Manual input | DWH instrument ID for the primary FX instrument of this currency; FK to DWH_dbo.Dim_Instrument (1=EUR, 2=GBP, 7=AUD, 75=DKK) | Tier 2 |
| 5 | UpdateDate | Manual input | Timestamp of the most recent manual insert/update for this row | Tier 2 |
| 6 | ReportingCurrency | Manual input | ISO alpha-3 code for the reporting currency of the eToro Money entity (DKK reports in EUR; others report in their own currency) | Tier 2 |
| 7 | ReportingInstrumentID | Manual input | DWH instrument ID for the reporting currency; FK to DWH_dbo.Dim_Instrument (1=EUR for Malta/DKK, 2=GBP for UK, 7=AUD for AUS) | Tier 2 |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (no upstream wiki source; manual static load) |
| Tier 2 | 7 | All columns (manually maintained, no upstream wiki) |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
