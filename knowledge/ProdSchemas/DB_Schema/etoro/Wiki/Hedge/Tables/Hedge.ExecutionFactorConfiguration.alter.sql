-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.ExecutionFactorConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExecutionFactorConfiguration.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_hedge_executionfactorconfiguration
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_hedge_executionfactorconfiguration (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration SET TBLPROPERTIES (
    'comment' = 'Per-strategy, per-instrument execution scaling configuration that defines a decimal multiplier controlling what fraction of the required hedge exposure is actually executed, enabling partial or amplified hedging by strategy and instrument. Source: etoro.Hedge.ExecutionFactorConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExecutionFactorConfiguration.md).'
);

ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'ExecutionFactorConfiguration',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration ALTER COLUMN StrategyID COMMENT 'The hedge strategy this execution factor applies to. Part of composite PK. No FK constraint - application-managed. One strategy can have different factors for different instruments. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration ALTER COLUMN InstrumentID COMMENT 'The instrument this execution factor applies to. Part of composite PK. No FK constraint - implicit reference to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration ALTER COLUMN ExecutionFactor COMMENT 'Scaling multiplier for hedge execution size. 1.0=full hedge, 0.5=50% partial hedge, 1.2=120% over-hedge buffer. High precision (8 decimal places) supports fractional calibration. Applied only when IsActive=1. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration ALTER COLUMN IsActive COMMENT 'Whether this factor is currently applied. 1=active (returned by GetStrategyInstrumentExecutionFactorConfiguration and applied by engine), 0=inactive (soft-deleted or staged, not applied). DEFAULT 0 - new configs require explicit activation. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionFactorConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionfactorconfiguration ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.ExecutionFactorConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionFactorConfiguration)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
