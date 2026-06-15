-- =============================================================================
-- Databricks ALTER Script: main.trading.bronze_etoro_trade_futuresmetadata  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.FuturesMetaData.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN InstrumentID COMMENT 'Primary key. FK to Trade.Instrument. One row per futures instrument.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN Multiplier COMMENT 'Contract size per point. Used for notional and fee calculation.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN MinimalTick COMMENT 'Smallest price increment in contract units.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN LastTradingDateTime COMMENT 'When trading stops for this contract.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN ExpirationDateTime COMMENT 'Contract maturity. 2222-01-01 for perpetuals.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN SettlementTime COMMENT 'Time of day for settlement.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN IndexPointValue COMMENT 'Dollar/value per point move. Used in exposure and fee calc.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN DbLoginName COMMENT 'Computed; database login at insert.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN AppLoginName COMMENT 'Computed; application context at insert.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN SysStartTime COMMENT 'Row start for system versioning.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN SysEndTime COMMENT 'Row end for system versioning.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN SettlementMethod COMMENT 'Settlement type; 0 or NULL.';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN UnitOfMeasure COMMENT 'Unit of measure; 0, 1, or NULL.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:26:10 UTC
-- Statements: 13/13 succeeded
-- ====================
