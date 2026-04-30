-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Merchant
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Merchant.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_merchant
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_merchant (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_merchant SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the payment processing companies (merchants/gateways) that handle deposit and withdrawal transactions on the eToro platform. Source: etoro.Dictionary.Merchant on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Merchant.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_merchant SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Merchant',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_merchant ALTER COLUMN ID COMMENT 'Payment gateway identifier. Key merchants: 1=Checkout, 2=WorldPay, 3=Neteller-PaySafe, 4=PayPal, 5=POLi, 6=iDEAL-IXOPAY-Worldpay, 7=Trustly-IXOPAY-powercash, 8=Skrill-PaySafe, 9=RapidTransfer, 10=Giropay-Sofort. (Tier 1 - upstream wiki, etoro.Dictionary.Merchant)';
ALTER TABLE main.general.bronze_etoro_dictionary_merchant ALTER COLUMN Name COMMENT 'Payment gateway company/product name. Includes integration provider suffix for aggregated gateways (e.g., "Trustly - IXOPAY-powercash"). (Tier 1 - upstream wiki, etoro.Dictionary.Merchant)';
ALTER TABLE main.general.bronze_etoro_dictionary_merchant ALTER COLUMN Description COMMENT 'Optional description. Currently NULL for all rows — name is self-descriptive. (Tier 1 - upstream wiki, etoro.Dictionary.Merchant)';

