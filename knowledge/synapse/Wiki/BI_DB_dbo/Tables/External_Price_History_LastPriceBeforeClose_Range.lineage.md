# Column Lineage: BI_DB_dbo.External_Price_History_LastPriceBeforeClose_Range

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| Price.History.LastPriceBeforeClose | Production Table | Price DB (AZR-W-PRICEDB-2-Price) | Primary production source — last price snapshot before market close |
| Bronze/Price/History/LastPriceBeforeClose/ | Data Lake (Parquet) | Generic Pipeline Bronze layer | Intermediate lake export (Append strategy, daily, delta format) |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | CurrencyPriceID | Price.History.LastPriceBeforeClose | CurrencyPriceID | Passthrough (COPY INTO from Parquet) | Tier 4 |
| 2 | InstrumentID | Price.History.LastPriceBeforeClose | InstrumentID | Passthrough | Tier 4 |
| 3 | Bid | Price.History.LastPriceBeforeClose | Bid | Passthrough | Tier 4 |
| 4 | Ask | Price.History.LastPriceBeforeClose | Ask | Passthrough | Tier 4 |
| 5 | Occurred | Price.History.LastPriceBeforeClose | Occurred | Passthrough | Tier 4 |
| 6 | PriceRateID | Price.History.LastPriceBeforeClose | PriceRateID | Passthrough | Tier 4 |
| 7 | USDConversionRate | Price.History.LastPriceBeforeClose | USDConversionRate | Passthrough | Tier 4 |
| 8 | MarketPriceRateID | Price.History.LastPriceBeforeClose | MarketPriceRateID | Passthrough | Tier 4 |
| 9 | BidSpreaded | Price.History.LastPriceBeforeClose | BidSpreaded | Passthrough | Tier 4 |
| 10 | AskSpreaded | Price.History.LastPriceBeforeClose | AskSpreaded | Passthrough | Tier 4 |
| 11 | USDConversionRateBidSpreaded | Price.History.LastPriceBeforeClose | USDConversionRateBidSpreaded | Passthrough | Tier 4 |
| 12 | USDConversionRateAskSpreaded | Price.History.LastPriceBeforeClose | USDConversionRateAskSpreaded | Passthrough | Tier 4 |
| 13 | USDConversionPriceRateID | Price.History.LastPriceBeforeClose | USDConversionPriceRateID | Passthrough | Tier 4 |
| 14 | PriceType | Price.History.LastPriceBeforeClose | PriceType | Passthrough | Tier 4 |
| 15 | InsretDate | Price.History.LastPriceBeforeClose | InsretDate | Passthrough (typo preserved from production) | Tier 4 |
| 16 | TradeDate | Price.History.LastPriceBeforeClose | TradeDate | Passthrough | Tier 4 |
| 17 | SourceID | Price.History.LastPriceBeforeClose | SourceID | Passthrough | Tier 4 |
| 18 | etr_y | Generic Pipeline | etr_y | ETL partition column (year) | Tier 5 |
| 19 | etr_ym | Generic Pipeline | etr_ym | ETL partition column (year-month) | Tier 5 |
| 20 | etr_ymd | Generic Pipeline | etr_ymd | ETL partition column (year-month-day) | Tier 5 |

## Lineage Notes

- All 17 business columns are 1:1 passthroughs from Price.History.LastPriceBeforeClose via Bronze lake Parquet.
- No upstream wiki exists for Price DB — all business columns are Tier 4 (inferred from DDL + data sampling).
- The SP uses COPY INTO with AUTO_CREATE_TABLE from Parquet — no transformation logic, no JOINs.
- The "InsretDate" typo exists in the production DDL and is preserved through the pipeline.
- Production PK is (InstrumentID, Occurred) — not enforced in Synapse (HEAP).
