# Lineage: Dealing_dbo.Dealing_Execution_Slippage

## Source Objects

| # | Source Object | Type | Role | Wiki |
|---|--------------|------|------|------|
| 1 | Dealing_staging.Etoro_Hedge_ExecutionLog | Staging table | Trade execution records (InstrumentID, IsBuy, Units, ExecutionRate, ExecutionTime, SendTime, RateIDAtSent, OrderID) | — (unresolved) |
| 2 | CopyFromLake.PriceLog_History_CurrencyPrice | Lake copy | eToro price at SendTime (matched by RateIDAtSent → PriceRateID); also provides BidSpreaded, AskSpreaded | — (unresolved) |
| 3 | CopyFromLake.PricesFromProvider_MarketCurrencyPrice | Lake copy | Kusto LP market price (Bid, Ask, OccurredAtServer) matched via CROSS APPLY latest before ExecutionTime | — (unresolved) |
| 4 | DWH_dbo.Fact_CurrencyPriceWithSplit | DWH fact table | Daily FX rates (Bid, Ask) for USD conversion via cross-currency logic | [Wiki](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CurrencyPriceWithSplit.md) |
| 5 | DWH_dbo.Dim_Instrument | DWH dimension | InstrumentType, BuyCurrencyID, SellCurrencyID, SellCurrency for FX rate derivation | [Wiki](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md) |
| 6 | Dealing_staging.Etoro_Hedge_HBCOrderLog | Staging table | HedgingMode classification: if OrderID found → HBC, else → CBH | — (unresolved) |
| 7 | Dealing_dbo.SP_Execution_Slippage | Stored procedure | Writer SP — daily delete+insert per @Date | [SP Code](../../../../../../DataPlatform/SynapseSQLPool1/sql_dp_prod_we/Dealing_dbo/Stored%20Procedures/Dealing_dbo.SP_Execution_Slippage.sql) |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|---------------|---------------|-----------|------|
| 1 | Date | SP parameter | @Date | Direct assignment | Tier 2 |
| 2 | InstrumentID | Dealing_staging.Etoro_Hedge_ExecutionLog | InstrumentID | Passthrough. FK to DWH_dbo.Dim_Instrument | Tier 1 |
| 3 | Occurred | CopyFromLake.PriceLog_History_CurrencyPrice | Occurred | Passthrough via RateIDAtSent JOIN (SendTime price event timestamp) | Tier 2 |
| 4 | ExecutionTime | Dealing_staging.Etoro_Hedge_ExecutionLog | ExecutionTime | Passthrough (LP fill timestamp) | Tier 2 |
| 5 | IsBuy | Dealing_staging.Etoro_Hedge_ExecutionLog | IsBuy | Passthrough | Tier 2 |
| 6 | Units | Dealing_staging.Etoro_Hedge_ExecutionLog | Units | SUM(Units) grouped by execution group | Tier 2 |
| 7 | ExecutionRate | Dealing_staging.Etoro_Hedge_ExecutionLog | ExecutionRate | Passthrough (group-by key) | Tier 2 |
| 8 | eToro_Price | CopyFromLake.PriceLog_History_CurrencyPrice | Ask / Bid | CASE WHEN IsBuy=1 THEN Ask ELSE Bid END (SendTime price) | Tier 2 |
| 9 | ProviderAmount_USD | Computed | Units, ExecutionRate, FX_Rate | SUM(Units × ExecutionRate × FX_Rate) | Tier 2 |
| 10 | eToro_AmountUSD | Computed | Units, eToro_Price, FX_Rate | SUM(Units × eToro_Price × FX_Rate) | Tier 2 |
| 11 | FX_Rate | DWH_dbo.Fact_CurrencyPriceWithSplit + DWH_dbo.Dim_Instrument | Bid, Ask, SellCurrencyID, BuyCurrencyID | CASE on currency pair: USD-quote=1, USD-base=1/Bid or 1/Ask, GBX=÷100, else cross-rate | Tier 2 |
| 12 | Slippage | Computed | ExecutionRate, eToro_Price, IsBuy | (IsBuy=1?+1:-1) × (ExecutionRate − eToro_Price) | Tier 2 |
| 13 | SlippageInDollar | Computed | eToro_Price, ExecutionRate, Units, FX_Rate, IsBuy | (IsBuy=1?+1:-1) × (eToro_Price − ExecutionRate) × Units × FX_Rate | Tier 2 |
| 14 | Slippage_Percent | Computed | ExecutionRate, eToro_Price, IsBuy | (IsBuy=1?+1:-1) × (ExecutionRate − eToro_Price) / eToro_Price | Tier 2 |
| 15 | UpdateDate | ETL-computed | — | GETDATE() at SP run time | Tier 2 |
| 16 | HedgingMode | Dealing_staging.Etoro_Hedge_HBCOrderLog + ExecutionLog | OrderID | CASE WHEN HBCOrderLog.OrderID IS NOT NULL THEN 'HBC' ELSE 'CBH' END | Tier 2 |
| 17 | KustoTime | CopyFromLake.PricesFromProvider_MarketCurrencyPrice | OccurredAtServer | Passthrough (aliased); latest Kusto price event before ExecutionTime via CROSS APPLY | Tier 2 |
| 18 | Kusto_Price | CopyFromLake.PricesFromProvider_MarketCurrencyPrice | Ask / Bid | CASE WHEN IsBuy=1 THEN AskKusto ELSE BidKusto END | Tier 2 |
| 19 | BidSpreaded | CopyFromLake.PriceLog_History_CurrencyPrice | BidSpreaded | Passthrough from SendTime price record | Tier 2 |
| 20 | AskSpreaded | CopyFromLake.PriceLog_History_CurrencyPrice | AskSpreaded | Passthrough from SendTime price record | Tier 2 |
| 21 | NumberofTransaction | Computed | — | COUNT(*) of raw Etoro_Hedge_ExecutionLog records per execution group | Tier 2 |
