# Lineage — DWH_dbo.Fact_CurrencyPriceWithSplit

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|-------------|
| 1 | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Staging View | DWH_staging | Synapse | Primary data source (non-split instruments) |
| 2 | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory | Staging View | DWH_staging | Synapse | Split-adjusted data source (instruments with stock splits) |
| 3 | etoro_History_SplitRatio | Staging Table | DWH_staging | Synapse | Split ratio reference for detecting split events |
| 4 | etoro_Trade_GetInstrument | Staging Table | DWH_staging | Synapse | Instrument currency pair mapping (BuyCurrencyID, SellCurrencyID) |
| 5 | Ext_FCPWS_History_SplitRatio | Helper Table | DWH_dbo | Synapse | Intermediate staging for split ratios (truncated/refilled each run) |
| 6 | Ext_FCPWS_Instrument | Helper Table | DWH_dbo | Synapse | Intermediate staging for instrument currency pairs (truncated/refilled each run) |
| 7 | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | Stored Procedure | DWH_dbo | Synapse | Writer SP — daily delete-insert + split adjustment + USD conversion |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|--------------|-----------|------|
| ProviderID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | ProviderID | Passthrough | Tier 3 |
| InstrumentID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | InstrumentID | Passthrough | Tier 3 |
| Occurred | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Occurred | Passthrough | Tier 3 |
| OccurredDate | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDate | Passthrough | Tier 3 |
| OccurredDateID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDateID | Passthrough | Tier 3 |
| isvalid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | isvalid | Passthrough | Tier 3 |
| AskSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | AskSpreaded | Passthrough | Tier 3 |
| BidSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | BidSpreaded | Passthrough | Tier 3 |
| RateLastEx | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | RateLastEx | Passthrough | Tier 3 |
| Ask | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Ask | Passthrough | Tier 3 |
| Bid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Bid | Passthrough | Tier 3 |
| UpdateDate | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | GETDATE() | ETL-computed: always set to current timestamp at load time | Tier 2 |
| ConvertRateIsBuy_1 | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | CASE expression | ETL-computed: USD conversion rate for buy side based on instrument currency pair (BuyCurrencyID/SellCurrencyID) using CASE logic with self-join to price table | Tier 2 |
| ConvertRateIsBuy_0 | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | CASE expression | ETL-computed: USD conversion rate for sell side based on instrument currency pair (BuyCurrencyID/SellCurrencyID) using CASE logic with self-join to price table | Tier 2 |
