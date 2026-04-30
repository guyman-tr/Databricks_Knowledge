-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Staking.StakingTransactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_staking_stakingtransactions
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_staking_stakingtransactions (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingtransactions SET TBLPROPERTIES (
    'comment' = 'Records the blockchain transfer details for each staking operation, including the destination staking pool address and associated fees. Source: WalletDB.Staking.StakingTransactions on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_staking_stakingtransactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Staking',
    'source_table' = 'StakingTransactions',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingtransactions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key. (Tier 1 - upstream wiki, WalletDB.Staking.StakingTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingtransactions ALTER COLUMN ExternalStakingAddress COMMENT 'The blockchain address of the staking pool where assets were sent. For ETH, an Ethereum address (0x-prefixed). Denormalized from Staking.StakingExternalAddress to preserve historical address even if the active pool changes. Passed as a parameter to InsertStakingTransaction. (Tier 1 - upstream wiki, WalletDB.Staking.StakingTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingtransactions ALTER COLUMN StakingId COMMENT 'The staking operation this transaction belongs to. FK to Staking.Staking.Id. 1:1 relationship - each staking operation has exactly one transaction record. Used by Staking.StakingData view to join fees into the reporting dataset. (Tier 1 - upstream wiki, WalletDB.Staking.StakingTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingtransactions ALTER COLUMN EtoroFee COMMENT 'eToro''s service fee for processing the staking delegation, in the staked crypto''s units. Currently 0 across all records - staking transfers are fee-free for users. (Tier 1 - upstream wiki, WalletDB.Staking.StakingTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingtransactions ALTER COLUMN BlockchainEstFee COMMENT 'Estimated blockchain network fee (gas fee) for the staking transaction, in the staked crypto''s units. Currently 0 across all records - blockchain fees absorbed by eToro. (Tier 1 - upstream wiki, WalletDB.Staking.StakingTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingtransactions ALTER COLUMN Occurred COMMENT 'Timestamp when this transaction record was created. Closely follows the Staking.Staking.Occurred timestamp (typically within 1 second). (Tier 1 - upstream wiki, WalletDB.Staking.StakingTransactions)';

