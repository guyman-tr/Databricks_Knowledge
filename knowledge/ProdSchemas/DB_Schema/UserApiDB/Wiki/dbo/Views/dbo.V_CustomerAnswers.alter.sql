-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.dbo.V_CustomerAnswers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_userapidb_dbo_v_customeranswers
--   main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_dbo_v_customeranswers (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers SET TBLPROPERTIES (
    'comment' = 'View joining KYC.CustomerAnswers with V_KYC to return user answers with question text, answer text, and thresholds. Source: UserApiDB.dbo.V_CustomerAnswers on the UserApiDB production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'dbo',
    'source_table' = 'V_CustomerAnswers',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN GCID COMMENT 'User who answered. From KYC.CustomerAnswers. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN OccurredAt COMMENT 'When answer was submitted. From KYC.CustomerAnswers. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN FreeText COMMENT 'Free-text response. From KYC.CustomerAnswers. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN QuestionId COMMENT 'Question identifier. From V_KYC. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN QuestionText COMMENT 'Question display text. From V_KYC -> KYC.Questions. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN AnswerId COMMENT 'Answer identifier. From V_KYC. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN AnswerText COMMENT 'Answer display text. From V_KYC -> KYC.Answers. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN MinThreshold COMMENT 'Min range value. From V_KYC -> KYC.AnswerThresholds. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN MaxThreshold COMMENT 'Max range value. From V_KYC -> KYC.AnswerThresholds. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers ALTER COLUMN MultipleSelection COMMENT 'Whether question allows multiple answers. From V_KYC -> KYC.Questions. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';

-- ---- UC Target: main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked SET TBLPROPERTIES (
    'comment' = 'View joining KYC.CustomerAnswers with V_KYC to return user answers with question text, answer text, and thresholds. Source: UserApiDB.dbo.V_CustomerAnswers on the UserApiDB production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'dbo',
    'source_table' = 'V_CustomerAnswers',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN GCID COMMENT 'User who answered. From KYC.CustomerAnswers. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN OccurredAt COMMENT 'When answer was submitted. From KYC.CustomerAnswers. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN FreeText COMMENT 'Free-text response. From KYC.CustomerAnswers. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN QuestionId COMMENT 'Question identifier. From V_KYC. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN QuestionText COMMENT 'Question display text. From V_KYC -> KYC.Questions. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN AnswerId COMMENT 'Answer identifier. From V_KYC. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN AnswerText COMMENT 'Answer display text. From V_KYC -> KYC.Answers. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN MinThreshold COMMENT 'Min range value. From V_KYC -> KYC.AnswerThresholds. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN MaxThreshold COMMENT 'Max range value. From V_KYC -> KYC.AnswerThresholds. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked ALTER COLUMN MultipleSelection COMMENT 'Whether question allows multiple answers. From V_KYC -> KYC.Questions. (Tier 1 - upstream wiki, UserApiDB.dbo.V_CustomerAnswers)';

