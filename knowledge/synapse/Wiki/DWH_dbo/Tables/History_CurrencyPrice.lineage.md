# Column Lineage: DWH_dbo.History_CurrencyPrice

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.History_CurrencyPrice` |
| **UC Target** | `bronze.pricelog_history_currencyprice` (or similar - exact name TBD) |
| **Primary Source** | `Trade.CurrencyPrice` / `History.CurrencyPrice` (production price feed tick archive) |
| **ETL SP** | None (External Table - reads directly from Bronze parquet via PolyBase) |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
Price Feed (external providers / exchanges)
  -> Trade.SetCurrencyPrice (SP, updates live cache)
       -> Trade.CurrencyPrice (live cache - 1 row per ProviderID+InstrumentID)
  -> History.CurrencyPrice (production DB tick archive - all ticks appended)
       -> PriceLog Generic Pipeline (Bronze landing)
            -> ADLS Gen2: Bronze/PriceLog/History/CurrencyPrice/etr_y={y}/etr_ym={ym}/etr_ymd={ymd}/*.parquet
                 -> DWH_dbo.History_CurrencyPrice (External Table - reads directly, no copy)

DWH downstream:
  -> DWH_staging.PriceLog_History_CurrencyPrice_Active (1-day materialized subset)
       -> SP_Dim_Instrument (ReceivedOnPriceServer per instrument)
  -> DWH_staging.PriceLog_History_CurrencyPrice_Active_5_days (5-day materialized subset)
       -> SP_Dim_Position_DL_To_Synapse (Open/Close price + USD conversion for P&L)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from production source. |
| **ETL-computed** | Derived by the Bronze pipeline at write time. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CurrencyPriceID | History.CurrencyPrice | CurrencyPriceID | passthrough | bigint; unique tick identifier |
| ProviderID | History.CurrencyPrice | ProviderID | passthrough | int; price feed provider |
| InstrumentID | History.CurrencyPrice | InstrumentID | passthrough | int; FK to Dim_Instrument |
| Bid | History.CurrencyPrice | Bid | passthrough | numeric(16,8); raw market bid |
| Ask | History.CurrencyPrice | Ask | passthrough | numeric(16,8); raw market ask |
| BidSpreaded | History.CurrencyPrice | BidSpreaded | passthrough | numeric(16,8); spread-adjusted bid |
| AskSpreaded | History.CurrencyPrice | AskSpreaded | passthrough | numeric(16,8); spread-adjusted ask |
| MarkupPips | History.CurrencyPrice | MarkupPips | passthrough | numeric(19,8); spread in PIPs |
| ValidFrom | History.CurrencyPrice | ValidFrom | passthrough | datetime2(7) |
| ValidTo | History.CurrencyPrice | ValidTo | passthrough | datetime2(7) |
| Occurred | History.CurrencyPrice | Occurred | passthrough | datetime2(7); tick time; source for partitions |
| OccurredOnProvider | History.CurrencyPrice | OccurredOnProvider | passthrough | datetime2(7); provider timestamp |
| ReceivedOnPriceServer | History.CurrencyPrice | ReceivedOnPriceServer | passthrough | datetime2(7) |
| MarketReceivedTime | History.CurrencyPrice | MarketReceivedTime | passthrough | datetime2(7) |
| PriceRateID | History.CurrencyPrice | PriceRateID | passthrough | bigint; tick ID for position joins |
| MarketPriceRateID | History.CurrencyPrice | MarketPriceRateID | passthrough | bigint |
| BidMarketPriceRateID | History.CurrencyPrice | BidMarketPriceRateID | passthrough | bigint |
| AskMarketPriceRateID | History.CurrencyPrice | AskMarketPriceRateID | passthrough | bigint |
| LiquidityAccountID | History.CurrencyPrice | LiquidityAccountID | passthrough | int |
| USDConversionRate | History.CurrencyPrice | USDConversionRate | passthrough | numeric(16,8); for non-USD P&L conversion |
| RateLastEx | History.CurrencyPrice | RateLastEx | passthrough | numeric(16,8) |
| SkewValueBid | History.CurrencyPrice | SkewValueBid | passthrough | numeric(19,8) |
| SkewValueAsk | History.CurrencyPrice | SkewValueAsk | passthrough | numeric(19,8) |
| etr_y | Bronze PriceLog pipeline | Occurred | ETL-computed | Year partition: year(Occurred) as string (e.g., "2024") |
| etr_ym | Bronze PriceLog pipeline | Occurred | ETL-computed | Year-month partition: format(Occurred, 'yyyy-MM') |
| etr_ymd | Bronze PriceLog pipeline | Occurred | ETL-computed | Date partition: format(Occurred, 'yyyy-MM-dd') |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 23 (all production columns) |
| **ETL-computed** | 3 (etr_y, etr_ym, etr_ymd - Bronze pipeline partition columns) |
| **Rename** | 0 |
| **Total** | 26 |

Note: 1 column listed in DDL (27 total) - column 27 is etr_ymd (counted above). Total = 26 unique columns per DDL.
