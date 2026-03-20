# Column Lineage: DWH_dbo.Dim_Currency

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Currency` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `etoro.Dictionary.Currency` (etoro) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.Currency
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_Currency (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_Currency (15.7K rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CurrencyID | etoro.Dictionary.Currency | CurrencyID | passthrough | Universal instrument identifier. 0=placeholder. |
| CurrencyTypeID | etoro.Dictionary.Currency | CurrencyTypeID | passthrough | Asset class: 1=Forex, 2=Commodity, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. |
| Name | etoro.Dictionary.Currency | Name | passthrough | Full instrument name. |
| Abbreviation | etoro.Dictionary.Currency | Abbreviation | passthrough | Ticker symbol (e.g., AAPL.US, BTC). |
| Mask | etoro.Dictionary.Currency | Mask | passthrough | Legacy bitmask for original 8 forex currencies only. |
| EEAStockExchange | etoro.Dictionary.Currency | EEAStockExchange | passthrough | MiFID II PRIIPs EEA exchange flag. |
| ISINCode | etoro.Dictionary.Currency | ISINCode | passthrough | International Securities Identification Number. |
| CurrencySymbol | etoro.Dictionary.Currency | CurrencySymbol | passthrough | Unicode display symbol ($, EUR, etc.). |
| InterestRateID | etoro.Dictionary.Currency | InterestRateID | passthrough | Overnight financing rate reference. |
| UpdateDate | - | - | ETL-computed | GETDATE() on each reload. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 9 |
| **ETL-computed** | 1 |
| **Total** | 10 |
