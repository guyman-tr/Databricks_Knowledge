# Lineage: DWH_dbo.Fact_CurrencyPriceWithSplit

> Column-level lineage from production Data Lake source to DWH Synapse table.

## Source Chain

```
Data Lake (PriceLog/Candles raw data)
  -> DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView  [standard daily]
  -> DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory  [split dates only]
  -> SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)
  -> DWH_dbo.Fact_CurrencyPriceWithSplit
```

## Generic Pipeline Mapping

| Field | Value |
|-------|-------|
| generic_id | 603 |
| copy_strategy | Merge |
| frequency_minutes | 1440 (daily) |
| UC table | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit |
| datalake_path | Gold/sql_dp_prod_we/DWH_dbo/Fact_CurrencyPriceWithSplit/ |
| business_group | DWH |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Notes |
|---|-----------|---------------|---------------|-----------|-------|
| 1 | ProviderID | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | ProviderID | Passthrough | 3 distinct values in prod |
| 2 | InstrumentID | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | InstrumentID | Passthrough | On split dates: from SplitInstHistory |
| 3 | Occurred | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Occurred | Passthrough | |
| 4 | OccurredDate | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDate | Passthrough | |
| 5 | OccurredDateID | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDateID | Passthrough | YYYYMMDD int format |
| 6 | isvalid | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | isvalid | Passthrough | ~54% = 1 in prod |
| 7 | AskSpreaded | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | AskSpreaded | Passthrough | numeric(36,12) |
| 8 | BidSpreaded | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | BidSpreaded | Passthrough | numeric(36,12) |
| 9 | RateLastEx | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | RateLastEx | Passthrough | |
| 10 | Ask | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Ask | Passthrough | |
| 11 | Bid | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Bid | Passthrough | |
| 12 | UpdateDate | ETL-computed | N/A | GETDATE() | Not price time - ETL load timestamp |
| 13 | ConvertRateIsBuy_1 | ETL-computed (UPDATE pass) | Bid + Ext_FCPWS_Instrument | CASE: SellCurrencyID=1->1.00, BuyCurrencyID=1->1/Bid, else cross-rate | ~1.3M NULLs where no cross-rate available |
| 14 | ConvertRateIsBuy_0 | ETL-computed (UPDATE pass) | Ask + Ext_FCPWS_Instrument | CASE: SellCurrencyID=1->1.00, BuyCurrencyID=1->1/Ask, else cross-rate | ~1.3M NULLs where no cross-rate available |

## ETL SP Details

**SP**: DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse
**Author**: Adi Ferber (2021-10-12)
**Pattern**: Per-date incremental (DELETE for @DateID + INSERT)
**Key Changes**:
- 2022-04-27: Replaced PriceLog_Candles_CurrencyPriceMaxDateWithSplitView with SplitInstHistory for split instruments
- 2023-02-26: Added ConvertRateIsBuy_1 and ConvertRateIsBuy_0 columns (MeravHu)
- 2023-03-09: Bugfix (MeravHu)

## Upstream Wiki

No upstream wiki available. DWH_staging.PriceLog_Candles_* is a Data Lake intermediate layer (not a production DB_Schema source with an etoro wiki).
