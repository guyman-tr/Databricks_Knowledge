---
object: EXW_dbo.EXW_FactRedeemTransactions
type: Table
generated: 2026-04-20
phase: 10B
---

# Column Lineage — EXW_dbo.EXW_FactRedeemTransactions

## ETL Chain

```
WalletDB.Wallet.Redemptions (source — redemption lifecycle, position, amounts, fees)
  + WalletDB.Wallet.Requests + WalletDB.Wallet.RequestStatuses (FinalRedeemStatus CASE)
  + WalletDB.Wallet.SentTransactions (blockchain tx hash, wallet, timestamp, fee)
  + WalletDB.Wallet.SentTransactionOutputs (destination address, amount, eToro fee flag)
  + WalletDB.Wallet.ReceivedTransactions (confirmation of crypto arrival in customer wallet)
  + EXW_Wallet.CustomerWalletsView (SendingGCID, SendingAddress by WalletId)
  + EXW_dbo.External_WalletDB_Wallet_TransactionsView (SentEtoroFees, EffectiveBlockchainFees)
  + EXW_Wallet.SentTransactionReplaces (BitGo replacement exclusion for re-run guard)
  + EXW_Wallet.CryptoTypes (BlockchainCryptoId lookup)
    |
    | SP_EXW_FactRedeemTransactions @d DATE
    | DELETE by RedeemID (for today's + re-run positions) + INSERT
    v
EXW_dbo.EXW_FactRedeemTransactions
    |
    | consumed by:
    +-- EXW_dbo.EXW_ReimbursementFollowUp (redemption fee reconciliation)
    +-- Ad-hoc finance/compliance redemption reporting
```

## Column Lineage

| # | DWH Column | Tier | Source Table | Source Column | Transform |
|---|------------|------|-------------|---------------|-----------|
| 1 | RedeemID | T1 | WalletDB.Wallet.Redemptions | Id | Renamed: Id → RedeemID |
| 2 | PositionID | T1 | WalletDB.Wallet.Redemptions | PositionId | Passthrough |
| 3 | RequestingGcid | T1 | WalletDB.Wallet.Redemptions | RequestingGcid | Passthrough |
| 4 | CryptoId | T1 | WalletDB.Wallet.Redemptions | CryptoId | Passthrough |
| 5 | RequestedAmount | T1 | WalletDB.Wallet.Redemptions | RequestedAmount | Passthrough |
| 6 | eToroFeeAmount | T2 | ETL-computed | — | Hardcoded NULL in SP (#re_temp override); source value from Redemptions.eToroFeeAmount is discarded; use SentEtoroFees instead |
| 7 | FinalRedeemStatus | T2 | ETL-computed | RequestStatuses.RequestStatusId | CASE: 1→'Completed', 2→'Error', else→'Pending' |
| 8 | SentTransactionID | T1 | WalletDB.Wallet.SentTransactions | Id | Renamed: Id → SentTransactionID |
| 9 | BlockchainTransactionID | T1 | WalletDB.Wallet.SentTransactions | BlockchainTransactionId | Passthrough (CAST to nvarchar(4000)) |
| 10 | SendingWalletID | T1 | WalletDB.Wallet.SentTransactions | WalletId | Passthrough |
| 11 | SentTime | T1 | WalletDB.Wallet.SentTransactions | Occurred | Renamed: Occurred → SentTime; CAST as datetime |
| 12 | SendingGCID | T2 | EXW_Wallet.CustomerWalletsView | Gcid | JOIN on SentTransactions.WalletId = CustomerWalletsView.Id |
| 13 | SendingAddress | T2 | EXW_Wallet.CustomerWalletsView | Address | JOIN on SentTransactions.WalletId = CustomerWalletsView.Id |
| 14 | ReceiveAddress | T1 | WalletDB.Wallet.SentTransactionOutputs | ToAddress | Renamed: ToAddress → ReceiveAddress; filtered by SourceId = PositionId |
| 15 | SentAmount | T1 | WalletDB.Wallet.SentTransactionOutputs | Amount | Passthrough; filtered by SourceId = PositionId, highest Amount per SentTransactionId |
| 16 | SentEtoroFees | T2 | EXW_dbo.External_WalletDB_Wallet_TransactionsView | EtoroFees, FeeExchangeRate | Computed: CAST(EtoroFees × FeeExchangeRate AS NUMERIC(38,8)) — converts fee to USD equivalent |
| 17 | SentBlockchainFees | T2 | WalletDB.Wallet.SentTransactions | BlockchainFee | ETL-computed: BlockchainFee / COUNT(outputs per SentTransactionId) — per-output fee allocation |
| 18 | IsEtoroFee | T1 | WalletDB.Wallet.SentTransactionOutputs | IsEtoroFee | Passthrough |
| 19 | TotalSentAmountInBCTX | T2 | ETL-computed | — | Hardcoded NULL; deprecated column retained for schema backward compatibility |
| 20 | ReceivedTransactionID | T1 | WalletDB.Wallet.ReceivedTransactions | Id | Renamed: Id → ReceivedTransactionID; LEFT JOIN on BlockchainTransactionId + ReceiverAddress = ReceiveAddress |
| 21 | ReceivedAmount | T1 | WalletDB.Wallet.ReceivedTransactions | Amount | Passthrough; matched by BlockchainTransactionId + ReceiverAddress |
| 22 | ReceivedBlockchainFees | T2 | ETL-computed | — | Hardcoded NULL; deprecated column retained for schema backward compatibility |
| 23 | ReceivingGCID | T1 | WalletDB.Wallet.Redemptions | RequestingGcid | Same value as RequestingGcid (redeemer = recipient in all standard cases) |
| 24 | TotalrxAmountInBCTX | T2 | ETL-computed | ReceivedTransactions.Amount | Subquery: MAX(ReceivedAmount) GROUP BY ReceivedTransactionID — total received in the blockchain tx |
| 25 | CountReceivedTXInBCTX | T2 | ETL-computed | ReceivedTransactions.Amount | Subquery: COUNT(ReceivedAmount) GROUP BY ReceivedTransactionID — output count in the blockchain tx |
| 26 | ReceivedInAllTXTable | T2 | ETL-computed | — | TotalrxAmountInBCTX / CountReceivedTXInBCTX — per-output average received amount |
| 27 | UpdateDate | T2 | ETL-computed | — | GETDATE() at insert time |
| 28 | EffectiveBlockchainFees | T2 | EXW_dbo.External_WalletDB_Wallet_TransactionsView | EffectiveBlockchainFee | Passthrough from TransactionsView (ActionTypeId=1 filter) |
| 29 | BlockchainCryptoId | T2 | EXW_Wallet.CryptoTypes | BlockchainCryptoId | LEFT JOIN on CryptoId; the underlying blockchain crypto ID (e.g., ETH for USDC tokens) |

## Tier Summary

- **Tier 1**: 15 columns (RedeemID, PositionID, RequestingGcid, CryptoId, RequestedAmount, SentTransactionID, BlockchainTransactionID, SendingWalletID, SentTime, ReceiveAddress, SentAmount, IsEtoroFee, ReceivedTransactionID, ReceivedAmount, ReceivingGCID) — passthrough/renamed from WalletDB upstream wikis (Redemptions, SentTransactions, SentTransactionOutputs, ReceivedTransactions)
- **Tier 2**: 14 columns — ETL-computed, hardcoded NULLs, lookup-enriched without upstream wiki, or from non-wiki sources (CustomerWalletsView, TransactionsView)
- **Tier 3**: 0
- **Tier 4**: 0

## UC Target

- **Synapse**: EXW_dbo.EXW_FactRedeemTransactions
- **UC Target**: `_Not_Migrated` (no UC mapping found — wallet redemption transaction fact, Synapse-only)
