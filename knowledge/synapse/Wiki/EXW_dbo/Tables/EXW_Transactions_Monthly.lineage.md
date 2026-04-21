# EXW_dbo.EXW_Transactions_Monthly — Column Lineage

**Object Type**: Table
**Schema**: EXW_dbo
**Generated**: 2026-04-20
**Pipeline Phase**: 10B

## Table Definition Summary

**DEPRECATED** — historical monthly wallet transaction summary per GCID×CryptoId×WalletId, frozen at 2023-12-31. SP_EXW_Transactions_Monthly(@d date) exists but its entire body is commented out (NO-OP). Data was last written 2024-01-01. Table retains 50.1M rows covering 489,135 GCIDs across 69 months (2018-04-30 to 2023-12-31).

The commented-out SP code is the canonical lineage reference — it documents what the ETL computed when active.

HASH(GCID), CLUSTERED COLUMNSTORE INDEX.

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Confidence |
|---|--------|---------------|---------------|-----------|------------|
| 1 | GCID | EXW_dbo.External_WalletDB_Wallet_TransactionsView | gcid | Direct passthrough | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 2 | RealCID | EXW_dbo.EXW_DimUser | RealCID | JOIN EXW_DimUser ON GCID | Tier 1 — Customer.CustomerStatic |
| 3 | WalletId | EXW_Wallet.CustomerWalletsView | Id | JOIN via GCID+CryptoId | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 4 | CryptoId | EXW_dbo.External_WalletDB_Wallet_TransactionsView | CryptoId | Direct passthrough | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 5 | CryptoName | EXW_Wallet.CryptoTypes | Name | JOIN on CryptoID | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 6 | SentAmount | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Amount (ActionTypeId=1) | ROUND(SUM(Amount + EtoroFees + RelevantBlockchainFee), 8, 1) for sent transactions | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 7 | SentAmountUSD | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Amount × EXW_Price.AvgPrice | ROUND(SUM(AmountOut + EtoroFeesUSD + RelevantBlockchainFeeUSD), 8, 1) | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 8 | RecivedAmount | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Amount (ActionTypeId=2) | ROUND(SUM(Amount), 8, 1) for received transactions | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 9 | RecivedAmountUSD | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Amount × EXW_Price.AvgPrice | ROUND(SUM(Amount*AvgPrice), 8, 1) | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 10 | Amount | (computed) | — | RecivedAmount - SentAmount (net monthly crypto flow) | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 11 | AmountUSD | (computed) | — | RecivedAmountUSD - SentAmountUSD (net monthly USD flow) | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 12 | RelevantBlockchainFee | EXW_dbo.External_WalletDB_Wallet_TransactionsView | BlockchainFee (IsEtoroHandlingFee=0) | SUM(BlockchainFee WHERE IsEtoroHandlingFee=0) — user-borne fees only | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 13 | RelevantBlockchainFeeUSD | EXW_dbo.External_WalletDB_Wallet_TransactionsView | BlockchainFee × AvgPrice | SUM(BlockchainFee × AvgPrice WHERE IsEtoroHandlingFee=0) | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 14 | EtoroFees | EXW_dbo.External_WalletDB_Wallet_TransactionsView | EtoroFees (sent only) | SUM of eToro fees for sent transactions | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 15 | EtoroFeesUSD | EXW_dbo.External_WalletDB_Wallet_TransactionsView | EtoroFees × AvgPrice | SUM(EtoroFees × AvgPrice) | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 16 | BlockchainFee | EXW_dbo.External_WalletDB_Wallet_TransactionsView | BlockchainFee (all, sent only) | SUM(BlockchainFee) for all sent transactions | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 17 | BlockchainFeeUSD | EXW_dbo.External_WalletDB_Wallet_TransactionsView | BlockchainFee × AvgPrice | SUM(BlockchainFee × AvgPrice) | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 18 | EffectiveBlockchainFee | EXW_dbo.External_WalletDB_Wallet_TransactionsView | EffectiveBlockchainFee | SUM(EffectiveBlockchainFee) for sent transactions | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 19 | EffectiveBlockchainFeeUSD | EXW_dbo.External_WalletDB_Wallet_TransactionsView | EffectiveBlockchainFee × AvgPrice | SUM(EffectiveBlockchainFee × AvgPrice) | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 20 | LastRecivedOccurred | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Occurred (ActionTypeId=2) | MAX(Occurred) for received transactions in the month | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 21 | LastSentOccurred | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Occurred (ActionTypeId=1) | MAX(Occurred) for sent transactions in the month | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 22 | EOMDate | (SP parameter) | — | @eom — last day of month containing @d | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 23 | EOMDateID | (SP parameter) | — | @eom_i — YYYYMMDD integer of EOMDate | Tier 2 — SP_EXW_Transactions_Monthly (commented) |
| 24 | UpdateDate | (computed) | — | GETDATE() at SP run time | Tier 2 — SP_EXW_Transactions_Monthly (commented) |

## Source Objects

| Source Object | Relationship | Notes |
|---------------|-------------|-------|
| EXW_dbo.External_WalletDB_Wallet_TransactionsView | Primary source | Full transaction history per wallet; ActionTypeId=1 (sent), ActionTypeId=2 (received) |
| EXW_Wallet.CustomerWalletsView | JOIN on GCID+CryptoId | Wallet-to-user mapping |
| EXW_dbo.EXW_DimUser | JOIN on GCID | RealCID lookup |
| EXW_Wallet.CryptoTypes | LEFT JOIN on CryptoId | Crypto name |
| EXW_Wallet.EXW_Price | LEFT JOIN on CryptoId + date range | USD price for amount conversion |

## UC Lineage

UC Target: `_Not_Migrated`
No UC entity exists for this table. Documentation is for knowledge purposes only.
