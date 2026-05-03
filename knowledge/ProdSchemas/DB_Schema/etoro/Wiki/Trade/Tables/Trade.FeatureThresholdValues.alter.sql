-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.FeatureThresholdValues
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.FeatureThresholdValues.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_featurethresholdvalues
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_featurethresholdvalues (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues SET TBLPROPERTIES (
    'comment' = 'Per-instrument, per-feature threshold value store that defines the numeric limits (e.g., milliseconds, pips, percentages) for each threshold level used by the dealing and validation subsystems. Source: etoro.Trade.FeatureThresholdValues on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.FeatureThresholdValues.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'FeatureThresholdValues',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument. Identifies the tradeable instrument. Part of composite PK. Used by InsertInstrumentRealTable and UpdateFeatureThresholdValues. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN FeatureID COMMENT 'FK to Dictionary.Feature. Feature: 1=Price Filter (MS), 2=Execution Delay (MS), 3=Rate Volatility (Pip), 4=Inactivity Timeout (MS), 5=Limit Execution (Pip), 6=Rate Volatility (%), 7=Price Stale timeout (MS). Part of composite PK. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN ThresholdID COMMENT 'FK to Dictionary.FeatureThreshold. Threshold level: 0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum. Part of composite PK. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN Value COMMENT 'Numeric value for this threshold. Units depend on feature: ms for timing features, pips for execution/volatility, percentage for Feature 6. Audited on INSERT/UPDATE/DELETE. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). SQL login audit context. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context audit. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN SysStartTime COMMENT 'System-versioning row start. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN SysEndTime COMMENT 'System-versioning row end. GENERATED ALWAYS AS ROW END. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
ALTER TABLE main.trading.bronze_etoro_trade_featurethresholdvalues ALTER COLUMN HostName COMMENT 'Computed: host_name(). Server name for audit context. (Tier 1 - upstream wiki, etoro.Trade.FeatureThresholdValues)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
