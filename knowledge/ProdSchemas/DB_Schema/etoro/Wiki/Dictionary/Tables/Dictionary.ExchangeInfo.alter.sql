-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_exchangeinfo
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ExchangeInfo.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_exchangeinfo SET TBLPROPERTIES (
    'comment' = 'A lookup table cataloging all stock exchanges and market venues where instruments traded on the eToro platform are listed. Each tradable instrument (stock, ETF, crypto, index) belongs to a specific exchange. This table provides the canonical exchange registry used for instrument classification, market hours determination, settlement rules, and regulatory reporting. Referenced by `Trade.InstrumentMetaData.ExchangeID` which links each instrument to its exchange. Used extensively by trading procedures including `Trade.InsertInstrumentTradingData`, `Trade.InsertInstrumentRealTable`, `Trade.GetAllInstrumentData`, `Trade.GetOrdersForExecutionReportDrillDown`, and instrument configuration procedures. The `Price.ExchangeIDList` user-defined type accepts lists of ExchangeIDs for batch operations.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_exchangeinfo ALTER COLUMN ExchangeID COMMENT 'Primary key. Exchange identifier. Production values 1-56; test values 99+.';
ALTER TABLE main.general.bronze_etoro_dictionary_exchangeinfo ALTER COLUMN ExchangeDescription COMMENT 'Exchange name or abbreviation.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:10 UTC
-- Statements: 3/3 succeeded
-- ====================
