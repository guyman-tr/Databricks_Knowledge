-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_moneybusdb_dictionary_transactionstatuses  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatuses.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatuses ALTER COLUMN ID COMMENT 'Primary key identifying each transaction status. Explicitly assigned (not IDENTITY). Referenced as StatusID in MoneyBus.Transactions and as TransactionStatusID in Dictionary.TransactionStatusReasons. Values: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. See [Transaction Status](../../_glossary.md#transaction-status) for full business definitions.';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatuses ALTER COLUMN Name COMMENT 'Human-readable status label. JOINed by ALERT_ConsecutiveTransactionFailuresAlert to display status names in alert output. Used for reporting and debugging visibility.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:49 UTC
-- Statements: 2/2 succeeded
-- ====================
