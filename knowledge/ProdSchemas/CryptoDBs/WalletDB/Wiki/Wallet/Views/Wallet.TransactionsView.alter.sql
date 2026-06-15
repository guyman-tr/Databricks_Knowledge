-- =============================================================================
-- Databricks ALTER Script: main.wallet.bronze_walletdb_wallet_transactionsview  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN gcid COMMENT 'Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN CryptoId COMMENT 'The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN WalletId COMMENT 'The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TranID COMMENT 'Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransStatusId COMMENT 'Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransStatus COMMENT 'Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransDate COMMENT 'Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN Amount COMMENT 'Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN EtoroFees COMMENT 'eToro platform fees. Source varies: Redemptions -> eToroFeeAmount, ConversionOut -> EtoroFeeCalculated, Payments -> EtoroFeeCalculated, Staking -> EtoroFee, Other -> SentTransactionOutputs.EtoroFees. NULL for receives.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN ProviderFees COMMENT 'External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN FeeExchangeRate COMMENT 'Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN BlockchainFee COMMENT 'Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN EffectiveBlockchainFee COMMENT 'Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN ActionTypeId COMMENT 'Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN ActionTypeName COMMENT 'Human-readable direction: ''Sent'' or ''Recive'' (legacy misspelling preserved for backward compatibility).';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN SenderAddress COMMENT 'Sender''s blockchain address. Sends: from WalletPool.PublicAddress (wallet''s own address). Receives: from ReceivedTransactions.SenderAddress (external sender).';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN ReciverAddress COMMENT 'Receiver''s blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN BlockchainTransactionId COMMENT 'On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransactionTypeId COMMENT 'Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN TransactionType COMMENT 'Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN Occurred COMMENT 'When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_transactionsview ALTER COLUMN LastStatusUpdateOccurred COMMENT 'Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:23:24 UTC
-- Statements: 22/22 succeeded
-- ====================
