-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.Wallets
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_wallets
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_wallets (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets SET TBLPROPERTIES (
    'comment' = 'Central registry of all customer and system wallets, linking each wallet to its owner (Gcid), blockchain, and operational purpose (type). The core entity connecting users to their crypto holdings. Source: WalletDB.Wallet.Wallets on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'Wallets',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN WalletId COMMENT 'Internal wallet identifier (GUID). Unique constraint. The universal business key used across the entire system. FK target for Wallet.SentTransactions, Wallet.Conversions, Wallet.Payments, Wallet.Redemptions, and Wallet.WalletAssets. Matches the WalletId in Wallet.WalletPool from which this wallet was assigned. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN Gcid COMMENT 'Global Customer ID of the wallet owner. For system wallets (types 1-4, 6-7), this is a system/service account ID. For customer wallets (type 5), this is the real user. Indexed for per-customer lookups. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN BlockchainCryptoId COMMENT 'The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Combined with Gcid and WalletTypeId for unique customer wallet constraint. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN WalletTypeId COMMENT 'Operational purpose: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. See Wallet Type. FK to Dictionary.WalletTypes. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN IsActive COMMENT 'Whether this wallet is currently operational. 1=active, 0=deactivated (funds locked, no new transactions). Set to 0 by Wallet.DeactivateWallet. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN Occurred COMMENT 'Timestamp when this wallet was created/assigned to the customer. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN BeginDate COMMENT 'System-versioned temporal column (ROW START). Tracks when this version of the row became current. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN EndDate COMMENT 'System-versioned temporal column (ROW END). Default 9999-12-31 for current rows. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_wallets ALTER COLUMN IsActivated COMMENT 'Whether the wallet has completed blockchain activation. 1=fully activated, 0=pending activation (awaiting on-chain confirmation). Most wallets are immediately activated. (Tier 1 - upstream wiki, WalletDB.Wallet.Wallets)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
