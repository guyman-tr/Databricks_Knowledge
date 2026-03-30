-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Staking_Parameters
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters SET TBLPROPERTIES (
    'comment' = 'This reference table configures the staking program for each supported cryptocurrency. It defines operational parameters: - **IntroDays**: Days a customer must hold before staking yields begin (7 for most, 9 for ADA, 60 for ETH) - **LiquidityBuffer**: Fraction of staked assets reserved for liquidity (0.60-1.00) - **Start dates**: When each phase (daily pool calculation, welcome email, reward distribution) begins for each crypto Contains 13 instruments including USD and EUR pairs (ETH, ETHEUR, ADA, ADAEUR, TRX, SOL, SOLEUR, POL, DOT, NEAR, ATOM, AVAX, SUI). Referenced by all Staking SPs (`SP_Staking`, `SP_Staking_US`, `SP_Staking_DailyPool`, `SP_Staking_DailyPool_US`, `SP_Staking_Emails`, `SP_Staking_WelcomeEmail`). Synapse: ROUND_ROBIN, CLUSTERED INDEX on InstrumentID.'
);

ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED INDEX on InstrumentID',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN InstrumentID COMMENT 'Crypto instrument identifier (100xxx range). E.g., 100001=ETH, 100017=ADA, 100026=TRX, 100063=SOL. (Tier 3 - live data)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN Currency COMMENT 'Crypto symbol. E.g., ETH, ADA, TRX, SOL, DOT, NEAR, ATOM, AVAX, SUI, POL, ETHEUR, SOLEUR, ADAEUR. (Tier 3 - live data)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN IntroDays COMMENT 'Days before staking yields begin for new positions. 7 (standard), 9 (ADA), 60 (ETH). (Tier 3 - live data)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN LiquidityBuffer COMMENT 'Fraction of staked pool reserved for liquidity. 0.60-1.00. Higher = more reserved, lower yield for stakers. (Tier 3 - live data)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN DailyPool_StartDate COMMENT 'Date when daily pool calculation begins for this crypto. (Tier 3 - live data)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN WelcomeEmail_StartDate COMMENT 'Date when welcome staking emails start being sent for this crypto. (Tier 3 - live data)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN Distribution_StartDate COMMENT 'Date when reward distribution begins. Always >= DailyPool_StartDate (pool must accumulate before distribution). (Tier 3 - live data)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN UpdateDate COMMENT 'Last configuration update timestamp. (Tier 3 - live data)';

-- ---- Column PII Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN IntroDays SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN LiquidityBuffer SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN DailyPool_StartDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN WelcomeEmail_StartDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN Distribution_StartDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 14:07:04 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 18/18 succeeded
-- ====================
