-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PaymentServiceStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentServiceStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_paymentservicestatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_paymentservicestatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_paymentservicestatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining payment service operational statuses — currently contains test/placeholder data indicating the table is in development or staging use. Source: etoro.Dictionary.PaymentServiceStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentServiceStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_paymentservicestatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentServiceStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_paymentservicestatus ALTER COLUMN PaymentServiceStatusID COMMENT 'Primary key identifying the payment service status. Currently contains test values (1-3). Referenced by Billing.PaymentService to control payment service availability. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentServiceStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentservicestatus ALTER COLUMN Name COMMENT 'Unique human-readable label for the status. Enforced unique by DPSS_NAME index. Used in billing configuration screens and service management. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentServiceStatus)';

