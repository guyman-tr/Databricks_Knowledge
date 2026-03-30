-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN Date COMMENT 'Trading date';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN Minute_Start COMMENT 'Start of 1-minute interval';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN Minute_End COMMENT 'End of 1-minute interval';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN InstrumentID COMMENT 'Commodity instrument ID';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN LiquidityAccountName COMMENT 'LP account name';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN LiquidityAccountID COMMENT 'LP account identifier';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN VolumeBuy COMMENT 'Count of LP hedge buy executions in this minute';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN VolumeSell COMMENT 'Count of LP hedge sell executions in this minute';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN Units_NOP COMMENT 'LP net open position in instrument units';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN NOP COMMENT 'LP net open position in USD';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN ValueStart COMMENT 'Mark-to-market USD value of LP NOP at minute start';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN ValueEnd COMMENT 'Mark-to-market USD value of LP NOP at minute end';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN ValueRealized COMMENT 'Realized USD value from LP positions closed in this minute';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN UpdateDate COMMENT 'ETL metadata: row write timestamp';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN Minute_Start SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN Minute_End SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN LiquidityAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN VolumeBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN VolumeSell SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN Units_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN ValueStart SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN ValueEnd SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN ValueRealized SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 13:58:52 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 30/30 succeeded
-- ====================
