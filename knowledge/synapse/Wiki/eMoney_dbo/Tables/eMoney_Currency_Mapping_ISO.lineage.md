# Column Lineage: eMoney_dbo.eMoney_Currency_Mapping_ISO

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Currency_Mapping_ISO |
| **Source System** | ISO 4217 (manually maintained) |
| **Source Object** | Static reference — no upstream DB source |
| **ETL Pattern** | Manual bulk load; no writer SP |
| **Writer SP** | None — manually maintained |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso |
| **Row Count (live)** | 168 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | CurrencyName | varchar(200) NULL | ISO 4217 | currency_name | Manual entry; full currency name | Tier 2 |
| 2 | CurrencyAlphaThreeCode | varchar(20) NULL | ISO 4217 | alpha-3 | Manual entry; 3-letter ISO currency code; joins to DWH_dbo.Dim_Instrument.BuyCurrency/SellCurrency | Tier 2 |
| 3 | CurrencyNumericCode_ISO | varchar(20) NULL | ISO 4217 | numeric | Manual entry; 3-digit ISO numeric; HASH distribution key; joins to FiatTransactions numeric codes | Tier 2 |
| 4 | UpdateDate | datetime NULL | Manual load | — | Bulk-load timestamp; all rows = 2024-06-24 | Tier 2 |

## ETL Pipeline

```
ISO 4217 reference data (external standard)
  |-- Manual bulk load (2024-06-24) ---|
  v
eMoney_dbo.eMoney_Currency_Mapping_ISO (168 rows, HASH(CurrencyNumericCode_ISO), HEAP)

Used by:
  SP_eMoney_DimFact_Transaction (steps 05a/05b/06) →
    FiatTransactions numeric currency codes → CurrencyAlphaThreeCode
    → Dim_Instrument.BuyCurrency / SellCurrency (InstrumentID lookup)
    → Fact_CurrencyPriceWithSplit (USD conversion)
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 4 | CurrencyName, CurrencyAlphaThreeCode, CurrencyNumericCode_ISO, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 4 | |

*Generated: 2026-04-21 | Phase 10B*
