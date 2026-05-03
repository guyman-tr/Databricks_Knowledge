# EXW_Wallet.EXW_Price — Column Lineage

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|--------------|-------------|--------|----------|--------------|
| 1 | EXW_Wallet.ETL_InstrumentRates_ByHour | Table | EXW_Wallet | Synapse | Hourly rate source — provides AskRateAvg, BidRateAvg, DateHour per instrument |
| 2 | EXW_Currency.Instruments | Table | EXW_Currency | Synapse | Instrument master — provides wallet InstrumentID (Id) |
| 3 | EXW_Currency.Currencies | Table | EXW_Currency | Synapse | Currency lookup — filters to USD sell-currency instruments |
| 4 | EXW_Wallet.CryptoMarketRatesMappings | Table | EXW_Wallet | Synapse | Maps currency symbol to CryptoId and MarketRatesCurrencySymbol |
| 5 | EXW_Wallet.CryptoTypes | Table | EXW_Wallet | Synapse | Crypto type master — provides eToroInstrumentID, BlockchainCryptoId, BlockchainCryptoName |
| 6 | EXW_Wallet.SP_Prices | Stored Procedure | EXW_Wallet | Synapse | Writer SP — daily delete+insert with hourly gap-filling |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|---------------|---------------|-----------|------|
| 1 | InstrumentID | EXW_Wallet.CryptoTypes / EXW_Wallet.CryptoMarketRatesMappings | InstrumentId / CryptoId | CASE WHEN eToroInstrumentID >= 100000 THEN eToroInstrumentID ELSE CryptoId END | Tier 2 |
| 2 | eToroInstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | Passthrough from CryptoTypes via #mapping | Tier 2 |
| 3 | CryptoID | EXW_Wallet.CryptoMarketRatesMappings | CryptoId | Passthrough via #mapping | Tier 2 |
| 4 | CryptoName | EXW_Wallet.CryptoMarketRatesMappings | MarketRatesCurrencySymbol | Rename: MarketRatesCurrencySymbol → CryptoName | Tier 2 |
| 5 | AskLast | EXW_Wallet.ETL_InstrumentRates_ByHour | AskRateAvg | Rename: AskRateAvg → AskLast. Gap-filled from prior hour or prior day. | Tier 2 |
| 6 | BidLast | EXW_Wallet.ETL_InstrumentRates_ByHour | BidRateAvg | Rename: BidRateAvg → BidLast. Gap-filled from prior hour or prior day. | Tier 2 |
| 7 | AvgPrice | EXW_Wallet.ETL_InstrumentRates_ByHour | AskRateAvg, BidRateAvg | (BidRateAvg + AskRateAvg) / 2. Gap-filled from prior hour or prior day. | Tier 2 |
| 8 | DateFrom | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | Rename: DateHour → DateFrom. Represents hour-bucket start. | Tier 2 |
| 9 | DateTo | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | DATEADD(HOUR, 1, DateHour). Hour-bucket end. | Tier 2 |
| 10 | BlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | Passthrough via #mapping join chain | Tier 2 |
| 11 | BlockchainCryptoName | EXW_Wallet.CryptoTypes | Name | Rename: CryptoTypes.Name → BlockchainCryptoName (ct1 alias for blockchain-level CryptoTypes row) | Tier 2 |
| 12 | FullDate | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | CAST(DateHour AS DATE) | Tier 2 |
| 13 | FullDateID | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | CONVERT(VARCHAR(8), DateHour, 112) → int date key YYYYMMDD | Tier 2 |
| 14 | UpdateDate | EXW_Wallet.SP_Prices | — | GETDATE() at insert time | Tier 2 |
