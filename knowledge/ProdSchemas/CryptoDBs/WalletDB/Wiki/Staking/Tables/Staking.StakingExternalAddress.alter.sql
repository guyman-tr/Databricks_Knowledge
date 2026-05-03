-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Staking.StakingExternalAddress
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_staking_stakingexternaladdress
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_staking_stakingexternaladdress (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingexternaladdress SET TBLPROPERTIES (
    'comment' = 'Configuration table holding the external blockchain addresses of eToro''s staking pools, one active address per supported cryptocurrency. Source: WalletDB.Staking.StakingExternalAddress on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_staking_stakingexternaladdress SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Staking',
    'source_table' = 'StakingExternalAddress',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingexternaladdress ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key. Used as RecordId in Wallet.Checksums for address integrity verification. (Tier 1 - upstream wiki, WalletDB.Staking.StakingExternalAddress)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingexternaladdress ALTER COLUMN ExternalAddress COMMENT 'The blockchain address of eToro''s staking pool. For ETH, this is an Ethereum address (0x-prefixed, 42 chars). This is the destination address for staking transfers. Read by Staking.GetStakingExternalAddress and validated by the checksum procedures. (Tier 1 - upstream wiki, WalletDB.Staking.StakingExternalAddress)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingexternaladdress ALTER COLUMN CryptoId COMMENT 'The cryptocurrency this staking address serves. FK to Wallet.CryptoTypes.CryptoID. Currently only 2 (ETH). Part of the unique constraint ensuring one active address per crypto. (Tier 1 - upstream wiki, WalletDB.Staking.StakingExternalAddress)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingexternaladdress ALTER COLUMN IsActive COMMENT 'Whether this address is the currently active staking pool for its crypto. 1=active (used for new staking transfers), 0=retired (kept for audit). Default 1 for new addresses. Filtered by GetStakingExternalAddress and part of unique index. (Tier 1 - upstream wiki, WalletDB.Staking.StakingExternalAddress)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingexternaladdress ALTER COLUMN EffectiveFrom COMMENT 'Timestamp when this address became the active staking pool. Defaults to UTC now on insert. Used for audit trail when addresses are rotated. (Tier 1 - upstream wiki, WalletDB.Staking.StakingExternalAddress)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
