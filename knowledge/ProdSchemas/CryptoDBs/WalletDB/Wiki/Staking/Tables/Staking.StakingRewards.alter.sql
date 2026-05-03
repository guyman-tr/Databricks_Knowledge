-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Staking.StakingRewards
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_staking_stakingrewards
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_staking_stakingrewards (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards SET TBLPROPERTIES (
    'comment' = 'Records the monthly staking reward distributions to individual wallets, capturing the reward amount, yield percentages, and the staking period month. Source: WalletDB.Staking.StakingRewards on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Staking',
    'source_table' = 'StakingRewards',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key. (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN StakingIncomeId COMMENT 'External income identifier from the reward calculation system. Used as idempotency key by InsertStakingReward (EXISTS check prevents duplicate inserts). Indexed by idx_StakingIncomeId for fast lookups. (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN CryptoId COMMENT 'The cryptocurrency for which the reward was earned. FK to Wallet.CryptoTypes.CryptoID. Currently all records are CryptoId=2 (ETH). Part of the unique constraint (CryptoId, WalletId, StakingMonthId). Resolved from Wallet.CustomerWalletsView by InsertStakingReward if NULL (backward compatibility). (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN WalletId COMMENT 'The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Used with Gcid from Wallet.CustomerWalletsView for per-user reward lookups in GetStakingRewardList. (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN StakingMonthId COMMENT 'The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202106 to 202306 in current data. (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN MonthlyReward COMMENT 'The amount of crypto earned as staking reward for this month, in the asset''s native units (e.g., 0.01172 ETH). Summed by Staking.GetStakingTotals for total rewards per wallet. Must exceed ~$1 USD equivalent to be distributed. (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN MonthlyYieldPercentage COMMENT 'The overall staking pool yield percentage for this month. Recent records show 0, suggesting yield tracking may have been externalized. (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN UserYieldPercentage COMMENT 'The user''s share of the pool yield, based on their eToro club tier. Recent records show 0, suggesting calculation moved upstream. Per Confluence, yield varies by club level. (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN IncomeDate COMMENT 'The date/time when the reward was calculated or distributed. Multiple rewards in the same batch share the same IncomeDate (e.g., all June 2023 rewards have 2023-06-18T07:58:54). (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingrewards ALTER COLUMN Occurred COMMENT 'Timestamp when this reward record was inserted into the database. Slightly after IncomeDate due to processing time. (Tier 1 - upstream wiki, WalletDB.Staking.StakingRewards)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
