-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.WalletPool
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_walletpool
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_walletpool (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool SET TBLPROPERTIES (
    'comment' = 'Pre-generated pool of blockchain wallets created in advance and ready for assignment to customers, providing instant wallet provisioning without waiting for on-chain creation. Source: WalletDB.Wallet.WalletPool on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 120-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'WalletPool',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '120'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPool)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool ALTER COLUMN WalletId COMMENT 'Internal wallet identifier (GUID). The primary business key used across the wallet system. Unique constraint. FK target for Wallet.WalletAddresses, Wallet.ReceivedTransactions, and Wallet.AmlValidations. Also referenced by Wallet.Wallets (logical link, not FK). (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPool)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool ALTER COLUMN BlockchainCryptoId COMMENT 'The blockchain this pool wallet was created for. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain network the PublicAddress belongs to. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPool)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool ALTER COLUMN ProviderWalletId COMMENT 'Wallet identifier assigned by the external custody provider (BitGo or CUG). Used for all API interactions with the provider. Format varies by provider. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPool)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool ALTER COLUMN PublicAddress COMMENT 'Blockchain address associated with this wallet. Users send crypto to this address. NULL during initial creation before address generation completes. Format depends on blockchain (e.g., bc1... for BTC, 0x... for ETH). (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPool)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool ALTER COLUMN Created COMMENT 'Timestamp when this pool wallet was created. Used for pool age monitoring and FIFO assignment ordering. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPool)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpool ALTER COLUMN WalletProviderId COMMENT 'Custody provider that holds the keys: 1=BitGo, 2=CUG, 3=None. See Wallet Provider. FK to Dictionary.WalletProvider. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPool)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
