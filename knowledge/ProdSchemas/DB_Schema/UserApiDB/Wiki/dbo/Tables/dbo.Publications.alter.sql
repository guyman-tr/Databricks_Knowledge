-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.dbo.Publications
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_dbo_publications
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_dbo_publications (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications SET TBLPROPERTIES (
    'comment' = 'Stores user profile bio/publication data (sticky message, about me, strategy) with system versioning for temporal history. Source: UserApiDB.dbo.Publications on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'dbo',
    'source_table' = 'Publications',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN CID COMMENT 'Primary key. Legacy Customer ID (not GCID). One publication record per user. (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN Sticky COMMENT 'User''s pinned/sticky message shown at top of their profile feed. (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN AboutMe COMMENT 'User''s "About Me" bio text displayed on their profile page. (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN LanguageCode COMMENT 'Language code for the publication content. (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN StrategyID COMMENT 'User''s declared trading strategy. Implicit FK to Dictionary.Strategies. See Strategies. (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN Trace COMMENT 'Computed: JSON object with HostName, AppName, SUserName, SPID, DBName, ObjectName. For audit trail. (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN ValidFrom COMMENT 'System versioning row start (GENERATED ALWAYS AS ROW START). (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN ValidTo COMMENT 'System versioning row end (GENERATED ALWAYS AS ROW END). (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_publications ALTER COLUMN AboutMeShort COMMENT 'Shortened version of AboutMe for preview/thumbnail display. (Tier 1 - upstream wiki, UserApiDB.dbo.Publications)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
