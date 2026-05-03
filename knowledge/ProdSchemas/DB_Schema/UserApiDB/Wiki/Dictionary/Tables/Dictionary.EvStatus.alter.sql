-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Dictionary.EvStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.EvStatus.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_dictionary_evstatus
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_dictionary_evstatus (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_evstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the overall Electronic Verification status for a user''s identity verification process, aggregated across multiple verification sources. Source: UserApiDB.Dictionary.EvStatus on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.EvStatus.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_dictionary_evstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'EvStatus',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_evstatus ALTER COLUMN EvStatusId COMMENT 'Primary key. Overall EV outcome: 0=None, 1=One Source, 2=Two Sources, 3=No Match, 4=ApprovedWithConflict, 5=Approved, 6=Rejected, 7=Alert, 8=One Source Verified. See EV Status. (Tier 1 - upstream wiki, UserApiDB.Dictionary.EvStatus)';
ALTER TABLE main.bi_db.bronze_userapidb_dictionary_evstatus ALTER COLUMN Name COMMENT 'Status label used in compliance dashboards and user management tools. (Tier 1 - upstream wiki, UserApiDB.Dictionary.EvStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
