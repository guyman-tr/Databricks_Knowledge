-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_moneybusdb_dictionary_accounttypes  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_moneybusdb_dictionary_accounttypes ALTER COLUMN ID COMMENT 'Primary key and unique identifier for each account type. Referenced as CreditorTypeID, DebitorTypeID (MoneyBus.Transactions), AccountTypeID (MoneyBus.Withdrawals), DebitAccountTypeID/CreditAccountTypeID (MoneyBus.TransferLimits), and InitiatorAccountTypeId (MoneyBus.TransactionsGroup). Values: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type) for full business definitions.';
ALTER TABLE main.bi_db.bronze_moneybusdb_dictionary_accounttypes ALTER COLUMN Name COMMENT 'Human-readable label for the account type. Used in alert reporting (ALERT_ConsecutiveTransactionFailuresAlert JOINs this column to display creditor/debitor type names). Unique business names that map to platform product verticals.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:46 UTC
-- Statements: 2/2 succeeded
-- ====================
