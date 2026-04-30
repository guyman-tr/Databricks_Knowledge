-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.PaymentSpecificationDues
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecificationDues.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues SET TBLPROPERTIES (
    'comment' = 'Tracks individual payment collection events (dues) under a payment specification, each representing a scheduled direct debit collection. Source: FiatDwhDB.dbo.PaymentSpecificationDues on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecificationDues.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'PaymentSpecificationDues',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. Referenced by PaymentSpecificationDueStatuses.DueId. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDues)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues ALTER COLUMN PaymentSpecificationDueGuid COMMENT 'External-facing unique identifier for this payment due. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDues)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues ALTER COLUMN PaymentSpecificationId COMMENT 'FK to dbo.PaymentSpecifications.Id. The parent specification this due belongs to. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDues)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues ALTER COLUMN DueTime COMMENT 'When this payment is scheduled to be collected. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDues)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues ALTER COLUMN EventTimestamp COMMENT 'When the due event occurred in the source system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDues)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues ALTER COLUMN Created COMMENT 'When this record was written to the DWH. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDues)';

