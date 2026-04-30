-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Customer.ExtendedUserFieldValidation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation SET TBLPROPERTIES (
    'comment' = 'Tracks validation status of extended user fields per user, country, and field combination. Source: UserApiDB.Customer.ExtendedUserFieldValidation on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Customer',
    'source_table' = 'ExtendedUserFieldValidation',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation ALTER COLUMN GCID COMMENT 'Part of composite PK. Global Customer ID. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserFieldValidation)';
ALTER TABLE main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation ALTER COLUMN CountryID COMMENT 'Part of composite PK. Country context for validation. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserFieldValidation)';
ALTER TABLE main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation ALTER COLUMN FieldID COMMENT 'Part of composite PK. Extended field identifier. Maps to Dictionary.ExtendedUserField. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserFieldValidation)';
ALTER TABLE main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation ALTER COLUMN IsValid COMMENT 'Whether the field value passed validation. NULL=not yet validated, 1=valid, 0=invalid. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserFieldValidation)';

