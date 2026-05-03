-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.ProviderInstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_history_providerinstrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_history_providerinstrumentconfiguration (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'Temporal history backing table for Hedge.ProviderInstrumentConfiguration - storing all past versions of the per-instrument order routing configuration for each liquidity provider, including order type, limit offset, and GTD time span. Source: etoro.History.ProviderInstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentConfiguration.md).'
);

ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'ProviderInstrumentConfiguration',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN LiquidityProviderTypeID COMMENT 'The liquidity provider type for which this order configuration applies. Part of the composite PK in the live Hedge.ProviderInstrumentConfiguration table. Implicit FK to Trade.LiquidityProviderType. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'The financial instrument for which this order configuration applies. Part of the composite PK. Implicit FK to instrument lookup. Together with LiquidityProviderTypeID, provides one configuration row per provider/instrument pair. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN OrderType COMMENT 'Specifies the order type to use when sending hedge orders for this instrument to this provider. Tinyint enum - values defined by the hedge engine (e.g., market order, limit order, GTD order). (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN LimitOffsetPercentage COMMENT 'Percentage offset from the reference price when placing limit orders for this instrument at this provider. Applied as: limit_price = reference_price * (1 +/- LimitOffsetPercentage / 100). Precision to 2 decimal places (e.g., 0.50 = 0.5% offset). (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN GTDTimeSpanInSeconds COMMENT 'Duration in seconds for Good Till Date orders. When an order is placed with GTD order type, the provider will cancel it if unfilled after this many seconds. Controls order lifecycle for non-immediate execution modes. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'SQL login captured via suser_name() at write time on the live table. Identifies who changed the order routing configuration. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Application identity from context_info() at write time. May contain null-byte padding from varchar(500) context_info() storage. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this order configuration became active. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_providerinstrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this configuration was superseded. Set by SQL Server temporal engine. Ending boundary (exclusive). Clustered index leading column. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentConfiguration)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
