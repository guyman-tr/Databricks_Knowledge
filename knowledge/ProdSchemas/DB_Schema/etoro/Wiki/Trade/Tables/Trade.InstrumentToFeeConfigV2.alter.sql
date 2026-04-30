-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.InstrumentToFeeConfigV2
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentToFeeConfigV2.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_instrumenttofeeconfigv2
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 SET TBLPROPERTIES (
    'comment' = 'Version 2 of instrument-to-fee mapping with SettlementTypeID and FeeCalculationTypeID; system-versioned. Primary source for overnight and weekend fee rates. Source: etoro.Trade.InstrumentToFeeConfigV2 on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentToFeeConfigV2.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'InstrumentToFeeConfigV2',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN InstrumentID COMMENT 'PK; FK to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN SettlementTypeID COMMENT '0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN FeeCalculationTypeID COMMENT '0=ExposureFormula, 1=LoanFormula. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedSellEndOfWeekFee COMMENT 'Weekend fee for non-leveraged sell. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedBuyEndOfWeekFee COMMENT 'Weekend fee for non-leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedBuyOverNightFee COMMENT 'Overnight fee for non-leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedSellOverNightFee COMMENT 'Overnight fee for non-leveraged sell. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN LeveragedSellEndOfWeekFee COMMENT 'Weekend fee for leveraged sell. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN LeveragedBuyEndOfWeekFee COMMENT 'Weekend fee for leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN LeveragedBuyOverNightFee COMMENT 'Overnight fee for leveraged buy. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN LeveragedSellOverNightFee COMMENT 'Overnight fee for leveraged sell. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN Occurred COMMENT 'When config was last changed. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN UpdatedByUser COMMENT 'User/system that updated. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN BeginTime COMMENT 'Temporal row start. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN EndTime COMMENT 'Temporal row end. (Tier 1 - upstream wiki, etoro.Trade.InstrumentToFeeConfigV2)';

