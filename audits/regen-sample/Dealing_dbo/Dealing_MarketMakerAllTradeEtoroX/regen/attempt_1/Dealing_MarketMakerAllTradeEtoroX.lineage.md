# Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Schema | Database |
|---|---|---|---|---|---|
| 1 | MarketMaker_ExchangesData_Trades | Staging Table (lake copy) | Primary source — eToroX exchange trade records | CopyFromLake | Synapse |
| 2 | External_MarketMaker_dbo_Instruments | Staging Table | Lookup — instrument name resolution | Dealing_staging | Synapse |
| 3 | External_MarketMaker_dbo_Exchanges | Staging Table | Lookup — exchange name resolution | Dealing_staging | Synapse |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Date | SP parameter | @Date | Passthrough from SP input parameter | Tier 2 |
| 2 | Id | MarketMaker_ExchangesData_Trades | Id | Passthrough | Tier 3 |
| 3 | CreationTime | MarketMaker_ExchangesData_Trades | CreationTime | Passthrough | Tier 3 |
| 4 | Instrument_Name | External_MarketMaker_dbo_Instruments | Name | JOIN on InstrumentId, renamed to Instrument_Name | Tier 3 |
| 5 | Name | External_MarketMaker_dbo_Exchanges | Name | JOIN on ExchangeId | Tier 3 |
| 6 | Side | MarketMaker_ExchangesData_Trades | Side | CASE: 1='Sell', 0='Buy' | Tier 2 |
| 7 | Price | MarketMaker_ExchangesData_Trades | Price | CASE: -1 → '0', ELSE raw value | Tier 2 |
| 8 | Quantity | MarketMaker_ExchangesData_Trades | Quantity | CASE: -1 → '0', ELSE raw value | Tier 2 |
| 9 | Funds | MarketMaker_ExchangesData_Trades | Price, Quantity | Computed: Price × Quantity | Tier 2 |
| 10 | ApiPrice | MarketMaker_ExchangesData_Trades | ApiPrice | Passthrough | Tier 3 |
| 11 | APiQuantity | MarketMaker_ExchangesData_Trades | ApiQuantity | Passthrough | Tier 3 |
| 12 | ApiFunds | MarketMaker_ExchangesData_Trades | ApiPrice, ApiQuantity | Computed: ApiPrice × ApiQuantity | Tier 2 |
| 13 | Fee | MarketMaker_ExchangesData_Trades | Fee | CASE: -1 → '0', ELSE raw value | Tier 2 |
| 14 | FeeCurrency | MarketMaker_ExchangesData_Trades | FeeCurrency | Passthrough | Tier 3 |
| 15 | PartyName | MarketMaker_ExchangesData_Trades | PartyName | Passthrough | Tier 3 |
| 16 | InsertTime | MarketMaker_ExchangesData_Trades | InsertTime | Passthrough | Tier 3 |
| 17 | OrderId | MarketMaker_ExchangesData_Trades | OrderId | Passthrough | Tier 3 |
| 18 | TradeId | MarketMaker_ExchangesData_Trades | TradeId | Passthrough | Tier 3 |
| 19 | Unit | MarketMaker_ExchangesData_Trades | Quantity, Side | CASE: Sell → Quantity×(-1), Buy → Quantity | Tier 2 |
| 20 | Value | MarketMaker_ExchangesData_Trades | Unit, Price, ApiPrice, Fee, FeeCurrency | Complex: Unit×(-1)×Price - Fee, with FeeCurrency branching | Tier 2 |
| 21 | UpdateDate | ETL | GETDATE() | ETL-generated timestamp | Tier 2 |
