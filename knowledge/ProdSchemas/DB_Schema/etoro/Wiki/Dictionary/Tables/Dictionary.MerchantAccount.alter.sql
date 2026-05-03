-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.MerchantAccount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MerchantAccount.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_merchantaccount
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_merchantaccount (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_merchantaccount SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the regional/entity-specific merchant accounts under each payment gateway, controlling which eToro entity processes each transaction. Source: etoro.Dictionary.MerchantAccount on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MerchantAccount.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_merchantaccount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'MerchantAccount',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_merchantaccount ALTER COLUMN MerchantAccountID COMMENT 'Unique merchant account identifier. Each ID represents a specific gateway + entity combination used for payment processing. (Tier 1 - upstream wiki, etoro.Dictionary.MerchantAccount)';
ALTER TABLE main.general.bronze_etoro_dictionary_merchantaccount ALTER COLUMN MerchantID COMMENT 'Parent merchant/gateway: references Dictionary.Merchant.ID. Multiple accounts per merchant. 1=Checkout, 2=WorldPay, etc. (Tier 1 - upstream wiki, etoro.Dictionary.MerchantAccount)';
ALTER TABLE main.general.bronze_etoro_dictionary_merchantaccount ALTER COLUMN Name COMMENT 'Account name encoding merchant + region: "CheckoutEU", "WorldpayAU", "CheckoutEMUK". Used as technical identifier in payment processing. (Tier 1 - upstream wiki, etoro.Dictionary.MerchantAccount)';
ALTER TABLE main.general.bronze_etoro_dictionary_merchantaccount ALTER COLUMN BODescription COMMENT 'Back-office entity label: "eToroEU", "eToroUK", "eToroAU", "EMUK". Identifies which eToro legal entity receives the funds. Used in reconciliation and regulatory reporting. (Tier 1 - upstream wiki, etoro.Dictionary.MerchantAccount)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
