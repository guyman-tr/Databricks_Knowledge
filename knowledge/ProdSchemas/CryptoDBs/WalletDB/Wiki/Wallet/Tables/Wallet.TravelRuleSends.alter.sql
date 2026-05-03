-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.TravelRuleSends
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleSends.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_travelrulesends
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_travelrulesends (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelrulesends SET TBLPROPERTIES (
    'comment' = 'Links outbound send transactions to their Travel Rule whitelisted address records, tracking which compliance-approved address was used for each send operation. Source: WalletDB.Wallet.TravelRuleSends on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleSends.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_travelrulesends SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'TravelRuleSends',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelrulesends ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleSends)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelrulesends ALTER COLUMN WalletId COMMENT 'Source wallet that performed the send. FK to Wallet.WalletPool.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleSends)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelrulesends ALTER COLUMN CorrelationId COMMENT 'Links to the parent send request. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleSends)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelrulesends ALTER COLUMN TravelRuleAddressId COMMENT 'The whitelisted address used for this send. FK to Wallet.TravelRuleAddresses.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleSends)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelrulesends ALTER COLUMN Created COMMENT 'Timestamp of this send-address linkage. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleSends)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
