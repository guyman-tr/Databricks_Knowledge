-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.PaymentSpecificationDetails
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecificationDetails.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails SET TBLPROPERTIES (
    'comment' = 'Stores originator details for payment specifications, capturing who initiated the direct debit mandate. Source: FiatDwhDB.dbo.PaymentSpecificationDetails on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecificationDetails.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'PaymentSpecificationDetails',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDetails)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails ALTER COLUMN PaymentSpecificationId COMMENT 'FK to dbo.PaymentSpecifications.Id. The specification these details belong to. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDetails)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails ALTER COLUMN OriginatorName COMMENT 'Name of the party that set up the payment specification (e.g., the direct debit originator company name). (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDetails)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails ALTER COLUMN OriginatorId COMMENT 'External identifier of the originator. NULL if not provided. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDetails)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails ALTER COLUMN EventTimestamp COMMENT 'When the detail event occurred in the source system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDetails)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails ALTER COLUMN Created COMMENT 'When this record was written to the DWH. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationDetails)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
