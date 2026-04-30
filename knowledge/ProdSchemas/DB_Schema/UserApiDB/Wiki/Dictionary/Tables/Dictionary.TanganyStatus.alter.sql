-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Dictionary.TanganyStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.TanganyStatus.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_dictionary_tanganystatus
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_dictionary_tanganystatus (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_tanganystatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the status of a user''s Tangany crypto custody wallet under MiCA regulation. Source: UserApiDB.Dictionary.TanganyStatus on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.TanganyStatus.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_dictionary_tanganystatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TanganyStatus',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_tanganystatus ALTER COLUMN TanganyStatusID COMMENT 'Primary key. Wallet state: 1=Pending, 2=Internal, 3=Customer, 4=Inactive, 5=MicaCustomer, 6=ConsentCustomer. See Tangany Status. (Tier 1 - upstream wiki, UserApiDB.Dictionary.TanganyStatus)';
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_tanganystatus ALTER COLUMN Name COMMENT 'Status label for crypto custody monitoring and compliance reports. (Tier 1 - upstream wiki, UserApiDB.Dictionary.TanganyStatus)';

