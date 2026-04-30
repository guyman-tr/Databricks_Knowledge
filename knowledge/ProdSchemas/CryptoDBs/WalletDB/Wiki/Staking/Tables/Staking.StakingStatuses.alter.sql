-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Staking.StakingStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_staking_stakingstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_staking_stakingstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingstatuses SET TBLPROPERTIES (
    'comment' = 'Event table recording every status transition in a staking operation''s lifecycle, linking each state change to its parent staking record and the corresponding dictionary status. Source: WalletDB.Staking.StakingStatuses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_staking_stakingstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Staking',
    'source_table' = 'StakingStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key. Monotonically increasing, used to establish event ordering when Occurred timestamps collide. (Tier 1 - upstream wiki, WalletDB.Staking.StakingStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingstatuses ALTER COLUMN StakingId COMMENT 'The staking operation this status event belongs to. FK to Staking.Staking.Id. Each staking operation has 2+ status rows (Pending + terminal). Used by StakingData view''s ROW_NUMBER() PARTITION for latest-status extraction. (Tier 1 - upstream wiki, WalletDB.Staking.StakingStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingstatuses ALTER COLUMN StakingStatusId COMMENT 'The status being applied. FK to Dictionary.StakingStatuses.Id: 1=Pending, 2=Failed, 3=Completed. See Staking Status. Filtered by GetStakingTotals (WHERE StakingStatusId=3) for completed-only aggregation. (Tier 1 - upstream wiki, WalletDB.Staking.StakingStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingstatuses ALTER COLUMN DetailsJson COMMENT 'Optional JSON payload for status-specific details (e.g., error messages for Failed status). Currently unused - all 4,419 rows have NULL. Column exists for extensibility. (Tier 1 - upstream wiki, WalletDB.Staking.StakingStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_staking_stakingstatuses ALTER COLUMN Occurred COMMENT 'Timestamp of this status transition. Defaults to UTC now. Used by StakingData view to determine the latest status per staking (ORDER BY Occurred DESC in ROW_NUMBER window). The time difference between Pending and Completed Occurred values indicates blockchain processing duration. (Tier 1 - upstream wiki, WalletDB.Staking.StakingStatuses)';

