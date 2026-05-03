-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.WalletAssets
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletAssets.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_walletassets
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_walletassets (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletassets SET TBLPROPERTIES (
    'comment' = 'Tracks which cryptocurrency assets are visible in each customer''s wallet portfolio, controlling what the user sees in their wallet UI and when assets were first added. Source: WalletDB.Wallet.WalletAssets on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletAssets.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_walletassets SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'WalletAssets',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletassets ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAssets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletassets ALTER COLUMN WalletId COMMENT 'The wallet this asset belongs to. FK to Wallet.Wallets.WalletId. Combined with CryptoId for unique constraint. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAssets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletassets ALTER COLUMN CryptoId COMMENT 'The cryptocurrency asset. FK to Wallet.CryptoTypes.CryptoID. A wallet can hold multiple cryptos - each is a separate WalletAssets row. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAssets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletassets ALTER COLUMN Occurred COMMENT 'When this asset was first added to the wallet. Represents the moment the user first acquired this crypto. Used for "portfolio age" analytics. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAssets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletassets ALTER COLUMN IsShown COMMENT 'Whether this asset is visible in the wallet UI. 1=shown (default), 0=hidden. Allows users or the system to hide zero-balance or deprecated assets without deleting the record. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAssets)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
