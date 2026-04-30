-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.ConversionStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_conversionstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_conversionstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversionstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history for crypto-to-crypto conversions, tracking each lifecycle transition from pending through completion or failure. Source: WalletDB.Wallet.ConversionStatuses on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_conversionstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'ConversionStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversionstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing event identifier. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversionstatuses ALTER COLUMN ConversionId COMMENT 'Parent conversion. FK to Wallet.Conversions.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversionstatuses ALTER COLUMN ConversionStatusId COMMENT 'Status: 1=Pending, 2=Failed, 3=Completed. See Conversion Status. FK to Dictionary.ConversionStatuses. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversionstatuses ALTER COLUMN Occurred COMMENT 'Timestamp of this status transition. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionStatuses)';

