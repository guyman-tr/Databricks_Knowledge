-- =============================================================================
-- Databricks ALTER Script: main.emoney.bronze_fiatdwhdb_dbo_fiattransactions
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatTransactions.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions SET TBLPROPERTIES (
    'comment' = 'Central transaction table recording all financial movements (card payments, bank transfers, refunds, fees, crypto conversions) across customer fiat accounts.'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionGuid COMMENT 'External-facing unique transaction identifier. Has two unique constraints.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN AccountId COMMENT 'FK to dbo.FiatAccount.Id. The account involved.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN CardId COMMENT 'FK to dbo.FiatCards.Id. The card used (NULL for non-card transactions).';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN CurrencyBalanceId COMMENT 'FK to dbo.FiatCurrencyBalances.Id. The currency balance affected.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN ExternalBankAccountId COMMENT 'FK to dbo.FiatBankAccount.Id. External bank account for bank transfers (NULL for card/internal).';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionTypeId COMMENT 'Transaction type: 0-14. See [Transaction Type](../../_glossary.md#transaction-type). (Dictionary.TransactionTypes)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN MerchantId COMMENT 'FK to dbo.FiatMerchants.Id. Merchant for card payments (NULL for transfers/fees).';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN Created COMMENT 'UTC timestamp when this transaction was recorded in DWH.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN Label COMMENT 'Human-readable transaction description/label displayed to the customer.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionLocalTime COMMENT 'Transaction time in the merchant''s local timezone (for card transactions).';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN ReferenceNumber COMMENT 'External reference number from the payment network or provider.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionCategory COMMENT 'High-level category: 0-4. See [Transaction Category](../../_glossary.md#transaction-category). (Dictionary.TransactionCategories)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN PaymentSchemeId COMMENT 'Payment scheme used: 0-7. See [Payment Schema Type](../../_glossary.md#payment-schema-type). (Dictionary.PaymentSchemaType)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN PaymentReference COMMENT 'Payment reference for bank transfers (masked for PII). Used for SEPA/FPS reference matching.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN MoneyCorrelationId COMMENT 'Correlation ID linking this transaction to related operations in the Money Transfer system.';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionCountryIso COMMENT 'ISO country code where the transaction originated (for card transactions).';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN SourceCugTransactionId COMMENT 'Source CUG (operational system) transaction ID. Links DWH record back to the operational record for cross-referencing.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:36 UTC
-- Statements: 19/19 succeeded
-- ====================
