-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PromotionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PromotionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_promotiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_promotiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_promotiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 2 promotion categories — Replaceable Promotion and Deposit Bonus — controlling how marketing promotions interact with the eToro messaging system. Source: etoro.Dictionary.PromotionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PromotionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_promotiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PromotionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_promotiontype ALTER COLUMN PromotionTypeID COMMENT 'Primary key. 1=Replaceable Promotion, 2=Deposit Bonus. Referenced by Maintenance.MessageTemplate. (Tier 1 - upstream wiki, etoro.Dictionary.PromotionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_promotiontype ALTER COLUMN IsReplaceable COMMENT 'Controls promotion coexistence behavior. 1=new promotion replaces existing active promotion; 0=promotions persist independently. (Tier 1 - upstream wiki, etoro.Dictionary.PromotionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_promotiontype ALTER COLUMN Name COMMENT 'Human-readable promotion category name. Unique index enforces no duplicates. Used in BackOffice UI and resolved by Internal.GetPromotionTypeID. (Tier 1 - upstream wiki, etoro.Dictionary.PromotionType)';

