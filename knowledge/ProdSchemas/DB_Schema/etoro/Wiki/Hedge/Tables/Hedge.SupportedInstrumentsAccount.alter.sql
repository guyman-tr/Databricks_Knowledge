-- =============================================================================
-- Databricks ALTER Script: main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.SupportedInstrumentsAccount.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN LiquidityAccountID COMMENT 'The liquidity account this allowlist entry applies to. Part of composite PK. Implicit reference to Trade.LiquidityAccounts (no FK constraint). 6 distinct account IDs configured: 8 (ZBFX P1), 11 (ZBFX P3), 345 (Talos Hidden), 439 (DLT), 2147 (OMS IM Pricing), 2148 (OMS IM Hedging).';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN InstrumentID COMMENT 'The instrument this account is permitted to execute. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). 5,239 distinct instruments configured.';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML.';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set.';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active.';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.SupportedInstrumentsAccount.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:29:06 UTC
-- Statements: 6/6 succeeded
-- ====================
