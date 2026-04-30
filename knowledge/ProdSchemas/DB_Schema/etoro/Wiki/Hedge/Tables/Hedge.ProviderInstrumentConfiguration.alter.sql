-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.ProviderInstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderInstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_hedge_providerinstrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_hedge_providerinstrumentconfiguration (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'Per-provider, per-instrument order submission configuration defining how hedge orders are sent to each liquidity provider for specific instruments - specifying order type (market vs limit vs GTD), limit price offset percentage, and GTD order validity window. Currently empty (designed but not yet operationally activated). Source: etoro.Hedge.ProviderInstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderInstrumentConfiguration.md).'
);

ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'ProviderInstrumentConfiguration',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN LiquidityProviderTypeID COMMENT 'The liquidity provider type this configuration applies to. Part of composite PK. Implicit reference to Trade.LiquidityProviderType (no FK constraint). Indexed via idx_LiquidityProviderTypeID for per-provider lookups. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'The instrument this configuration applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). Indexed via idx_InstrumentID for per-instrument lookups. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN OrderType COMMENT 'Numeric enum specifying the order submission type for this provider/instrument pair (e.g., market, limit, GTD). Governs whether LimitOffsetPercentage and GTDTimeSpanInSeconds are used. No FK to dictionary table; enum values defined in application code. No DEFAULT - must be explicitly set. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN LimitOffsetPercentage COMMENT 'Percentage offset from market price used to compute the limit price when OrderType is a limit order. E.g., 0.05 = 5 basis point offset. No DEFAULT - required on insert. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN GTDTimeSpanInSeconds COMMENT 'Validity window in seconds for GTD (Good Till Date) orders. After expiry, unfilled orders are cancelled. Used when OrderType is GTD. No DEFAULT - required on insert. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_providerinstrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.ProviderInstrumentConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.ProviderInstrumentConfiguration)';

