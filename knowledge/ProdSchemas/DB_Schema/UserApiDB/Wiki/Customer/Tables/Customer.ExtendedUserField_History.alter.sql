-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Customer.ExtendedUserField_History
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserField_History.md
-- Layer: bronze
-- UC Target: main.pii_data.bronze_userapidb_customer_extendeduserfield_history
-- =============================================================================

-- ---- UC Target: main.pii_data.bronze_userapidb_customer_extendeduserfield_history (business_group=pii_data) ----
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history SET TBLPROPERTIES (
    'comment' = 'Audit history table tracking all changes to extended user field values, including the action type (INSERT/UPDATE/DELETE). Source: UserApiDB.Customer.ExtendedUserField_History on the UserApiDB production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserField_History.md).'
);

ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Customer',
    'source_table' = 'ExtendedUserField_History',
    'business_group' = 'pii_data',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN ID COMMENT 'Primary key. Auto-incrementing audit record identifier. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN GCID COMMENT 'Global Customer ID whose field was changed. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN FieldId COMMENT 'Which extended field was changed. Maps to Dictionary.ExtendedUserField. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN Value COMMENT 'The field value at the time of the change (new value for INSERT/UPDATE, old value for DELETE). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN LastModified COMMENT 'Original LastModified timestamp from the source record. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN Occurred COMMENT 'When this history record was created (the actual change timestamp). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN Action COMMENT 'Type of change: ''INSERT'', ''UPDATE'', or ''DELETE''. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN TypeId COMMENT 'Value subtype at the time of the change. Maps to Dictionary.ExtendedUserValueType. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN CountryId COMMENT 'Country context at the time of the change. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield_history ALTER COLUMN AdditionalDetails COMMENT 'Additional data at the time of the change. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField_History)';

