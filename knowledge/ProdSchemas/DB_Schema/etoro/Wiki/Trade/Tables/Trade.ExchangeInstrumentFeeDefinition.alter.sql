-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.ExchangeInstrumentFeeDefinition
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ExchangeInstrumentFeeDefinition.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition SET TBLPROPERTIES (
    'comment' = 'Exchange-level fee schedule that defines which fee type (overnight vs. weekend) applies for each day of the week per exchange and optionally per instrument, used by the CFD overnight/weekend fee process. Source: etoro.Trade.ExchangeInstrumentFeeDefinition on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ExchangeInstrumentFeeDefinition.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'ExchangeInstrumentFeeDefinition',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN ExchangeID COMMENT 'FK to Dictionary.ExchangeInfo (implicit). Exchange identifier (e.g., 1=FX, 2=CFD, 4=Nasdaq, 5=NYSE). (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN InstrumentID COMMENT '-999 = exchange-wide default; specific InstrumentID = instrument override. FK to Trade.Instrument (implicit). (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN sunday COMMENT 'Fee type for Sunday: 0=None, 1=Overnight, 2=Weekend. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN monday COMMENT 'Fee type for Monday: 0=None, 1=Overnight, 2=Weekend. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN tuesday COMMENT 'Fee type for Tuesday: 0=None, 1=Overnight, 2=Weekend. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN wednesday COMMENT 'Fee type for Wednesday: 0=None, 1=Overnight, 2=Weekend. Typically 2 (weekend fee day). (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN thursday COMMENT 'Fee type for Thursday: 0=None, 1=Overnight, 2=Weekend. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN friday COMMENT 'Fee type for Friday: 0=None, 1=Overnight, 2=Weekend. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN saturday COMMENT 'Fee type for Saturday: 0=None, 1=Overnight, 2=Weekend. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN DbLoginName COMMENT 'Current SQL login; audit trail. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN SysStartTime COMMENT 'System versioning row start. History.ExchangeInstrumentFeeDefinition. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';
ALTER TABLE main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition ALTER COLUMN SysEndTime COMMENT 'System versioning row end. Current rows have max datetime. (Tier 1 - upstream wiki, etoro.Trade.ExchangeInstrumentFeeDefinition)';

