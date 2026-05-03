-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.StakingStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.StakingStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_stakingstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_stakingstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_stakingstatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle statuses for crypto staking transfer operations in the WalletDB system. Source: WalletDB.Dictionary.StakingStatuses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.StakingStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_stakingstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'StakingStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_stakingstatuses ALTER COLUMN Id COMMENT 'Unique identifier for the staking status. Values: 1=Pending, 2=Failed, 3=Completed. Referenced by Staking.StakingStatuses.StakingStatusId via explicit FK. See Staking Status for full business definitions. (Tier 1 - upstream wiki, WalletDB.Dictionary.StakingStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_stakingstatuses ALTER COLUMN Name COMMENT 'Human-readable label for the staking status. Resolved via JOIN in Staking.StakingData view and Wallet.GetStakingTransactionList/V2 functions to display status names in reporting. (Tier 1 - upstream wiki, WalletDB.Dictionary.StakingStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
