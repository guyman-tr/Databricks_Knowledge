-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.WalletPoolStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletPoolStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_walletpoolstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_walletpoolstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_walletpoolstatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle statuses for pre-generated wallet addresses in the wallet pool, tracking progress from creation through funding to readiness for customer assignment. Source: WalletDB.Dictionary.WalletPoolStatuses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletPoolStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_walletpoolstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'WalletPoolStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_walletpoolstatuses ALTER COLUMN Id COMMENT 'Unique identifier. Values: 1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated, 5=FundingSent, 6=FundingVerified, 7=FundingFailed, 10=Timeout, 11=VerifiedForAssign. Gap at 8-9. FK target for Wallet.WalletPoolStatuses. (Tier 1 - upstream wiki, WalletDB.Dictionary.WalletPoolStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_walletpoolstatuses ALTER COLUMN Name COMMENT 'Status label. Unique constraint ensures no duplicates. Used in pool management dashboards and monitoring alerts. (Tier 1 - upstream wiki, WalletDB.Dictionary.WalletPoolStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
