-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.InstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_instrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_instrumentconfiguration (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table storing prior row versions of Price.InstrumentConfiguration, capturing every change to per-instrument spread alert, spread lock, skew limit, and max spread threshold settings. Source: etoro.History.InstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentConfiguration.md).'
);

ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'InstrumentConfiguration',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'The instrument whose price configuration is captured in this version. PK in source table (one config row per instrument). Implicit FK to Trade.Instrument (source has explicit FK FK_PriceInstrumentConfiguration_InstrumentID). (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN SpreadAlertThresholdPercentage COMMENT 'Spread alert trigger threshold as a percentage of mid-price. When the pricing engine receives a spread wider than this % threshold, an alert is generated. Example: 2.5 means alert fires when spread >= 2.5% of mid. (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN SpreadLockThresholdPercentage COMMENT 'Spread lock trigger threshold as a percentage of mid-price. When spread exceeds this level, the instrument''s pricing may be locked or suspended to protect customers from extreme spreads. NULL = no lock threshold configured. Example: 3.5 = lock at 3.5%. (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN SkewLimitThreshold COMMENT 'Maximum allowed deviation in the price skew calculation. When the skew model produces a skew exceeding this threshold, the engine may override or alert. DEFAULT 0 = no skew limit enforced (threshold disabled). (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN EtoroMaxSpreadPercentage COMMENT 'eToro''s own maximum spread cap published to customers, independent of what liquidity providers send. If the incoming spread exceeds this, eToro clips it to this cap. DEFAULT 0 = no cap enforced (0 means disabled, not 0%). (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'Materialized snapshot of suser_name() at the time this configuration version was superseded. Identifies who changed the configuration. Observed: "TRAD\bonniegr" (manual admin operation). (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Materialized snapshot of context_info() at version close time. Typically NULL - configuration changes are typically made via direct SQL or an admin tool that does not set context_info. (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'Start of validity for this configuration version. Set by SQL Server temporal engine. Rows where SysStartTime = SysEndTime are insert artifacts from TRG_T_InstrumentConfiguration (see Section 2.1). (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';
ALTER TABLE main.general.bronze_etoro_history_instrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'End of validity for this configuration version. Set by SQL Server temporal engine to the timestamp when the live configuration row was updated or deleted. CLUSTERED INDEX ordered (SysEndTime, SysStartTime) for temporal scan performance. (Tier 1 - upstream wiki, etoro.History.InstrumentConfiguration)';

