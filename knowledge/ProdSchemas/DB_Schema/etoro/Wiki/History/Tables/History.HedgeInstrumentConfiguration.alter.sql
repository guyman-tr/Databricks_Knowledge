-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.HedgeInstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'SQL Server system-versioned temporal history table for Hedge.InstrumentConfiguration, recording every change to the per-instrument hedge configuration including order size limits, HBC deal size thresholds, circuit breaker parameters, spread settings, and manual trading restrictions. Source: etoro.History.HedgeInstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'HedgeInstrumentConfiguration',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'The financial instrument whose hedge configuration is recorded. PK in source (not IDENTITY). FK to Trade.Instrument. One row per instrument in the current table. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN MinOrderSizeForExecutionInEToroUnits COMMENT 'Minimum order size (in eToro''s internal unit denomination) required for this instrument to be routed to a liquidity provider for hedging. Source DEFAULT=1. High precision (19,5) supports fractional-unit instruments like crypto. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN HBCDealSizeThresholdAlertInEToroUnits COMMENT 'HBC (Hedge Book Control) alert threshold in eToro units. Single hedge orders exceeding this size trigger an operator alert. Source DEFAULT=30,000,000. The HBC system protects liquidity providers from oversized orders. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN HBCMaxDealSizeThresholdRejectInEToroUnits COMMENT 'HBC reject threshold in eToro units. Single hedge orders exceeding this size are automatically rejected by the HBC system. Source DEFAULT=30,000,000. Alert threshold is typically lower than or equal to reject threshold. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN ManualMaxDealSizeInEToroUnits COMMENT 'Optional override for maximum deal size on manually-submitted hedge orders. NULL means the standard HBC thresholds apply. When set, provides a tighter constraint for manual operations than the automated threshold. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN SpreadReturnFactor COMMENT 'Multiplier applied in spread return calculations. Source DEFAULT=1. 1.0 = full market spread applies to the customer; values approaching 0 indicate greater spread subsidization. Affects customer cost of trading. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN CircuitBreakerLimit COMMENT 'The exposure or deviation threshold at which the circuit breaker trips and hedging is suspended for this instrument. NULL for instruments without circuit breaker protection. High precision (14,4) for large exposure values. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN CircuitBreakerWarningLimit COMMENT 'Warning threshold below the full circuit breaker limit. Triggers operator alerts before the circuit breaker trips. NULL when not configured. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'SQL Server login (suser_name()) at time of change. Computed column in source, materialized here. Identifies which service account made the configuration change. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Application context from context_info() at time of change. Computed column in source, materialized here. May identify the operator email or service that triggered the update. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this instrument configuration version became active. For INSERT-trigger-captured rows, equals SysEndTime. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this version was superseded. CLUSTERED index leading column. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN RestrictManualActions COMMENT 'Flag controlling whether manual hedging operations are permitted for this instrument. Source DEFAULT=0 (unrestricted). Non-zero values block manual open/close actions via management tools. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration ALTER COLUMN LotSizeForView COMMENT 'Display denominator for converting eToro internal units to conventional lot sizes for reporting and UI display. Source DEFAULT=1. Example: setting to 100,000 displays FX positions in standard lots. Does not affect execution. (Tier 1 - upstream wiki, etoro.History.HedgeInstrumentConfiguration)';

