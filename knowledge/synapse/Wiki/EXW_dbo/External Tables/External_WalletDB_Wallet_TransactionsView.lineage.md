# EXW_dbo.External_WalletDB_Wallet_TransactionsView — Column Lineage

> Generated: 2026-04-20 | Phase 10B | Source: WalletDB.Wallet.TransactionsView (Generic Pipeline Bronze export)

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source DB** | WalletDB |
| **Primary Source Object** | Wallet.TransactionsView (unified transaction view — all sent + received) |
| **Writer** | Generic Pipeline (ADF/CopyFromLake) — no Synapse SP writer |
| **Bronze Location** | Bronze/WalletDB/Wallet/TransactionsView/ |
| **UC Target** | `wallet.bronze_walletdb_wallet_transactionsview` |
| **Refresh** | Override strategy, every 60 minutes |
| **Last Data** | 2026-04-20 (live — updated hourly) |
| **Data Range** | 2018-04-23 to today (Occurred/TransDate) |

## Load Pattern

Generic Pipeline exports `Wallet.TransactionsView` from WalletDB to Bronze Parquet/Delta at `Bronze/WalletDB/Wallet/TransactionsView/` every 60 minutes using an Override (full replacement) strategy. The Synapse External Table maps directly to this Bronze location via the `internal-sources` data source. No transformation occurs — it is a 1:1 column projection of the upstream view output.

## ETL Pipeline

```
WalletDB (etoro-walletdb-prod)
  Wallet.TransactionsView          <- unified view: 7 CTEs (Redeem, ConversionIn/Out, Payment,
                                      Staking, Other, Received) UNION ALL, enriched with
                                      Gcid, SenderAddress, status/type names
    |
    |-- [Generic Pipeline -- Override, every 60 min] --|
    v
Azure Data Lake (Bronze)
  Bronze/WalletDB/Wallet/TransactionsView/  <- Delta/Parquet files
    |
    |-- [EXW_dbo.External_WalletDB_Wallet_TransactionsView (External Table)] --|
    |-- [Unity Catalog: wallet.bronze_walletdb_wallet_transactionsview] --|
    v
Consumers (Synapse): SP_EXW_Fact_Transactions, SP_EXW_Transactions_Monthly,
                     SP_EXW_Hourly, SP_EXW_FactRedeemTransactions, SP_EXW_UserCalculatedBalance
```

## Column Lineage

All 22 columns are direct passthroughs from Wallet.TransactionsView. No transformation occurs.

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | gcid | Wallet.TransactionsView | gcid | Passthrough | Tier 1 |
| 2 | CryptoId | Wallet.TransactionsView | CryptoId | Passthrough | Tier 1 |
| 3 | WalletId | Wallet.TransactionsView | WalletId | Passthrough (uniqueidentifier -> nvarchar(4000) in Bronze) | Tier 1 |
| 4 | TranID | Wallet.TransactionsView | TranID | Passthrough | Tier 1 |
| 5 | TransStatusId | Wallet.TransactionsView | TransStatusId | Passthrough | Tier 1 |
| 6 | TransStatus | Wallet.TransactionsView | TransStatus | Passthrough | Tier 1 |
| 7 | TransDate | Wallet.TransactionsView | TransDate | Passthrough | Tier 1 |
| 8 | Amount | Wallet.TransactionsView | Amount | Passthrough | Tier 1 |
| 9 | EtoroFees | Wallet.TransactionsView | EtoroFees | Passthrough | Tier 1 |
| 10 | ProviderFees | Wallet.TransactionsView | ProviderFees | Passthrough | Tier 1 |
| 11 | FeeExchangeRate | Wallet.TransactionsView | FeeExchangeRate | Passthrough | Tier 1 |
| 12 | BlockchainFee | Wallet.TransactionsView | BlockchainFee | Passthrough | Tier 1 |
| 13 | EffectiveBlockchainFee | Wallet.TransactionsView | EffectiveBlockchainFee | Passthrough | Tier 1 |
| 14 | ActionTypeId | Wallet.TransactionsView | ActionTypeId | Passthrough | Tier 1 |
| 15 | ActionTypeName | Wallet.TransactionsView | ActionTypeName | Passthrough | Tier 1 |
| 16 | SenderAddress | Wallet.TransactionsView | SenderAddress | Passthrough | Tier 1 |
| 17 | ReciverAddress | Wallet.TransactionsView | ReciverAddress | Passthrough (legacy misspelling preserved) | Tier 1 |
| 18 | BlockchainTransactionId | Wallet.TransactionsView | BlockchainTransactionId | Passthrough | Tier 1 |
| 19 | TransactionTypeId | Wallet.TransactionsView | TransactionTypeId | Passthrough | Tier 1 |
| 20 | TransactionType | Wallet.TransactionsView | TransactionType | Passthrough | Tier 1 |
| 21 | Occurred | Wallet.TransactionsView | Occurred | Passthrough | Tier 1 |
| 22 | LastStatusUpdateOccurred | Wallet.TransactionsView | LastStatusUpdateOccurred | Passthrough | Tier 1 |
_DDL column count: 22. Lineage rows 1-22 account for all columns._

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 22 | All 22 columns — direct passthrough from WalletDB.Wallet.TransactionsView via Generic Pipeline |

## UC External Lineage

UC Target: `wallet.bronze_walletdb_wallet_transactionsview`
Mapped in `_generic_pipeline_mapping.json` — Generic Pipeline produces this Bronze Delta table directly.
