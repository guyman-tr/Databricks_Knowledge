-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.ASIC.CustomerAnswers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.CustomerAnswers.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_asic_customeranswers
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_asic_customeranswers (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_asic_customeranswers SET TBLPROPERTIES (
    'comment' = 'Stores individual question and answer pairs for each ASIC classification test attempt, providing a full record of user responses. Source: UserApiDB.ASIC.CustomerAnswers on the UserApiDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.CustomerAnswers.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_asic_customeranswers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'ASIC',
    'source_table' = 'CustomerAnswers',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_asic_customeranswers ALTER COLUMN CustomerAnswerId COMMENT 'Primary key. Auto-generated unique identifier for each Q&A row. (Tier 1 - upstream wiki, UserApiDB.ASIC.CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_customeranswers ALTER COLUMN TestId COMMENT 'FK to ASIC.TestResults.TestId. Groups all Q&A pairs for a single test attempt. Indexed for fast retrieval. (Tier 1 - upstream wiki, UserApiDB.ASIC.CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_customeranswers ALTER COLUMN Question COMMENT 'Full text of the question asked during the test. Stored as text (not ID) for audit self-sufficiency. (Tier 1 - upstream wiki, UserApiDB.ASIC.CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_customeranswers ALTER COLUMN Answer COMMENT 'Full text of the user''s answer. Stored as text for audit self-sufficiency. (Tier 1 - upstream wiki, UserApiDB.ASIC.CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_customeranswers ALTER COLUMN OccurredAt COMMENT 'When this Q&A pair was recorded. Typically matches the parent test''s OccurredAt. (Tier 1 - upstream wiki, UserApiDB.ASIC.CustomerAnswers)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
