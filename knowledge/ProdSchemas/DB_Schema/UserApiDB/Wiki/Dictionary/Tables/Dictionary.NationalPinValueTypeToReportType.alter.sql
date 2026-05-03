-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Dictionary.NationalPinValueTypeToReportType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.NationalPinValueTypeToReportType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype SET TBLPROPERTIES (
    'comment' = 'Junction table mapping ExtendedUserValueType national identifiers to their regulatory reporting format (NIND, CCCP, CONCAT, LEI). Source: UserApiDB.Dictionary.NationalPinValueTypeToReportType on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.NationalPinValueTypeToReportType.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'NationalPinValueTypeToReportType',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype ALTER COLUMN ValueTypeID COMMENT 'Part of composite PK. FK to Dictionary.ExtendedUserValueType. The national identifier subtype. (Tier 1 - upstream wiki, UserApiDB.Dictionary.NationalPinValueTypeToReportType)';
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype ALTER COLUMN NationalPinReportTypeID COMMENT 'Part of composite PK. FK to Dictionary.NationalPinReportType. The regulatory reporting format (1=NIND, 2=CCCP, 3=CONCAT, 4=LEI). (Tier 1 - upstream wiki, UserApiDB.Dictionary.NationalPinValueTypeToReportType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
