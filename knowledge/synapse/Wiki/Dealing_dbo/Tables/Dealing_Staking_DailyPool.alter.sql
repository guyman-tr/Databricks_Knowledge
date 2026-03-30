-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Staking_DailyPool
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool SET TBLPROPERTIES (
    'comment' = 'This table is the **daily building block of the staking reward calculation**. SP_Staking (the monthly distribution SP) uses `Avg_DailyTotalStakingPool` from this table to determine how much of the network''s staking rewards belong to eToro vs clients: the bigger eToro''s pool, the more rewards eToro earned and thus can distribute. **DailyTotalStakingPool**: The total crypto units held across all eligible clients who are opted into staking for this instrument on this date. Excludes: - Clients in intro period (IntroDays waiting period) - Clients who opted out - Clients in non-eligible regulations/countries - Clients flagged as is_us=1 (handled by SP_Staking_DailyPool_US) **Avg_DailyTotalStakingPool**: The simple average of DailyTotalStakingPool across ALL dates stored in the table for this instrument. This is a rolling average - it changes each day as a new row is added. SP_Staking reads this column to compute the client-pool-to-network ratio for reward distribution. The table also drives `Dealing_Staking_Opte...'
);

ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED INDEX on Date',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN Date COMMENT 'The calendar date for this pool snapshot. One row per (date, instrument). CLUSTERED INDEX key. (Tier 3 - SP_Staking_DailyPool @Date parameter)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier for the staked cryptocurrency. FK to DWH_dbo.Dim_Instrument. Includes both base and EUR pairs (e.g., SOL=100063, SOLEUR=100456). (Tier 3 - BI_DB_dbo.BI_DB_PositionPnL)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN Currency COMMENT 'Ticker symbol of the staked crypto (e.g., "ADA", "ADAEUR", "ETH", "SOL"). EUR pairs represent the EUR-denominated equivalent instruments. (Tier 3 - Dealing_staging.Fivetran_google_sheets_platform_rewards)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN DailyTotalStakingPool COMMENT 'Total crypto units held by all opted-in eligible clients for this instrument on this date. Sum of `AmountInUnitsDecimal` from BI_DB_dbo.BI_DB_PositionPnL, filtered to the eligible, opted-in staking population. Units in native crypto denomination (e.g., TRX pool shows ~393M TRX). (Tier 3 - BI_DB_dbo.BI_DB_PositionPnL)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN Avg_DailyTotalStakingPool COMMENT 'Simple average of DailyTotalStakingPool across ALL dates in the table for this instrument. Recomputed each day. Used by SP_Staking as the primary measure of eToro''s average staked pool during the distribution period. (Tier 3 - computed from DailyTotalStakingPool history)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was written by SP_Staking_DailyPool. Set to GETDATE(). (Tier 4 - ETL metadata)';

-- ---- Column PII Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN DailyTotalStakingPool SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN Avg_DailyTotalStakingPool SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
