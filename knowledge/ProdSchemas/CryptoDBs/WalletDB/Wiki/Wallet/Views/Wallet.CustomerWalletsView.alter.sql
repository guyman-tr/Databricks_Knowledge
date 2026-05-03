-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.CustomerWalletsView
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_customerwalletsview
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_customerwalletsview (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview SET TBLPROPERTIES (
    'comment' = 'The primary abstraction layer for accessing active customer wallets, joining wallet ownership, pool addresses, and visible crypto assets into a single denormalized row per customer-crypto combination. Source: WalletDB.Wallet.CustomerWalletsView on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 120-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'CustomerWalletsView',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '120'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Id COMMENT 'The wallet''s universal business key (aliased from Wallets.WalletId). Used as the primary identifier across the entire wallet system - referenced by SentTransactions, ReceivedTransactions, Conversions, Payments, Redemptions, and all balance/transaction lookups. From Wallet.Wallets.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Gcid COMMENT 'Global Customer ID of the wallet owner. For customer wallets (type 5, 99.99% of rows), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets. From Wallet.Wallets.Gcid. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN CryptoId COMMENT 'The cryptocurrency asset visible in this wallet. FK to Wallet.CryptoTypes.CryptoID. Combined with Gcid for the standard wallet lookup pattern: WHERE Gcid = @gcid AND CryptoId = @cryptoId. From Wallet.WalletAssets.CryptoId. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Address COMMENT 'Blockchain public address associated with this wallet. Users send/receive crypto at this address. Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x, SOL is base58. Aliased from Wallet.WalletPool.PublicAddress. May be NULL during initial creation before address generation completes. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN BlockchainProviderWalletId COMMENT 'External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the provider. Aliased from Wallet.WalletPool.ProviderWalletId. Format is provider-specific (typically a hex hash for BitGo). (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Occurred COMMENT 'Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN WalletTypeId COMMENT 'Operational purpose of the wallet: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. See Wallet Type. FK to Dictionary.WalletTypes. From Wallet.Wallets.WalletTypeId. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN IsActive COMMENT 'Whether this wallet is currently operational. Always 1 in this view (WHERE filter), but included for schema compatibility. 1=active, 0=deactivated (excluded by view). From Wallet.Wallets.IsActive. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Status COMMENT 'Computed activation status: 0=Created/Active (wallet fully operational, IsActivated=1), 5=Pending activation (awaiting blockchain confirmation, IsActivated=0). Computed in view: CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END. 99.6% of rows are Status=0. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN WalletRecordId COMMENT 'Auto-incrementing surrogate key from the base Wallets table. Aliased from Wallet.Wallets.Id. Useful for ordering by creation sequence. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN BlockchainCryptoId COMMENT 'The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain the Address belongs to. May differ from CryptoId for multi-token blockchains (e.g., ERC-20 tokens share the ETH blockchain). From Wallet.Wallets.BlockchainCryptoId. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN WalletProviderId COMMENT 'Custody provider: 1=BitGo (97.5% of wallets, multi-sig), 2=CUG (2.5%, MPC-based, newer blockchains like SOL). See Wallet Provider. FK to Dictionary.WalletProvider. From Wallet.WalletPool.WalletProviderId. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN IsActivated COMMENT 'Whether the wallet has completed initial blockchain activation. 1=activated (fully operational), 0=pending activation. The Status column is derived from this value. From Wallet.Wallets.IsActivated. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerWalletsView)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
