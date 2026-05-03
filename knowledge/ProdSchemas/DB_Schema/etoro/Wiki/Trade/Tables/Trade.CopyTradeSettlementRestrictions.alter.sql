-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.CopyTradeSettlementRestrictions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CopyTradeSettlementRestrictions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions SET TBLPROPERTIES (
    'comment' = 'Configures which countries, regulations, instrument types, exchanges, and instruments are restricted or permitted for copy-trading settlement, supporting jurisdictional and product-level compliance rules. Source: etoro.Trade.CopyTradeSettlementRestrictions on the etoro production database, ingested via the Generic Pipeline (Snapshot strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CopyTradeSettlementRestrictions.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'CopyTradeSettlementRestrictions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Snapshot',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN CountryID COMMENT 'Country for which this restriction applies. References Dictionary.Country. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN RegulationID COMMENT 'Regulation scope; NULL = all regulations for that country. References Dictionary.Regulation. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type (e.g., Crypto=5). References Dictionary.CurrencyType. Part of CK: at least one of InstrumentTypeID/ExchangeID/InstrumentID/GroupID required. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN ExchangeID COMMENT 'Exchange scope; NULL = not exchange-specific. References Dictionary.ExchangeInfo. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN InstrumentID COMMENT 'Specific instrument; NULL = not instrument-specific. References Trade.InstrumentMetaData. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN RestrictionTypeID COMMENT 'Type of restriction (block/allow). References Dictionary.RestrictionType. Validated on INSERT. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN ID COMMENT 'Surrogate primary key. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN DbLoginName COMMENT 'Computed: current SQL login. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN AppLoginName COMMENT 'Computed: application login from CONTEXT_INFO. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN SysStartTime COMMENT 'System-versioning row start. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN SysEndTime COMMENT 'System-versioning row end. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN UnblockReasonId COMMENT 'If set, restriction can be overridden by this reason. References Dictionary.BlockUnBlockReason. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN GroupID COMMENT 'Instrument group scope. References Dictionary.TradingInstrumentGroups. Part of CK. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN RegistrationDate COMMENT 'Optional registration date for time-bounded rules. Part of UQ. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
ALTER TABLE main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions ALTER COLUMN AccountTypeID COMMENT 'Account type scope. Part of UQ. (Tier 1 - upstream wiki, etoro.Trade.CopyTradeSettlementRestrictions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
