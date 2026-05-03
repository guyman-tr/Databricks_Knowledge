-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PhoneVerificationListType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneVerificationListType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_phoneverificationlisttype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_phoneverificationlisttype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationlisttype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 2 phone verification list categories - White (trusted) and Black (blocked) - for phone number allowlist/blocklist management. Source: etoro.Dictionary.PhoneVerificationListType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneVerificationListType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationlisttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PhoneVerificationListType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationlisttype ALTER COLUMN VerificationListTypeID COMMENT 'Primary key identifying the list type. 1=White (trusted), 2=Black (blocked). Used in phone verification list management. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneVerificationListType)';
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationlisttype ALTER COLUMN VerificationListType COMMENT 'Human-readable label for the list type. "White" or "Black". (Tier 1 - upstream wiki, etoro.Dictionary.PhoneVerificationListType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
