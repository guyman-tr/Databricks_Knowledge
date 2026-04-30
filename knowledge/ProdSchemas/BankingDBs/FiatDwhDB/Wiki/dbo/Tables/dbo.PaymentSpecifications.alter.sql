-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.PaymentSpecifications
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecifications.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications SET TBLPROPERTIES (
    'comment' = 'Stores payment specifications (direct debit mandates) linked to currency balances, tracking the setup and lifecycle of automated payment instructions. Source: FiatDwhDB.dbo.PaymentSpecifications on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecifications.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'PaymentSpecifications',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN CurrencyBalanceId COMMENT 'FK to dbo.FiatCurrencyBalances.Id. The balance this specification draws from. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN PaymentSpecificationGuid COMMENT 'External-facing unique identifier for this specification. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN PaymentSpecificationTypeId COMMENT 'Type: 0=Unknown, 1=DirectDebit. See Payment Specification Type. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN ExternalId COMMENT 'Provider''s external ID for this specification. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN Reference COMMENT 'Payment reference string identifying this mandate. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN ExternalOriginatorId COMMENT 'ID of the external party that initiated the specification (e.g., the direct debit originator). (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN EventTimestamp COMMENT 'When the specification event occurred in the source system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN Created COMMENT 'When this record was created in the DWH. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN CreationStatus COMMENT 'Result of the initial specification setup (e.g., "Success", "Failed"). (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications ALTER COLUMN ErrorReason COMMENT 'Error description if specification setup failed. NULL on success. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecifications)';

