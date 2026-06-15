-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_moneybusdb_dictionary_withdrawstatuses  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatuses.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatuses ALTER COLUMN ID COMMENT 'Primary key identifying each withdrawal status. Explicitly assigned (not IDENTITY). Referenced as StatusID in MoneyBus.Withdrawals and as WithdrawStatusID in Dictionary.WithdrawStatusReasons. Values: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. See [Withdraw Status](../../_glossary.md#withdraw-status) for full business definitions.';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatuses ALTER COLUMN Name COMMENT 'Human-readable status label used for display in withdrawal reports and operational dashboards.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:53 UTC
-- Statements: 2/2 succeeded
-- ====================
