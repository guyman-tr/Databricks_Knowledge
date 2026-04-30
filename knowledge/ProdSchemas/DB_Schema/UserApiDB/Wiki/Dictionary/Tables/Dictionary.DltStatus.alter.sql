-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Dictionary.DltStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.DltStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_userapidb_dictionary_dltstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_userapidb_dictionary_dltstatus (business_group=general) ----
ALTER TABLE main.general.bronze_userapidb_dictionary_dltstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining Distributed Ledger Technology (blockchain) verification status codes for crypto-related operations. Source: UserApiDB.Dictionary.DltStatus on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.DltStatus.md).'
);

ALTER TABLE main.general.bronze_userapidb_dictionary_dltstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'DltStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_userapidb_dictionary_dltstatus ALTER COLUMN DltStatusID COMMENT 'Primary key. DLT verification state: 1=Pending, 2=Ongoing, 3=Failed, 4=Passed, 5=Inactive. See DLT Status. (Tier 1 - upstream wiki, UserApiDB.Dictionary.DltStatus)';
ALTER TABLE main.general.bronze_userapidb_dictionary_dltstatus ALTER COLUMN Name COMMENT 'Human-readable status label used in monitoring dashboards and compliance reports. (Tier 1 - upstream wiki, UserApiDB.Dictionary.DltStatus)';

