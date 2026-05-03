-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Dictionary.MandatoryType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.MandatoryType.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_dictionary_mandatorytype
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_dictionary_mandatorytype (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_dictionary_mandatorytype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining whether a KYC field or document is required, optional, or exempt for a given regulatory configuration. Source: UserApiDB.Dictionary.MandatoryType on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.MandatoryType.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_dictionary_mandatorytype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'MandatoryType',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_dictionary_mandatorytype ALTER COLUMN MandatoryTypeID COMMENT 'Primary key. Requirement level: 0=Exempt (hidden), 1=Optional (shown, not required), 2=Mandatory (required for completion). See Mandatory Type. (Tier 1 - upstream wiki, UserApiDB.Dictionary.MandatoryType)';
ALTER TABLE main.compliance.bronze_userapidb_dictionary_mandatorytype ALTER COLUMN Name COMMENT 'Requirement level label used in admin configuration tools. (Tier 1 - upstream wiki, UserApiDB.Dictionary.MandatoryType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
