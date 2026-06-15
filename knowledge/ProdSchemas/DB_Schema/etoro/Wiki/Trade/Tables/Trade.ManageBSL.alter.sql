-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_trade_managebsl  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ManageBSL.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN ID COMMENT 'Surrogate key';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN MessageType COMMENT '0=no action, 1=Warning, 2=Liquidation, 3=Unblock';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN WarningType COMMENT '0=block, 1=Alert1, 2=Alert2';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN CID COMMENT 'Customer ID (FK to Customer.Customer)';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN BonusCredit COMMENT 'Bonus credit at snapshot time';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN RealizedEquity COMMENT 'Realized equity at snapshot time';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN UnRealizedEquity COMMENT 'Unrealized equity at snapshot time';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN BSLRealFunds COMMENT 'Balance stop loss real funds';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN TimeMessageInsertedToQueue COMMENT 'When message was enqueued';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN TimeMessageWasRecieved COMMENT 'When consumer received the message';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN TimeMessageWasAck COMMENT 'When consumer acknowledged';
ALTER TABLE main.general.bronze_etoro_trade_managebsl ALTER COLUMN ExecutionID COMMENT 'BSL execution run ID';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:25:00 UTC
-- Statements: 12/12 succeeded
-- ====================
