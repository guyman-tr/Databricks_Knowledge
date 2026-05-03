-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CardType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cardtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cardtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cardtype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 32 payment card network brands (Visa, MasterCard, Diners, etc.) with their active status and 3D Secure authentication configuration. Source: etoro.Dictionary.CardType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cardtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CardType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cardtype ALTER COLUMN CardTypeID COMMENT 'Card network identifier. Active brands: 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. Inactive: 0=None, 4=Amex, 5=FirePay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Local Card, 14=China UnionPay, 15=Solo, 16=Cirrus, 17=GE Capital, 18=Unknown, 19-31=various regional/legacy brands. (Tier 1 - upstream wiki, etoro.Dictionary.CardType)';
ALTER TABLE main.general.bronze_etoro_dictionary_cardtype ALTER COLUMN Name COMMENT 'Card brand name. Unique constraint prevents duplicates. Used in payment UI, transaction records, and fraud reporting. (Tier 1 - upstream wiki, etoro.Dictionary.CardType)';
ALTER TABLE main.general.bronze_etoro_dictionary_cardtype ALTER COLUMN IsActive COMMENT 'Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. DEFAULT 1 (new card types are active by default). Only 4 of 32 are currently active. (Tier 1 - upstream wiki, etoro.Dictionary.CardType)';
ALTER TABLE main.general.bronze_etoro_dictionary_cardtype ALTER COLUMN Is3dsOn COMMENT 'Whether 3D Secure authentication is mandatory for this card type: 1=3DS required (redirects to issuer authentication), 0=no 3DS. DEFAULT 0. Only Visa and MasterCard have 3DS enabled, for PSD2/SCA compliance. (Tier 1 - upstream wiki, etoro.Dictionary.CardType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
