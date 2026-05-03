-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.History.CustomerAnswers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/History/Tables/History.CustomerAnswers.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_history_customeranswers
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_history_customeranswers (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers SET TBLPROPERTIES (
    'comment' = 'Archive table storing deleted KYC customer answers, populated by KYC.ClearCustomerAnswers before deleting from the source table. Source: UserApiDB.History.CustomerAnswers on the UserApiDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/History/Tables/History.CustomerAnswers.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'History',
    'source_table' = 'CustomerAnswers',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers ALTER COLUMN ID COMMENT 'Primary key. Archive record ID. (Tier 1 - upstream wiki, UserApiDB.History.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers ALTER COLUMN GCID COMMENT 'User who originally answered. (Tier 1 - upstream wiki, UserApiDB.History.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers ALTER COLUMN QuestionId COMMENT 'Question that was answered. (Tier 1 - upstream wiki, UserApiDB.History.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers ALTER COLUMN AnswerId COMMENT 'Answer that was selected. (Tier 1 - upstream wiki, UserApiDB.History.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers ALTER COLUMN OccurredAt_InSource COMMENT 'When the answer was originally submitted in KYC.CustomerAnswers. (Tier 1 - upstream wiki, UserApiDB.History.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers ALTER COLUMN OccurredAt COMMENT 'When the answer was archived (cleared from the source table). (Tier 1 - upstream wiki, UserApiDB.History.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_history_customeranswers ALTER COLUMN FreeText COMMENT 'Free-text response that was provided. (Tier 1 - upstream wiki, UserApiDB.History.CustomerAnswers)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
