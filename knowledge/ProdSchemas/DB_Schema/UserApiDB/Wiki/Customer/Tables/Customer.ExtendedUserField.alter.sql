-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Customer.ExtendedUserField
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserField.md
-- Layer: bronze
-- UC Targets (2):
--   main.pii_data.bronze_userapidb_customer_extendeduserfield
--   main.compliance.bronze_userapidb_customer_extendeduserfield_masked
-- =============================================================================

-- ---- UC Target: main.pii_data.bronze_userapidb_customer_extendeduserfield (business_group=pii_data) ----
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield SET TBLPROPERTIES (
    'comment' = 'Stores user-provided values for regulation-specific extended profile fields (tax IDs, national PINs, employer names, etc.) per user, field, and country. Source: UserApiDB.Customer.ExtendedUserField on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserField.md).'
);

ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Customer',
    'source_table' = 'ExtendedUserField',
    'business_group' = 'pii_data',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN GCID COMMENT 'Part of unique clustered key. Global Customer ID. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN FieldId COMMENT 'Part of unique clustered key. FK to Dictionary.ExtendedUserField. Identifies which field: 0=province, 6=TaxId, 7=NationalPin, etc. See Extended User Field. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN Value COMMENT 'The user-provided value for this field (e.g., the actual tax number, national PIN). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN LastModified COMMENT 'When this field value was last updated. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN TypeId COMMENT 'Value subtype. Maps to Dictionary.ExtendedUserValueType for further classification (e.g., which specific type of tax ID). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN ID COMMENT 'Surrogate PK (NONCLUSTERED). Auto-incrementing. Used for row identification. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN CountryId COMMENT 'Part of unique clustered key. Country context for this field value. Allows per-country field values. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN AdditionalDetails COMMENT 'JSON or freeform additional data (e.g., document details, validation metadata). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';

-- ---- UC Target: main.compliance.bronze_userapidb_customer_extendeduserfield_masked (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked SET TBLPROPERTIES (
    'comment' = 'Stores user-provided values for regulation-specific extended profile fields (tax IDs, national PINs, employer names, etc.) per user, field, and country. Source: UserApiDB.Customer.ExtendedUserField on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserField.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Customer',
    'source_table' = 'ExtendedUserField',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked ALTER COLUMN GCID COMMENT 'Part of unique clustered key. Global Customer ID. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked ALTER COLUMN FieldId COMMENT 'Part of unique clustered key. FK to Dictionary.ExtendedUserField. Identifies which field: 0=province, 6=TaxId, 7=NationalPin, etc. See Extended User Field. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked ALTER COLUMN Value COMMENT 'The user-provided value for this field (e.g., the actual tax number, national PIN). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked ALTER COLUMN LastModified COMMENT 'When this field value was last updated. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked ALTER COLUMN TypeId COMMENT 'Value subtype. Maps to Dictionary.ExtendedUserValueType for further classification (e.g., which specific type of tax ID). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked ALTER COLUMN ID COMMENT 'Surrogate PK (NONCLUSTERED). Auto-incrementing. Used for row identification. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked ALTER COLUMN CountryId COMMENT 'Part of unique clustered key. Country context for this field value. Allows per-country field values. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.compliance.bronze_userapidb_customer_extendeduserfield_masked ALTER COLUMN AdditionalDetails COMMENT 'JSON or freeform additional data (e.g., document details, validation metadata). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC (batch 1 — both targets)
-- Redeploy pii_data column comments: 2026-06-23 (drift fix — see Customer.ExtendedUserField.redeploy_pii_data_comments.sql)
-- Bronze deploy: UserApiDB batch 1
-- ====================
