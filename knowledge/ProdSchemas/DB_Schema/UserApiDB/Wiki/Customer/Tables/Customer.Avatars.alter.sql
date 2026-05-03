-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Customer.Avatars
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.Avatars.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_customer_avatars
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_customer_avatars (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars SET TBLPROPERTIES (
    'comment' = 'Stores user profile avatar images across multiple sizes and versions, with CDN URLs for image delivery. Source: UserApiDB.Customer.Avatars on the UserApiDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.Avatars.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_customer_avatars SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Customer',
    'source_table' = 'Avatars',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars ALTER COLUMN AvatarId COMMENT 'Primary key. Auto-incrementing avatar record identifier. (Tier 1 - upstream wiki, UserApiDB.Customer.Avatars)';
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars ALTER COLUMN CID COMMENT 'Customer ID (legacy). Links to the user who owns this avatar. Indexed for fast lookup. (Tier 1 - upstream wiki, UserApiDB.Customer.Avatars)';
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars ALTER COLUMN Width COMMENT 'Image width in pixels. Multiple sizes stored per avatar version (e.g., 50, 100, 200, 500). (Tier 1 - upstream wiki, UserApiDB.Customer.Avatars)';
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars ALTER COLUMN Height COMMENT 'Image height in pixels. Typically matches Width for square avatars. (Tier 1 - upstream wiki, UserApiDB.Customer.Avatars)';
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars ALTER COLUMN VersionNum COMMENT 'Version number for this avatar. Incremented when user uploads a new profile photo. Latest version is the active one. (Tier 1 - upstream wiki, UserApiDB.Customer.Avatars)';
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars ALTER COLUMN ImageURL COMMENT 'Full CDN URL for this avatar image variant. Used directly in UI rendering. (Tier 1 - upstream wiki, UserApiDB.Customer.Avatars)';
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars ALTER COLUMN AvatarTypeId COMMENT 'Type of avatar image (e.g., profile photo, cover image). (Tier 1 - upstream wiki, UserApiDB.Customer.Avatars)';
ALTER TABLE main.compliance.bronze_userapidb_customer_avatars ALTER COLUMN Ocurred COMMENT 'Timestamp when this avatar record was created. Default: current UTC time. (Tier 1 - upstream wiki, UserApiDB.Customer.Avatars)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
