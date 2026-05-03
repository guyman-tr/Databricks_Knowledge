-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatTransactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatTransactions.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiattransactions
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiattransactions (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions SET TBLPROPERTIES (
    'comment' = 'Central transaction table recording all financial movements (card payments, bank transfers, refunds, fees, crypto conversions) across customer fiat accounts. Source: FiatDwhDB.dbo.FiatTransactions on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatTransactions.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatTransactions',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionGuid COMMENT 'External-facing unique transaction identifier. Has two unique constraints. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN AccountId COMMENT 'FK to dbo.FiatAccount.Id. The account involved. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN CardId COMMENT 'FK to dbo.FiatCards.Id. The card used (NULL for non-card transactions). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN CurrencyBalanceId COMMENT 'FK to dbo.FiatCurrencyBalances.Id. The currency balance affected. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN ExternalBankAccountId COMMENT 'FK to dbo.FiatBankAccount.Id. External bank account for bank transfers (NULL for card/internal). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionTypeId COMMENT 'Transaction type: 0-14. See Transaction Type. (Dictionary.TransactionTypes) (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN MerchantId COMMENT 'FK to dbo.FiatMerchants.Id. Merchant for card payments (NULL for transfers/fees). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN Created COMMENT 'UTC timestamp when this transaction was recorded in DWH. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN Label COMMENT 'Human-readable transaction description/label displayed to the customer. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionLocalTime COMMENT 'Transaction time in the merchant''s local timezone (for card transactions). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN ReferenceNumber COMMENT 'External reference number from the payment network or provider. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionCategory COMMENT 'High-level category: 0-4. See Transaction Category. (Dictionary.TransactionCategories) (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN PaymentSchemeId COMMENT 'Payment scheme used: 0-7. See Payment Schema Type. (Dictionary.PaymentSchemaType) (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN PaymentReference COMMENT 'Payment reference for bank transfers (masked for PII). Used for SEPA/FPS reference matching. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN MoneyCorrelationId COMMENT 'Correlation ID linking this transaction to related operations in the Money Transfer system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN TransactionCountryIso COMMENT 'ISO country code where the transaction originated (for card transactions). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactions ALTER COLUMN SourceCugTransactionId COMMENT 'Source CUG (operational system) transaction ID. Links DWH record back to the operational record for cross-referencing. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
