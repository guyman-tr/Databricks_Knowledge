# Lineage: EXW_dbo.EXW_FactConversions

## Source Objects

| # | Source Object | Source Type | Database | Schema | How Used |
|---|--------------|------------|----------|--------|----------|
| 1 | Wallet.Conversions | Table | WalletDB | Wallet | Primary source — base conversion record (Id, wallets, requested amounts, crypto IDs, correlation, occurred) |
| 2 | Wallet.ConversionTransactions | Table | WalletDB | Wallet | Per-leg transaction details — actual amounts, fees, addresses, timestamps for From and To legs |
| 3 | EXW_Wallet.CryptoTypes | Table | Synapse | EXW_Wallet | Lookup — resolves CryptoID to crypto name, and BlockchainCryptoId/Name |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|--------------|-----------|------|
| 1 | ConversionID | Wallet.Conversions | Id | Passthrough (renamed) | Tier 1 |
| 2 | CorrelationID | Wallet.Conversions | CorrelationId | Passthrough | Tier 1 |
| 3 | RequestTime | Wallet.Conversions | Occurred | Passthrough (renamed) | Tier 1 |
| 4 | FromWalletId | Wallet.Conversions | FromWalletId | Passthrough | Tier 1 |
| 5 | FromAddress | Wallet.ConversionTransactions | ToAddress | From-leg address (renamed from To-leg ToAddress column) | Tier 1 |
| 6 | SendingGCID | — | — | Customer GCID from wallet-to-customer mapping; not in upstream tables | Tier 3 |
| 7 | RequestedFromAmount | Wallet.Conversions | FromAmount | Passthrough (renamed — original user-requested sell amount) | Tier 1 |
| 8 | FromCryptoID | Wallet.Conversions | FromCryptoId | Passthrough | Tier 1 |
| 9 | FromCrypto | EXW_Wallet.CryptoTypes | Name | Lookup on FromCryptoID | Tier 2 |
| 10 | ConversionStatus | — | — | Status code from Wallet.ConversionStatuses (no upstream wiki) | Tier 3 |
| 11 | ModificationTime | — | — | Last modification timestamp across conversion lifecycle | Tier 3 |
| 12 | FromAmount | Wallet.ConversionTransactions | Amount | From-leg actual amount (renamed) | Tier 1 |
| 13 | ToEtoroEstimatedBCFee | Wallet.ConversionTransactions | EstimatedBlockChainFee | To-leg estimated blockchain fee (renamed) | Tier 1 |
| 14 | ToEtoroDate | Wallet.ConversionTransactions | Occurred | To-leg transaction timestamp (renamed) | Tier 1 |
| 15 | ConversionID2 | Wallet.Conversions | Id | Duplicate of ConversionID | Tier 1 |
| 16 | ToWalletId | Wallet.Conversions | ToWalletId | Passthrough | Tier 1 |
| 17 | ToAddress | Wallet.ConversionTransactions | ToAddress | To-leg destination address | Tier 1 |
| 18 | RecievingGCID | — | — | Customer GCID from wallet-to-customer mapping; always equals SendingGCID | Tier 3 |
| 19 | RequestedToAmount | Wallet.Conversions | ToAmount | Passthrough (renamed — original user-requested buy amount) | Tier 1 |
| 20 | ToCryptoID | Wallet.Conversions | ToCryptoId | Passthrough | Tier 1 |
| 21 | ToCrypto | EXW_Wallet.CryptoTypes | Name | Lookup on ToCryptoID | Tier 2 |
| 22 | ToAmount | Wallet.ConversionTransactions | Amount | To-leg actual amount (renamed) | Tier 1 |
| 23 | FromEtoroEstimatedBCFee | Wallet.ConversionTransactions | EstimatedBlockChainFee | From-leg estimated blockchain fee (renamed) | Tier 1 |
| 24 | FromEtoroDate | Wallet.ConversionTransactions | Occurred | From-leg transaction timestamp (renamed) | Tier 1 |
| 25 | ToEtoroSentTXID | — | — | To-leg sent transaction ID from Wallet.SentTransactions (no upstream wiki) | Tier 3 |
| 26 | ToEtoroSentBlockchainTXID | — | — | To-leg sent blockchain transaction hash from Wallet.SentTransactions | Tier 3 |
| 27 | FromEtoroSentTXID | — | — | From-leg sent transaction ID from Wallet.SentTransactions | Tier 3 |
| 28 | FromEtoroSentBlockchainTXID | — | — | From-leg sent blockchain transaction hash from Wallet.SentTransactions | Tier 3 |
| 29 | SentToEtoroWalletAmount | Wallet.ConversionTransactions | Amount | To-leg amount sent (renamed) | Tier 1 |
| 30 | SentToEtoroWalletEtoroFees | Wallet.ConversionTransactions | EtoroFeeCalculated | To-leg eToro fee (renamed) | Tier 1 |
| 31 | SentToEtoroBlockchainFees | Wallet.ConversionTransactions | EstimatedBlockChainFee | To-leg blockchain fee on sent transaction | Tier 1 |
| 32 | SentFromEtoroWalletAmount | Wallet.ConversionTransactions | Amount | From-leg amount sent (renamed) | Tier 1 |
| 33 | SentFromEtoroWalletEtoroFees | Wallet.ConversionTransactions | EtoroFeeCalculated | From-leg eToro fee (renamed) | Tier 1 |
| 34 | SentFromEtoroBlockchainFees | Wallet.ConversionTransactions | EstimatedBlockChainFee | From-leg blockchain fee on sent transaction | Tier 1 |
| 35 | ToEtoroReceivedTXID | — | — | To-leg received transaction ID (from Wallet.ReceivedTransactions, no wiki) | Tier 3 |
| 36 | ToEtoroReceivedAmount | — | — | To-leg received crypto amount | Tier 3 |
| 37 | ToEtoroReceiveBlockchainFee | — | — | To-leg received blockchain fee | Tier 3 |
| 38 | FromEtoroReceivedTXID | — | — | From-leg received transaction ID | Tier 3 |
| 39 | FromEtoroReceivedAmount | — | — | From-leg received crypto amount | Tier 3 |
| 40 | FromEtoroReceiveBlockchainFee | — | — | From-leg received blockchain fee | Tier 3 |
| 41 | ReceivedTime | — | — | Timestamp when the conversion was fully received/completed | Tier 3 |
| 42 | UpdateDate | — | — | ETL load timestamp (all rows show 2024-04-09) | Tier 3 |
| 43 | FromBlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | From-leg blockchain crypto ID via CryptoTypes lookup | Tier 2 |
| 44 | FromBlockchainCryptoName | EXW_Wallet.CryptoTypes | Name | From-leg blockchain crypto name via CryptoTypes lookup | Tier 2 |
| 45 | ToBlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | To-leg blockchain crypto ID via CryptoTypes lookup | Tier 2 |
| 46 | ToBlockchainCryptoName | EXW_Wallet.CryptoTypes | Name | To-leg blockchain crypto name via CryptoTypes lookup | Tier 2 |
