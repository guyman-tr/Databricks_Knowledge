# EXW_dbo.EXW_FactConversions — Column Lineage

> Generated: 2026-04-20 | Phase 10B | Source: WalletDB.Wallet.Conversions + WalletDB.Wallet.ConversionTransactions

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source DB** | WalletDB |
| **Primary Source Table** | Wallet.Conversions |
| **Secondary Source** | Wallet.ConversionTransactions (fee/TX detail columns) |
| **Status Source** | Wallet.ConversionStatuses + Dictionary.ConversionStatuses |
| **Lookup Sources** | EXW_Wallet.CryptoTypes (crypto names), EXW_DimUser / CustomerWalletsView (GCID) |
| **Writer SP** | None found in SSDT — historical one-time load |
| **Last Load** | 2024-04-09 (UpdateDate uniform) |
| **Data Range** | 2018-10-28 to 2023-06-14 (feature deprecated/replaced post-2023) |

## Load Pattern

No dedicated SP writer exists in SSDT. All rows share `UpdateDate = 2024-04-09`, indicating a one-time historical dump. Likely loaded via an ad-hoc query joining WalletDB.Wallet.Conversions, Wallet.ConversionTransactions, Wallet.ConversionStatuses, EXW_Wallet.CryptoTypes, and EXW_DimUser. The feature appears to have been deprecated after June 2023.

## ETL Pipeline

```
WalletDB (etoro-walletdb-prod)
  Wallet.Conversions               ← conversion header (IDs, wallets, amounts)
  Wallet.ConversionTransactions    ← per-leg detail (TXIDs, fees, addresses)
  Wallet.ConversionStatuses        ← current status per conversion
  Dictionary.ConversionStatuses    ← status name lookup (1=Pending, 2=Failed, 3=Completed)
  EXW_Wallet.CryptoTypes           ← crypto names
  EXW_Wallet.CustomerWalletsView   ← GCID lookup from wallet
    |
    |-- [Historical one-time load - 2024-04-09] --|
    v
EXW_dbo.EXW_FactConversions (50,298 rows)
    |
    |-- [Read by BI_DB_dbo.SP_US_Daily_Crypto] --|
    v
BI_DB_dbo.BI_DB_US_Daily_Conversions (via JOIN on ToEtoroSentTXID = EXW_FactTransactions.TranID)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | ConversionID | Wallet.Conversions | Id | Passthrough (rename) | Tier 1 |
| 2 | CorrelationID | Wallet.Conversions | CorrelationId | Passthrough (rename) | Tier 1 |
| 3 | RequestTime | Wallet.Conversions | Occurred | Passthrough (rename) | Tier 1 |
| 4 | FromWalletId | Wallet.Conversions | FromWalletId | Passthrough | Tier 1 |
| 5 | FromAddress | Wallet.ConversionTransactions | ToAddress | FROM-leg destination address | Tier 1 |
| 6 | SendingGCID | EXW_Wallet.CustomerWalletsView | GCID | JOIN on FromWalletId | Tier 2 |
| 7 | RequestedFromAmount | Wallet.Conversions | FromAmount | Passthrough (rename — original request amount) | Tier 1 |
| 8 | FromCryptoID | Wallet.Conversions | FromCryptoId | Passthrough (rename) | Tier 1 |
| 9 | FromCrypto | EXW_Wallet.CryptoTypes | Name | JOIN on FromCryptoId | Tier 2 |
| 10 | ConversionStatus | Wallet.ConversionStatuses + Dictionary.ConversionStatuses | ConversionStatusId | JOIN denormalized; stores status value (1=Pending, 2=Failed, 3=Completed) | Tier 2 |
| 11 | ModificationTime | Wallet.ConversionStatuses | (timestamp of last status change) | Latest status modification time | Tier 2 |
| 12 | FromAmount | Wallet.ConversionTransactions | Amount | FROM-leg actual executed amount | Tier 1 |
| 13 | ToEtoroEstimatedBCFee | Wallet.ConversionTransactions | EstimatedBlockChainFee | TO-leg estimated BC fee — NULL in ALL rows (not populated) | Tier 2 |
| 14 | ToEtoroDate | Wallet.ConversionTransactions | Occurred | TO-leg transaction timestamp | Tier 2 |
| 15 | ConversionID2 | Wallet.Conversions | Id | Duplicate of ConversionID — no transformation | Tier 4 |
| 16 | ToWalletId | Wallet.Conversions | ToWalletId | Passthrough | Tier 1 |
| 17 | ToAddress | Wallet.ConversionTransactions | ToAddress | TO-leg destination address | Tier 1 |
| 18 | RecievingGCID | EXW_Wallet.CustomerWalletsView | GCID | JOIN on ToWalletId; always = SendingGCID (same user controls both wallets) | Tier 2 |
| 19 | RequestedToAmount | Wallet.Conversions | ToAmount | Passthrough (rename — original request amount) | Tier 1 |
| 20 | ToCryptoID | Wallet.Conversions | ToCryptoId | Passthrough (rename) | Tier 1 |
| 21 | ToCrypto | EXW_Wallet.CryptoTypes | Name | JOIN on ToCryptoId | Tier 2 |
| 22 | ToAmount | Wallet.ConversionTransactions | Amount | TO-leg actual executed amount | Tier 1 |
| 23 | FromEtoroEstimatedBCFee | Wallet.ConversionTransactions | EstimatedBlockChainFee | FROM-leg estimated BC fee; NULL for 1,548 rows (3%) | Tier 1 |
| 24 | FromEtoroDate | Wallet.ConversionTransactions | Occurred | FROM-leg transaction timestamp | Tier 2 |
| 25 | ToEtoroSentTXID | EXW_Wallet.SentTransactions | TranID | TO-leg sent transaction internal ID; NULL for 542 rows | Tier 2 |
| 26 | ToEtoroSentBlockchainTXID | EXW_Wallet.SentTransactions | BlockchainTransactionId | TO-leg blockchain hash | Tier 2 |
| 27 | FromEtoroSentTXID | EXW_Wallet.SentTransactions | TranID | FROM-leg sent transaction internal ID | Tier 2 |
| 28 | FromEtoroSentBlockchainTXID | EXW_Wallet.SentTransactions | BlockchainTransactionId | FROM-leg blockchain hash | Tier 2 |
| 29 | SentToEtoroWalletAmount | EXW_Wallet.SentTransactions | Amount | TO-leg gross sent amount | Tier 2 |
| 30 | SentToEtoroWalletEtoroFees | EXW_Wallet.SentTransactions | EtoroFees | TO-leg eToro fees | Tier 2 |
| 31 | SentToEtoroBlockchainFees | EXW_Wallet.SentTransactions | BlockchainFees | TO-leg blockchain fees | Tier 2 |
| 32 | SentFromEtoroWalletAmount | EXW_Wallet.SentTransactions | Amount | FROM-leg gross sent amount | Tier 2 |
| 33 | SentFromEtoroWalletEtoroFees | EXW_Wallet.SentTransactions | EtoroFees | FROM-leg eToro fees | Tier 2 |
| 34 | SentFromEtoroBlockchainFees | EXW_Wallet.SentTransactions | BlockchainFees | FROM-leg blockchain fees | Tier 2 |
| 35 | ToEtoroReceivedTXID | EXW_Wallet.ReceivedTransactions | TranID | TO-leg received transaction internal ID | Tier 2 |
| 36 | ToEtoroReceivedAmount | EXW_Wallet.ReceivedTransactions | Amount | TO-leg amount received in destination wallet | Tier 2 |
| 37 | ToEtoroReceiveBlockchainFee | EXW_Wallet.ReceivedTransactions | BlockchainFee | TO-leg blockchain fee on receipt | Tier 2 |
| 38 | FromEtoroReceivedTXID | EXW_Wallet.ReceivedTransactions | TranID | FROM-leg received transaction internal ID | Tier 2 |
| 39 | FromEtoroReceivedAmount | EXW_Wallet.ReceivedTransactions | Amount | FROM-leg amount received back | Tier 2 |
| 40 | FromEtoroReceiveBlockchainFee | EXW_Wallet.ReceivedTransactions | BlockchainFee | FROM-leg blockchain fee on receipt | Tier 2 |
| 41 | ReceivedTime | EXW_Wallet.ReceivedTransactions | (timestamp) | Timestamp when both legs received confirmation | Tier 2 |
| 42 | UpdateDate | ETL load process | — | Timestamp of last ETL load; uniform 2024-04-09 for all rows | Tier 2 |
| 43 | FromBlockchainCryptoId | EXW_Wallet.BlockchainCryptos | BlockchainCryptoId | Blockchain-layer crypto ID for FROM side | Tier 2 |
| 44 | FromBlockchainCryptoName | EXW_Wallet.BlockchainCryptos | Name | Blockchain-layer crypto name for FROM side | Tier 2 |
| 45 | ToBlockchainCryptoId | EXW_Wallet.BlockchainCryptos | BlockchainCryptoId | Blockchain-layer crypto ID for TO side | Tier 2 |
| 46 | ToBlockchainCryptoName | EXW_Wallet.BlockchainCryptos | Name | Blockchain-layer crypto name for TO side | Tier 2 |
_DDL column count: 46. Lineage rows 1–46 account for all columns._

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 14 | ConversionID, CorrelationID, RequestTime, FromWalletId, FromAddress, RequestedFromAmount, FromCryptoID, FromAmount, ToWalletId, ToAddress, RequestedToAmount, ToCryptoID, ToAmount, FromEtoroEstimatedBCFee |
| Tier 2 | 31 | SendingGCID, FromCrypto, ConversionStatus, ModificationTime, ToEtoroEstimatedBCFee(NULL), ToEtoroDate, RecievingGCID, ToCrypto, FromEtoroDate, ToEtoroSentTXID, ToEtoroSentBlockchainTXID, FromEtoroSentTXID, FromEtoroSentBlockchainTXID, SentToEtoroWalletAmount, SentToEtoroWalletEtoroFees, SentToEtoroBlockchainFees, SentFromEtoroWalletAmount, SentFromEtoroWalletEtoroFees, SentFromEtoroBlockchainFees, ToEtoroReceivedTXID, ToEtoroReceivedAmount, ToEtoroReceiveBlockchainFee, FromEtoroReceivedTXID, FromEtoroReceivedAmount, FromEtoroReceiveBlockchainFee, ReceivedTime, UpdateDate, FromBlockchainCryptoId, FromBlockchainCryptoName, ToBlockchainCryptoId, ToBlockchainCryptoName |
| Tier 4 | 1 | ConversionID2 (duplicate of ConversionID) |

## UC External Lineage

No UC mapping found for EXW_dbo.EXW_FactConversions in Generic Pipeline mapping.
UC Target: `_Not_Migrated`
