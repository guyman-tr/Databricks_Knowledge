-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.BlockchainCryptoProviders
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders SET TBLPROPERTIES (
    'comment' = 'Junction table mapping which wallet providers (BitGo, CUG) serve each blockchain network, linking blockchains to their specific coin provider implementations for multi-provider support. Source: WalletDB.Wallet.BlockchainCryptoProviders on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'BlockchainCryptoProviders',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptoProviders)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders ALTER COLUMN BlockchainCryptoId COMMENT 'The blockchain network this mapping applies to. FK to Wallet.BlockchainCryptos.Id. Values: 1=BTC, 2=ETH, 3=BCH, 4=XRP, 6=LTC, 8=ETC, 18=ADA, 19=DOGE, 21=XLM, 23=EOS, 27=TRX, 64=SOL. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptoProviders)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders ALTER COLUMN WalletProviderId COMMENT 'Top-level wallet custody provider: 1=BitGo (institutional multi-sig custody), 2=CUG (Crypto Unified Gateway, eToro internal), 3=None (internal/virtual operations). See Wallet Provider. FK to Dictionary.WalletProvider. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptoProviders)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders ALTER COLUMN CryptoCoinProviderid COMMENT 'Specific coin provider implementation class for this blockchain/provider combination. Maps to the technical API adapter: 1=BitGoBlockchainProviderV2, 2=BitGoEthereumProviderV2, 3=BitgoRippleProviderV2, 4=BitGoStellarProviderV2, 5=BitGoEOSProviderV2, 6=CUGBlockchainProvider, 7=BitGoTronProviderV2, 8=BitGoEthereumClassicProviderV2, 9=CUGAccountBasedBlockchainProvider. See Crypto Coin Provider. FK to Dictionary.CryptoCoinProviders. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptoProviders)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders ALTER COLUMN Occurred COMMENT 'Timestamp when this provider mapping was created. Enables tracking when blockchains were onboarded to specific providers. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptoProviders)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
