-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.InstrumentCusip
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.InstrumentCusip.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_trade_instrumentcusip
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_trade_instrumentcusip (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_trade_instrumentcusip SET TBLPROPERTIES (
    'comment' = 'Thin projection of Trade.InstrumentMetaData exposing InstrumentID, CUSIP (aliased from Cusip), and ISINCode for compliance and lookup. Source: etoro.Trade.InstrumentCusip on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.InstrumentCusip.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_trade_instrumentcusip SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'InstrumentCusip',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_trade_instrumentcusip ALTER COLUMN InstrumentID COMMENT 'PK of Trade.Instrument. Same as InstrumentMetaData.InstrumentID. Identifies the tradeable instrument. (Tier 1 - upstream wiki, etoro.Trade.InstrumentCusip)';
ALTER TABLE main.bi_db.bronze_etoro_trade_instrumentcusip ALTER COLUMN CUSIP COMMENT 'Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments. (Tier 1 - upstream wiki, etoro.Trade.InstrumentCusip)';
ALTER TABLE main.bi_db.bronze_etoro_trade_instrumentcusip ALTER COLUMN ISINCode COMMENT 'International Securities Identification Number. From InstrumentMetaData.ISINCode. Required for stocks in many jurisdictions. NULL for forex, crypto. (Tier 1 - upstream wiki, etoro.Trade.InstrumentCusip)';

