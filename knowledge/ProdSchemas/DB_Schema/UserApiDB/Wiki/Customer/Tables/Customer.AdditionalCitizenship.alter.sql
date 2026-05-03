-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Customer.AdditionalCitizenship
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_customer_additionalcitizenship
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_customer_additionalcitizenship (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_userapidb_customer_additionalcitizenship SET TBLPROPERTIES (
    'comment' = 'Stores additional citizenship/nationality for users who hold dual or multiple citizenships, with temporal history tracking via system versioning. Source: UserApiDB.Customer.AdditionalCitizenship on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_customer_additionalcitizenship SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Customer',
    'source_table' = 'AdditionalCitizenship',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_customer_additionalcitizenship ALTER COLUMN AdditionalCitizenshipID COMMENT 'Primary key. Auto-incrementing surrogate key. (Tier 1 - upstream wiki, UserApiDB.Customer.AdditionalCitizenship)';
ALTER TABLE main.bi_db.bronze_userapidb_customer_additionalcitizenship ALTER COLUMN GCID COMMENT 'Global Customer ID. Unique constraint - one additional citizenship per user. (Tier 1 - upstream wiki, UserApiDB.Customer.AdditionalCitizenship)';
ALTER TABLE main.bi_db.bronze_userapidb_customer_additionalcitizenship ALTER COLUMN CountryID COMMENT 'The additional citizenship country. Implicit FK to Dictionary.Country. See Country. (Tier 1 - upstream wiki, UserApiDB.Customer.AdditionalCitizenship)';
ALTER TABLE main.bi_db.bronze_userapidb_customer_additionalcitizenship ALTER COLUMN StartTime COMMENT 'System versioning row start time (GENERATED ALWAYS AS ROW START). (Tier 1 - upstream wiki, UserApiDB.Customer.AdditionalCitizenship)';
ALTER TABLE main.bi_db.bronze_userapidb_customer_additionalcitizenship ALTER COLUMN EndTime COMMENT 'System versioning row end time (GENERATED ALWAYS AS ROW END). (Tier 1 - upstream wiki, UserApiDB.Customer.AdditionalCitizenship)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
