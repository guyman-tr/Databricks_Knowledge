-- =============================================================================
-- Databricks ALTER Script: main.trading.bronze_etoro_trade_providertoinstrument_daily  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.ProviderToInstrument_Daily.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument_daily ALTER COLUMN ProviderID COMMENT 'Part of PK. Provider identifier.';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument_daily ALTER COLUMN InstrumentID COMMENT 'Part of PK. FK to Trade.Instrument.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:18:49 UTC
-- Statements: 2/2 succeeded
-- ====================
