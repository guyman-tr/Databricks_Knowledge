-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Dictionary.EvProvider
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.EvProvider.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_dictionary_evprovider
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_dictionary_evprovider (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_dictionary_evprovider SET TBLPROPERTIES (
    'comment' = 'Lookup table defining third-party Electronic Verification identity verification providers integrated with the platform, classified by verification method. Source: UserApiDB.Dictionary.EvProvider on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.EvProvider.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_dictionary_evprovider SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'EvProvider',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_dictionary_evprovider ALTER COLUMN EvProviderId COMMENT 'Primary key. Provider identifier (1-15). See EV Provider. (Tier 1 - upstream wiki, UserApiDB.Dictionary.EvProvider)';
ALTER TABLE main.compliance.bronze_userapidb_dictionary_evprovider ALTER COLUMN Name COMMENT 'Provider display name used in admin tools and verification logs. (Tier 1 - upstream wiki, UserApiDB.Dictionary.EvProvider)';
ALTER TABLE main.compliance.bronze_userapidb_dictionary_evprovider ALTER COLUMN ProviderTypeID COMMENT 'FK to Dictionary.ProviderType. Classification: 0=ElectronicVerification, 1=DocumentsVerification. See Provider Type. (Tier 1 - upstream wiki, UserApiDB.Dictionary.EvProvider)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
