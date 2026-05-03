-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.SentTransactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_senttransactions
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_senttransactions (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions SET TBLPROPERTIES (
    'comment' = 'Records every outbound blockchain transaction sent from eToro wallets, capturing the on-chain transaction hash, source wallet, transaction type, fees, and correlation to the parent request. Source: WalletDB.Wallet.SentTransactions on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'SentTransactions',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions ALTER COLUMN BlockchainTransactionId COMMENT 'The on-chain transaction hash/ID. Unique constraint enforced. Can be looked up on blockchain explorers. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions ALTER COLUMN WalletId COMMENT 'The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer''s wallet. For redemptions, this is the system''s omnibus/redeem wallet. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions ALTER COLUMN Occurred COMMENT 'Timestamp when the transaction was broadcast to the blockchain. NULL only for legacy records. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions ALTER COLUMN CorrelationId COMMENT 'Links to the parent request in Wallet.Requests.CorrelationId. Enables tracing from business request to on-chain transaction. NULL for pre-correlation-era transactions. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions ALTER COLUMN TransactionTypeId COMMENT 'Business purpose: 0=Redeem, 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 9=Staking, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 14=StakeAndRewardsRefund, 15=CustomerMoneyBack. See Transaction Type. FK to Dictionary.TransactionTypes. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions ALTER COLUMN BlockchainFee COMMENT 'Network fee paid in the crypto''s native units. Recorded after on-chain confirmation. Used for cost analysis, customer billing, and financial reconciliation. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactions ALTER COLUMN CryptoId COMMENT 'The cryptocurrency sent. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId for per-wallet per-crypto transaction history queries. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
