---
object: EXW_dbo.EXW_V_RedeemReconciliation
type: View
base_table: EXW_dbo.EXW_RedeemReconciliation
filter: EntryAppears = 'BothSidesEntry' AND [etoro - RedeemStatus] = 'TransactionDone'
lineage_generated: 2026-04-20
---

# Column Lineage — EXW_dbo.EXW_V_RedeemReconciliation

## View Definition Summary

```
SELECT 51 columns (renamed) FROM EXW_dbo.EXW_RedeemReconciliation
WHERE EntryAppears = 'BothSidesEntry'
  AND [etoro - RedeemStatus] = 'TransactionDone'
```

Excludes from base table (7 columns — deprecated/internal wallet metrics):
- [Wallet - CryptoId] (col 30)
- [Wallet - SumAmountInBlockchainTransaction] (col 44) — always NULL
- [Wallet - ReceivedTXBlockchainFees] (col 47) — always NULL
- [Wallet - SumReceivedInBCTX - with Dupes] (col 48)
- [Wallet - CountDupes] (col 49)
- [Wallet - SumReceivedInBCTX - deduped] (col 50)
- [Wallet - ReceivedTXAMLStatus] (col 51)

## Column Lineage (View col → Base Table col)

| # | View Column | Base Table Column | Rename? | Tier |
|---|------------|-------------------|---------|------|
| 1 | PositionID | PositionID | No | Tier 1 — Billing.Redeem |
| 2 | EntryAppears | EntryAppears | No | Tier 2 — SP_EXW_RedeemReconciliation |
| 3 | IsTestAccount | IsTestAccount | No | Tier 2 — SP_EXW_RedeemReconciliation |
| 4 | RedeemID | RedeemID | No | Tier 1 — Billing.Redeem |
| 5 | CID | [etoro - CID] | Yes | Tier 1 — Billing.Redeem |
| 6 | GCID | [Wallet - RequestingGCID] | Yes | Tier 1 — WalletDB.Wallet.Redemptions |
| 7 | CryptoName | CryptoName | No | Tier 2 — SP_EXW_RedeemReconciliation |
| 8 | CryptoID | [etoro - CryptoID] | Yes | Tier 1 — Billing.Redeem |
| 9 | EtoroRedeemStatus | [etoro - RedeemStatus] | Yes | Tier 1 — Billing.Redeem (always 'TransactionDone' in this view) |
| 10 | EtoroRedeemReason | [etoro - RedeemReason] | Yes | Tier 1 — Billing.Redeem |
| 11 | EtoroRedeemAmount | [etoro - RedeemAmount] | Yes | Tier 1 — Billing.Redeem |
| 12 | EtoroRedeemFee | [etoro - RedeemFee] | Yes | Tier 1 — Billing.Redeem |
| 13 | EtoroBlockchainFee | [etoro - BlockchainFee] | Yes | Tier 1 — Billing.Redeem |
| 14 | EtoroAmountOnRequestUSD | [etoro - AmountOnRequestUSD] | Yes | Tier 1 — Billing.Redeem |
| 15 | EtoroAmountOnCloseUSD | [eToro - AmountOnCloseUSD] | Yes | Tier 1 — Billing.Redeem |
| 16 | FundingID | [etoro - FundingID] | Yes | Tier 1 — Billing.Redeem |
| 17 | InstrumentID | [etoro - InstrumentID] | Yes | Tier 1 — Billing.Redeem |
| 18 | RequestDate | [etoro - RequestDate] | Yes | Tier 1 — Billing.Redeem |
| 19 | ModificationDate | [etoro - ModificationDate] | Yes | Tier 1 — Billing.Redeem |
| 20 | RequestDateID | [etoro - RequestDateID] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 21 | ModificationDateID | [etoro - ModificationDateID] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 22 | WithdrawToFundingID | [etoro - WithdrawToFundingID] | Yes | Tier 1 — Billing.Redeem |
| 23 | WithdrawID | [etoro - WithdrawID] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 24 | EtoroAmount | [etoro - Amount] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 25 | EtoroCashoutType | [etoro - CashoutType] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 26 | EtoroProcessorValueDate | [etoro - ProcessorValueDate] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 27 | EtoroDepotID | [etoro - DepotID] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 28 | EtoroApproved | [etoro - Approved] | Yes | Tier 1 — Billing.Withdraw |
| 29 | EtoroCashoutStatus | [etoro - CashoutStatus] | Yes | Tier 1 — Billing.Withdraw |
| 30 | EtoroCashoutReason | [etoro - CashoutReason] | Yes | Tier 1 — Billing.Withdraw |
| 31 | WalletSendingWalletID | [Wallet - SendingWalletID] | Yes | Tier 1 — WalletDB.Wallet.SentTransactions |
| 32 | WalletRedeemID | [Wallet - RedeemID] | Yes | Tier 1 — WalletDB.Wallet.Redemptions |
| 33 | WalletPositionID | [Wallet - PositionID] | Yes | Tier 1 — WalletDB.Wallet.Redemptions |
| 34 | WalletRequestedAmount | [Wallet - RequestedAmount] | Yes | Tier 1 — WalletDB.Wallet.Redemptions |
| 35 | WalletRedeemStatus | [Wallet - RedeemStatus] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 36 | WalletSentTransactionID | [Wallet - SentTransactionID] | Yes | Tier 1 — WalletDB.Wallet.SentTransactions |
| 37 | WalletBlockchainTransactionID | [Wallet - BlockchainTransactionID] | Yes | Tier 1 — WalletDB.Wallet.SentTransactions |
| 38 | WalletSenderAddress | [Wallet - SenderAddress] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 39 | WalletReceiverAddress | [Wallet - ReceiverAddress] | Yes | Tier 1 — WalletDB.Wallet.SentTransactionOutputs |
| 40 | WalletSentAmount | [Wallet - SentAmount] | Yes | Tier 1 — WalletDB.Wallet.SentTransactionOutputs |
| 41 | WalletSentTXEtoroFees | [Wallet - SentTXEtoroFees] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 42 | WalletSentTTXBlockchainFees | [Wallet - SentTTXBlockchainFees] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 43 | WalletReceivedTransactionID | [Wallet - ReceivedTransactionID] | Yes | Tier 1 — WalletDB.Wallet.ReceivedTransactions |
| 44 | WalletReceivedAmount | [Wallet - ReceivedAmount] | Yes | Tier 1 — WalletDB.Wallet.ReceivedTransactions |
| 45 | WalletEffectiveBlockchainFees | [Wallet - EffectiveBlockchainFees] | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 46 | IsCFD | isCFD | Yes | Tier 2 — SP_EXW_RedeemReconciliation |
| 47 | IsGermanBaFin | IsGermanBaFin | No | Tier 2 — SP_EXW_RedeemReconciliation |
| 48 | ManagerOpsID | [etoro - ManagerOpsID] | Yes | Tier 1 — Billing.Redeem |
| 49 | ManagerID | [etoro - ManagerID] | Yes | Tier 1 — Billing.Redeem |
| 50 | EtoroRemark | [etoro - Remark] | Yes | Tier 1 — Billing.Redeem |
| 51 | UpdateDate | UpdateDate | No | Tier 2 — SP_EXW_RedeemReconciliation |

## Notes

- All columns are pass-through renames from EXW_RedeemReconciliation (no computation in view)
- View filter eliminates ~all non-completed redemptions (OnlyEtoroSideEntry, NoUserReceiveEntry rows excluded)
- 1,117,023 rows = completed redemptions (TransactionDone + BothSidesEntry)
- No UC target (view — no direct lake mapping)
