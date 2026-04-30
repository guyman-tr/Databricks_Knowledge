-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.ASIC.TestResults
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_asic_testresults
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_asic_testresults (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_asic_testresults SET TBLPROPERTIES (
    'comment' = 'Stores ASIC classification test results per user, recording pass/fail outcome and numeric score for each test attempt. Source: UserApiDB.ASIC.TestResults on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_asic_testresults SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'ASIC',
    'source_table' = 'TestResults',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_asic_testresults ALTER COLUMN TestId COMMENT 'Primary key. Auto-generated unique identifier for each test attempt. (Tier 1 - upstream wiki, UserApiDB.ASIC.TestResults)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_testresults ALTER COLUMN GCID COMMENT 'Global Customer ID. Identifies which user took the test. Indexed descending for fast per-user lookups. (Tier 1 - upstream wiki, UserApiDB.ASIC.TestResults)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_testresults ALTER COLUMN Success COMMENT 'Whether the user passed the ASIC classification test. 1 = passed, 0 = failed. (Tier 1 - upstream wiki, UserApiDB.ASIC.TestResults)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_testresults ALTER COLUMN Score COMMENT 'Numeric score achieved on the test. May be NULL if scoring is not applicable. (Tier 1 - upstream wiki, UserApiDB.ASIC.TestResults)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_testresults ALTER COLUMN OccurredAt COMMENT 'When the test was taken. Used for audit trails and ordering results. (Tier 1 - upstream wiki, UserApiDB.ASIC.TestResults)';
ALTER TABLE main.bi_db.bronze_userapidb_asic_testresults ALTER COLUMN Deleted COMMENT 'Soft-delete flag. 0 = active, 1 = deleted. All active queries filter WHERE Deleted = 0. (Tier 1 - upstream wiki, UserApiDB.ASIC.TestResults)';

