-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Dictionary.ExtendedUserValueType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.ExtendedUserValueType.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_dictionary_extendeduservaluetype
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_dictionary_extendeduservaluetype (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_dictionary_extendeduservaluetype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining specific subtypes of extended user field values, primarily country-specific Tax ID and NationalPin classifications. Source: UserApiDB.Dictionary.ExtendedUserValueType on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.ExtendedUserValueType.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_dictionary_extendeduservaluetype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'ExtendedUserValueType',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_dictionary_extendeduservaluetype ALTER COLUMN ValueTypeID COMMENT 'Primary key. Value subtype identifier (37-79). Referenced by NationalPinValueTypeToReportType for regulatory reporting format. See Extended User Value Type. (Tier 1 - upstream wiki, UserApiDB.Dictionary.ExtendedUserValueType)';
ALTER TABLE main.compliance.bronze_userapidb_dictionary_extendeduservaluetype ALTER COLUMN Name COMMENT 'Value subtype name. camelCase for tax IDs (taxCPR), PascalCase for national PINs (NationalNumber). (Tier 1 - upstream wiki, UserApiDB.Dictionary.ExtendedUserValueType)';
ALTER TABLE main.compliance.bronze_userapidb_dictionary_extendeduservaluetype ALTER COLUMN FieldTypeID COMMENT 'FK to Dictionary.ExtendedUserFieldType. Parent field type: 3=Tax ID, 4=NationalPin, 9=DedicatedEv. (Tier 1 - upstream wiki, UserApiDB.Dictionary.ExtendedUserValueType)';
ALTER TABLE main.compliance.bronze_userapidb_dictionary_extendeduservaluetype ALTER COLUMN ExtendedUserValueTypeShortName COMMENT 'Shortened name for API responses. Typically matches Name. (Tier 1 - upstream wiki, UserApiDB.Dictionary.ExtendedUserValueType)';

