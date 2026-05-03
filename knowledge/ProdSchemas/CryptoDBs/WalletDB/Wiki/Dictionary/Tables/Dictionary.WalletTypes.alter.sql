-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.WalletTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletTypes.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_wallettypes
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_wallettypes (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_wallettypes SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying wallets by their operational purpose - redeem, conversion, funding, payment, customer, crypto-to-fiat, or staking refund. Source: WalletDB.Dictionary.WalletTypes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletTypes.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_wallettypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'WalletTypes',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_wallettypes ALTER COLUMN Id COMMENT 'Unique identifier. Values: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer, 6=C2F, 7=StakingRefund. FK target for Wallet.Wallets.WalletTypeId. (Tier 1 - upstream wiki, WalletDB.Dictionary.WalletTypes)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_wallettypes ALTER COLUMN Name COMMENT 'Unique wallet type label. Used in wallet management logic to route operations to the correct wallet type. (Tier 1 - upstream wiki, WalletDB.Dictionary.WalletTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
