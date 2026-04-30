-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.ProviderInstrumentToLeverage
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage SET TBLPROPERTIES (
    'comment' = 'Maps available leverage tiers per provider-instrument pair: defines which leverage values (1x, 2x, 5x, 10x, etc.) a user can select when opening a position for a given instrument through a given execution provider. Source: etoro.Trade.ProviderInstrumentToLeverage on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'ProviderInstrumentToLeverage',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN ProviderID COMMENT 'FK to Trade.Provider. Part of PK. Identifies execution provider (e.g., 1=Tradonomi). (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument (via ProviderToInstrument). Part of PK. Identifies tradeable instrument. (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN LeverageID COMMENT 'FK to Dictionary.Leverage. Part of PK. Leverage tier (1=1x, 2=5x, 3=10x, 5=50x, 6=100x, 7=200x, 8=400x, 9=2x, 10=30x, 11=20x). (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN IsDefault COMMENT '1=default leverage for this provider-instrument (offered when user does not specify), 0=available but not default. ProviderInstrumentLeverageAdd/Edit set IsDefault=0 for others when adding with 1. (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN Percentage COMMENT 'Display or allocation weight. Sample shows 0. (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN LeverageType COMMENT 'Leverage category. Default 1 (retail). Part of PK. May distinguish professional/restricted tiers. (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). Current DB login for audit. (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context. (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN SysStartTime COMMENT 'System-versioning row start. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage ALTER COLUMN SysEndTime COMMENT 'System-versioning row end. GENERATED ALWAYS AS ROW END. History in History.TradeProviderInstrumentToLeverage. (Tier 1 - upstream wiki, etoro.Trade.ProviderInstrumentToLeverage)';

