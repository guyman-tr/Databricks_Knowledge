-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.InstrumentToFeeConfig
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentToFeeConfig.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_instrumenttofeeconfig
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_instrumenttofeeconfig (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig SET TBLPROPERTIES (
    'comment' = 'Temporal table that maps each instrument to percentage-based overnight and weekend fee rates (legacy; superseded by Trade.InstrumentToFeeConfigV2 with settlement-type awareness). Source: etoro.Trade.InstrumentToFeeConfig on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentToFeeConfig.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'InstrumentToFeeConfig',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN InstrumentID COMMENT 'PK; FK to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN NonLeveragedSellEndOfWeekFee COMMENT 'Weekend fee % for non-leveraged sell. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN NonLeveragedBuyEndOfWeekFee COMMENT 'Weekend fee % for non-leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN NonLeveragedBuyOverNightFee COMMENT 'Overnight fee % for non-leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN NonLeveragedSellOverNightFee COMMENT 'Overnight fee % for non-leveraged sell. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN LeveragedSellEndOfWeekFee COMMENT 'Weekend fee % for leveraged sell. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN LeveragedBuyEndOfWeekFee COMMENT 'Weekend fee % for leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN LeveragedBuyOverNightFee COMMENT 'Overnight fee % for leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN LeveragedSellOverNightFee COMMENT 'Overnight fee % for leveraged sell. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN Occurred COMMENT 'When config was last changed. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN UpdatedByUser COMMENT 'User/system that updated. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN BeginTime COMMENT 'Temporal row start. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN EndTime COMMENT 'Temporal row end. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfig ALTER COLUMN NonLeveragedBuyCFDOverNightFee COMMENT 'CFD-specific overnight rate for non-leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfig)';

