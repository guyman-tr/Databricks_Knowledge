-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.TransactionsView
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_transactionsview
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_transactionsview (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview SET TBLPROPERTIES (
    'comment' = 'Comprehensive unified transaction view combining all sent transaction types (redemptions, conversions, payments, staking, and other) with received transactions into a single CTE-based queryable interface with fees, statuses, blockchain details, and customer context. Active replacement for TransactionViewOld. Source: WalletDB.Wallet.TransactionsView on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'TransactionsView',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN gcid COMMENT 'Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN CryptoId COMMENT 'The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN WalletId COMMENT 'The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TranID COMMENT 'Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransStatusId COMMENT 'Latest status ID. Resolved via correlated subquery: SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC. FK to Dictionary.TransactionStatus. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransStatus COMMENT 'Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransDate COMMENT 'Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN Amount COMMENT 'Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN EtoroFees COMMENT 'eToro platform fees. Source varies: Redemptions -> eToroFeeAmount, ConversionOut -> EtoroFeeCalculated, Payments -> EtoroFeeCalculated, Staking -> EtoroFee, Other -> SentTransactionOutputs.EtoroFees. NULL for receives. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN ProviderFees COMMENT 'External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN FeeExchangeRate COMMENT 'Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN BlockchainFee COMMENT 'Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN EffectiveBlockchainFee COMMENT 'Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN ActionTypeId COMMENT 'Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN ActionTypeName COMMENT 'Human-readable direction: ''Sent'' or ''Recive'' (legacy misspelling preserved for backward compatibility). (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN SenderAddress COMMENT 'Sender''s blockchain address. Sends: from WalletPool.PublicAddress (wallet''s own address). Receives: from ReceivedTransactions.SenderAddress (external sender). (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN ReciverAddress COMMENT 'Receiver''s blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN BlockchainTransactionId COMMENT 'On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransactionTypeId COMMENT 'Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransactionType COMMENT 'Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN Occurred COMMENT 'When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN LastStatusUpdateOccurred COMMENT 'Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld). (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionsView)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
