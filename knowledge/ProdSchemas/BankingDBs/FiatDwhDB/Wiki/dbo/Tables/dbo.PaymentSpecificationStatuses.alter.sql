-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.PaymentSpecificationStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecificationStatuses.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status table tracking the lifecycle of payment specifications (New, Active, Cancelled, CancelledPending, Error). Source: FiatDwhDB.dbo.PaymentSpecificationStatuses on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecificationStatuses.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'PaymentSpecificationStatuses',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses ALTER COLUMN PaymentSpecificationId COMMENT 'FK to dbo.PaymentSpecifications.Id. The specification whose status changed. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses ALTER COLUMN PaymentSpecificationStatusId COMMENT 'Status: 0=New, 1=Active, 2=Cancelled, 3=CancelledPending, 4=Error. See Payment Specification Status Type. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses ALTER COLUMN EventTimestamp COMMENT 'When the status change occurred in the source system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses ALTER COLUMN Created COMMENT 'When this record was written to the DWH. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationStatuses)';

