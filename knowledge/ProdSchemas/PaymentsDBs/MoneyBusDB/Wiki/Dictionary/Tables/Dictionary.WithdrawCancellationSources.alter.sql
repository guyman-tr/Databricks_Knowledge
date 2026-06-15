-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawCancellationSources.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources ALTER COLUMN ID COMMENT 'Primary key identifying each cancellation source. Explicitly assigned (not IDENTITY). Referenced as CancellationSource in MoneyBus.WithdrawCancelRequest. Values: 0=None, 1=User, 2=BackOffice, 3=Abort. See [Withdraw Cancellation Source](../../_glossary.md#withdraw-cancellation-source) for full business definitions.';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources ALTER COLUMN Name COMMENT 'Human-readable label for the cancellation source. Has a UNIQUE constraint ensuring no duplicates. Used for display in cancellation reports and audit logs.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:51 UTC
-- Statements: 2/2 succeeded
-- ====================
