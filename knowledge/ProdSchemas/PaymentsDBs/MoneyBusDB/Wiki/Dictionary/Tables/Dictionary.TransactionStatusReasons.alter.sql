-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons ALTER COLUMN ID COMMENT 'Primary key identifying each transaction status reason. Explicitly assigned (not IDENTITY). Referenced as StatusReasonID in MoneyBus.Transactions and MoneyBus.TransactionsTable_New (UDT). Values: 1=Created, 2=Success, 3=Held, 4=Credited, 5=Debited, 6=HoldDecline, 7=CreditDecline, 8=DebitDecline, 9=ValidateDecline, 10=Technical, 11=DebitInitiated, 12=HoldInitiated, 13=CreditInitiated, 14=HoldCanceled, 15=ReconciliationAborted. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason) for full business definitions.';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons ALTER COLUMN Name COMMENT 'Human-readable label for the status reason. Descriptive names follow a consistent pattern: {Step}{Outcome} (e.g., HoldInitiated, CreditDecline). Consumed by TransactionStatusReasonsGet for application-level caching and display.';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons ALTER COLUMN TransactionStatusID COMMENT 'Parent status that this reason belongs to. Implicit FK to Dictionary.TransactionStatuses.ID. Maps each granular reason to its top-level outcome category: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. Critical for determining recoverability - reasons mapping to InProcess are retryable, others are terminal. See [Transaction Status](../../_glossary.md#transaction-status).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:50 UTC
-- Statements: 3/3 succeeded
-- ====================
