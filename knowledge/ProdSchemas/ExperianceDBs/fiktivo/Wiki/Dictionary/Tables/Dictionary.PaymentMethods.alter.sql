-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.Dictionary.PaymentMethods
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PaymentMethods.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_dictionary_paymentmethods
--   bi_db.bronze_fiktivo_fiktivo_dictionary.paymentmethods
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dictionary_paymentmethods (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_paymentmethods SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the available methods for paying affiliate commissions, determining payment processing rules, fees, and settlement timelines. Source: fiktivo.Dictionary.PaymentMethods on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PaymentMethods.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_paymentmethods SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentMethods',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_paymentmethods ALTER COLUMN PaymentMethodID COMMENT 'Primary key (IDENTITY) identifying the payment method. Values: 1=None, 2=PayPal, 3=Wire Transfer, 4=eToro Trading Account, 5=Neteller, 6=Skrill, 7=Webmoney, 8=Credit Card, 9=China Union Pay. See Payment Methods for full definitions. IDENTITY column - NOT FOR REPLICATION. (Tier 1 - upstream wiki, fiktivo.Dictionary.PaymentMethods)';
ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_paymentmethods ALTER COLUMN Name COMMENT 'Human-readable label for the payment method. Used in admin UIs, payment processing screens, and affiliate self-service portals. (Tier 1 - upstream wiki, fiktivo.Dictionary.PaymentMethods)';

-- ---- UC Target: bi_db.bronze_fiktivo_fiktivo_dictionary.paymentmethods (business_group=BI_DB) ----
ALTER TABLE bi_db.bronze_fiktivo_fiktivo_dictionary.paymentmethods SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the available methods for paying affiliate commissions, determining payment processing rules, fees, and settlement timelines. Source: fiktivo.Dictionary.PaymentMethods on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PaymentMethods.md).'
);

ALTER TABLE bi_db.bronze_fiktivo_fiktivo_dictionary.paymentmethods SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentMethods',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE bi_db.bronze_fiktivo_fiktivo_dictionary.paymentmethods ALTER COLUMN PaymentMethodID COMMENT 'Primary key (IDENTITY) identifying the payment method. Values: 1=None, 2=PayPal, 3=Wire Transfer, 4=eToro Trading Account, 5=Neteller, 6=Skrill, 7=Webmoney, 8=Credit Card, 9=China Union Pay. See Payment Methods for full definitions. IDENTITY column - NOT FOR REPLICATION. (Tier 1 - upstream wiki, fiktivo.Dictionary.PaymentMethods)';
ALTER TABLE bi_db.bronze_fiktivo_fiktivo_dictionary.paymentmethods ALTER COLUMN Name COMMENT 'Human-readable label for the payment method. Used in admin UIs, payment processing screens, and affiliate self-service portals. (Tier 1 - upstream wiki, fiktivo.Dictionary.PaymentMethods)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
