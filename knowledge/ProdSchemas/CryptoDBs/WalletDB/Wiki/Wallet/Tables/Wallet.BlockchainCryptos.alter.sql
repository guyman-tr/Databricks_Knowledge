-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.BlockchainCryptos
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_blockchaincryptos
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_blockchaincryptos (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptos SET TBLPROPERTIES (
    'comment' = 'Master reference table of all supported blockchain networks, defining each chain''s identifier, address validation pattern, and blockchain provider mapping. Source: WalletDB.Wallet.BlockchainCryptos on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptos SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'BlockchainCryptos',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptos ALTER COLUMN Id COMMENT 'Unique blockchain network identifier. Manually assigned (not IDENTITY) to maintain stable IDs across environments. Referenced by Wallet.CryptoTypes, Wallet.Wallets, Wallet.WalletPool, and Wallet.BlockchainCryptoProviders as BlockchainCryptoId. Gaps exist in sequence (e.g., 5, 7 missing) - likely reserved IDs for blockchains that were planned but not launched. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptos)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptos ALTER COLUMN Name COMMENT 'Standard ticker symbol for the blockchain (e.g., BTC, ETH, XRP, SOL). Unique constraint enforced by IX_Wallet_BlockchainCryptos__Name. Used for human-readable identification and API parameter matching. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptos)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptos ALTER COLUMN Occurred COMMENT 'Timestamp when this blockchain was added to the system. Original blockchains (BTC, ETH, BCH, XRP, LTC, XLM) all share the same date (2019-06-11), indicating the initial platform launch batch. Newer chains have later dates tracking their go-live. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptos)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptos ALTER COLUMN CryptoCoinProviderId COMMENT 'Blockchain provider implementation used for this chain: 1=BitGoBlockchainProviderV2 (UTXO chains like BTC, LTC, BCH, also SOL, ADA, DOGE, TRX, ETC), 2=BitGoEthereumProviderV2 (ETH/ERC-20), 3=BitgoRippleProviderV2 (XRP), 4=BitGoStellarProviderV2 (XLM), 5=BitGoEOSProviderV2 (EOS). See Crypto Coin Provider. FK to Dictionary.CryptoCoinProviders. (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptos)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_blockchaincryptos ALTER COLUMN AddressPattern COMMENT 'Regex pattern for validating blockchain addresses before any transaction. Each blockchain has a unique pattern matching its address format. The default (.*?) accepts all strings (used when provider handles validation). Updated when chains add new address formats (e.g., Bitcoin SegWit). (Tier 1 - upstream wiki, WalletDB.Wallet.BlockchainCryptos)';

