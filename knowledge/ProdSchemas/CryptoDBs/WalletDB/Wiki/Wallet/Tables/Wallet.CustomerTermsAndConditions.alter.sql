-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.CustomerTermsAndConditions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CustomerTermsAndConditions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_wallet_customertermsandconditions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_wallet_customertermsandconditions (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_wallet_customertermsandconditions SET TBLPROPERTIES (
    'comment' = 'Records each customer''s acceptance of Terms and Conditions versions, tracking which T&C version each user has agreed to and when they accepted it. Source: WalletDB.Wallet.CustomerTermsAndConditions on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CustomerTermsAndConditions.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_wallet_customertermsandconditions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'CustomerTermsAndConditions',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_wallet_customertermsandconditions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerTermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_customertermsandconditions ALTER COLUMN Gcid COMMENT 'Global Customer ID of the user who accepted. Indexed with TermsAndConditionId for per-user acceptance queries. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerTermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_customertermsandconditions ALTER COLUMN TermsAndConditionId COMMENT 'The T&C version accepted. FK to Wallet.TermsAndConditions.Id. Multiple rows per Gcid reflect acceptance of different versions over time. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerTermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_customertermsandconditions ALTER COLUMN Occured COMMENT 'Timestamp when the user accepted. Note: column name typo "Occured" preserved from original schema. (Tier 1 - upstream wiki, WalletDB.Wallet.CustomerTermsAndConditions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
