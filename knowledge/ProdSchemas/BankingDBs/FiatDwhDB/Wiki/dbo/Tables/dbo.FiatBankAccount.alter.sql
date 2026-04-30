-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatBankAccount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatBankAccount.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount SET TBLPROPERTIES (
    'comment' = 'Stores bank account details (IBAN, sort code, BIC) linked to customer fiat accounts, representing both internal platform bank accounts and external third-party bank accounts used for payments and transfers. Source: FiatDwhDB.dbo.FiatBankAccount on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatBankAccount.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatBankAccount',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN IsExternal COMMENT 'Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN BankAccountGuid COMMENT 'Unique external-facing identifier for this bank account. Used by application APIs and provider integrations. Has a unique constraint. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN FullName COMMENT 'Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN Nickname COMMENT 'Optional user-assigned friendly name for the bank account (e.g., "My savings"). Used for display in the customer''s account list. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN BankAccountNumber COMMENT 'Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN SortCode COMMENT 'UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN Created COMMENT 'UTC timestamp when this bank account record was created in the data warehouse. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN Iban COMMENT 'International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN Bic COMMENT 'Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN EventTimestamp COMMENT 'Timestamp of the original event in the source system that created or modified this bank account. May differ from Created (DWH insertion time). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN CurrencyBalanceId COMMENT 'FK to dbo.FiatCurrencyBalances.Id. Links internal bank accounts to their associated currency balance. NULL for external payee accounts. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN BsbCode COMMENT 'Australian Bank-State-Branch code (6 digits). Used together with BankAccountNumber for Australian NPP and direct entry payments. NULL for non-Australian accounts. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount ALTER COLUMN Ncc COMMENT 'National Clearing Code. Used for bank identification in regions that don''t use IBAN or sort code systems. NULL when other identifiers are sufficient. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatBankAccount)';

