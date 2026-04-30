-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.ExecutionFactorConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExecutionFactorConfiguration.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_history_executionfactorconfiguration
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_history_executionfactorconfiguration (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration SET TBLPROPERTIES (
    'comment' = 'Temporal system-versioned history table storing all past versions of per-instrument execution factor configurations - recording every change to the sizing multipliers applied when the hedge execution layer places orders for specific (strategy, instrument) combinations. Source: etoro.History.ExecutionFactorConfiguration on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExecutionFactorConfiguration.md).'
);

ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'ExecutionFactorConfiguration',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration ALTER COLUMN StrategyID COMMENT 'The execution strategy model. Composite PK with InstrumentID in source table. FK to Hedge.ExecutionStrategyModels (ModelID). Known values: 1=LimitOrderBid, 2=LimitOrderMid, 3=LimitOrderAsk, 4=MarketOrder. Determines which order placement strategy this factor applies to. (Tier 1 - upstream wiki, etoro.History.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration ALTER COLUMN InstrumentID COMMENT 'The instrument for which this execution factor applies. Composite PK with StrategyID. Implicit FK to Trade.Instrument. A specific InstrumentID row allows per-instrument sizing control for the given strategy. (Tier 1 - upstream wiki, etoro.History.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration ALTER COLUMN ExecutionFactor COMMENT 'The sizing multiplier applied to hedge order calculations for this (StrategyID, InstrumentID) pair. 1.0 = no adjustment. < 1.0 = smaller orders. > 1.0 = larger orders. 8 decimal places for precision. Overrides the server-level Trade.HedgeServer.ExecutionFactor for this specific combination. (Tier 1 - upstream wiki, etoro.History.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration ALTER COLUMN IsActive COMMENT 'Soft enable/disable flag. 1 = active, returned by Hedge.GetStrategyInstrumentExecutionFactorConfiguration. 0 (default) = inactive, ignored by hedging application. Allows pre-staging or disabling overrides without deleting the row (preserving history). (Tier 1 - upstream wiki, etoro.History.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration ALTER COLUMN DbLoginName COMMENT 'SQL Server login captured via suser_name() computed column on source (AS suser_name()). Identifies who changed the configuration at the database level. NULL if login unavailable. (Tier 1 - upstream wiki, etoro.History.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration ALTER COLUMN AppLoginName COMMENT 'Application user identity captured via context_info() computed column (AS CONVERT(varchar(500), context_info())). Contains email padded with null bytes when set. Must be trimmed with REPLACE/RTRIM to use. NULL when not set (most direct DB changes). (Tier 1 - upstream wiki, etoro.History.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this configuration version became active. Managed by SQL Server temporal system-versioning. Equal to SysEndTime for INSERT-triggered zero-duration rows. (Tier 1 - upstream wiki, etoro.History.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_history_executionfactorconfiguration ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this version was superseded. Clustered index leading column. Equal to SysStartTime for INSERT-triggered zero-duration rows. (Tier 1 - upstream wiki, etoro.History.ExecutionFactorConfiguration)';

