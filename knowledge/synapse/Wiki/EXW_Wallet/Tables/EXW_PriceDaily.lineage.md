# EXW_Wallet.EXW_PriceDaily — Lineage

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Documentation |
|---|--------------|-------------|--------|----------|--------------|---------------|
| 1 | EXW_Currency.Instruments | Table | EXW_Currency | Synapse | Instrument ID mapping | No wiki |
| 2 | EXW_Currency.Currencies | Table | EXW_Currency | Synapse | Currency symbol filtering (USD sell side) | No wiki |
| 3 | EXW_Wallet.CryptoMarketRatesMappings | Table | EXW_Wallet | Synapse | CryptoId and CryptoName resolution | No wiki |
| 4 | EXW_Wallet.CryptoTypes | Table | EXW_Wallet | Synapse | eToroInstrumentID and BlockchainCryptoId mapping | No wiki |
| 5 | EXW_Wallet.ETL_InstrumentRates_ByHour | Table | EXW_Wallet | Synapse | Hourly bid/ask rates (AskRateAvg, BidRateAvg) | No wiki |
| 6 | EXW_Wallet.EXW_Price | Table | EXW_Wallet | Synapse | Gap-fill for missing hourly prices | No wiki |
| 7 | EXW_Wallet.SP_Prices | Stored Procedure | EXW_Wallet | Synapse | Writer SP — daily price aggregation | No wiki |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| InstrumentID | EXW_Currency.Instruments / EXW_Wallet.CryptoMarketRatesMappings | Id / CryptoId | CASE WHEN eToroInstrumentID >= 100000 THEN eToroInstrumentID ELSE CryptoId END | Tier 2 |
| eToroInstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | Passthrough | Tier 2 |
| CryptoID | EXW_Wallet.CryptoMarketRatesMappings | CryptoId | Passthrough | Tier 2 |
| CryptoName | EXW_Wallet.CryptoMarketRatesMappings | MarketRatesCurrencySymbol | Rename passthrough | Tier 2 |
| AvgPrice | EXW_Wallet.ETL_InstrumentRates_ByHour | AskRateAvg, BidRateAvg | (BidRateAvg + AskRateAvg) / 2, gap-filled from EXW_Price, ROW_NUMBER Rn=1 last hour | Tier 2 |
| BlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | Passthrough via mapping join | Tier 2 |
| BlockchainCryptoName | EXW_Wallet.CryptoTypes | Name | Rename passthrough (ct1.Name) | Tier 2 |
| FullDate | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | CAST(DateHour AS DATE) | Tier 2 |
| FullDateID | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | CONVERT(VARCHAR(8), DateHour, 112) — integer date key | Tier 2 |
| UpdateDate | EXW_Wallet.SP_Prices | — | GETDATE() — ETL timestamp | Tier 2 |
