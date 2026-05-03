-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.ReceivedTransactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_receivedtransactions
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_receivedtransactions (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions SET TBLPROPERTIES (
    'comment' = 'Records every inbound blockchain transaction received into eToro wallets, capturing the sender address, amount, blockchain hash, and classification of the incoming funds for processing and compliance. Source: WalletDB.Wallet.ReceivedTransactions on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'ReceivedTransactions',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. FK target for Wallet.ReceivedTransactionStatuses. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN Occurred COMMENT 'Timestamp when this received transaction was detected and recorded by the system. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN WalletId COMMENT 'The eToro wallet that received the funds. FK to Wallet.WalletPool.WalletId. Used to identify the owning customer. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN SenderAddress COMMENT 'The blockchain address that sent the funds. NULL when the sender cannot be determined (e.g., coinbase transactions). Used for AML screening. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN ReceiverAddress COMMENT 'The specific blockchain address within the wallet that received the funds. A wallet may have multiple addresses. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN Amount COMMENT 'Amount of crypto received in native units. NULL for zero-value transactions (e.g., token approvals). (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN BlockchainFee COMMENT 'Network fee associated with this incoming transaction. Usually the sender''s fee, recorded for reference. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN CorrelationId COMMENT 'Links to the parent request in Wallet.Requests.CorrelationId for system-initiated receives (redemptions, conversions). NULL for unexpected external deposits. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN BlockchainTransactionId COMMENT 'On-chain transaction hash. Format varies by blockchain (0x-prefixed hex for ETH, base58 for SOL, uppercase hex for XRP). Used for blockchain explorer lookups. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN BlockchainTransactionDate COMMENT 'Timestamp of the transaction on the blockchain itself (block time). May differ from Occurred which is when the system detected it. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN CryptoId COMMENT 'The cryptocurrency received. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN ReceivedTransactionTypeId COMMENT 'Business classification: 1=MoneyIn, 2=Redeem, 3=Funding, 4=ConversionFromUser, 5=ConversionFromEtoro, 6=Payment, 7=RedeemAsic, 8=StakeAndRewardsRefund. See Received Transaction Type. FK to Dictionary.ReceivedTransactionTypes. Default 1 (MoneyIn). (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN NormalizedSenderAddress COMMENT 'Computed PERSISTED column stripping protocol prefix and query parameters from SenderAddress for consistent matching. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN NormalizedReceiverAddress COMMENT 'Computed PERSISTED column stripping protocol prefix and query parameters from ReceiverAddress for consistent matching. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN ProviderTransactionId COMMENT 'Transaction identifier assigned by the custody provider (BitGo/CUG). May differ from the blockchain hash. Used for provider API reconciliation. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactions ALTER COLUMN ReceiveRequestCorrelationId COMMENT 'Links to a ReceiveTransaction request (RequestTypeId=8) when the incoming transaction is processed as a formal request. Distinct from CorrelationId which links to the originating request. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
