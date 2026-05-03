-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DocumentAutheticationType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentAutheticationType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_documentautheticationtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_documentautheticationtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_documentautheticationtype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the types of document authentication processes used during KYC verification - Proof of Identity (POI), Proof of Address (POA), Selfie, and biometric variants. Source: etoro.Dictionary.DocumentAutheticationType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentAutheticationType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_documentautheticationtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DocumentAutheticationType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_documentautheticationtype ALTER COLUMN TypeID COMMENT 'Primary key identifying the authentication type. 1=POI, 2=POA, 3=Selfie, 4=SelfieLiveliness, 5=SelfieMotion. Referenced by BackOffice.DocumentAuthenticationReasons.AutheticationTypeID (note: DDL preserves the original "Authetication" typo). (Tier 1 - upstream wiki, etoro.Dictionary.DocumentAutheticationType)';
ALTER TABLE main.general.bronze_etoro_dictionary_documentautheticationtype ALTER COLUMN Type COMMENT 'Human-readable authentication type name. Used in BackOffice KYC review UI and compliance reports. Nullable in DDL but all 5 rows have values. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentAutheticationType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
