-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.KYC.QuestionsAnswers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.QuestionsAnswers.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_kyc_questionsanswers
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_kyc_questionsanswers (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_kyc_questionsanswers SET TBLPROPERTIES (
    'comment' = 'Junction table mapping questions to their available answers with display order. Source: UserApiDB.KYC.QuestionsAnswers on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.QuestionsAnswers.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_kyc_questionsanswers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'KYC',
    'source_table' = 'QuestionsAnswers',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_kyc_questionsanswers ALTER COLUMN QuestionId COMMENT 'Part of composite PK. References KYC.Questions. (Tier 1 - upstream wiki, UserApiDB.KYC.QuestionsAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_questionsanswers ALTER COLUMN AnswerId COMMENT 'Part of composite PK. References KYC.Answers. (Tier 1 - upstream wiki, UserApiDB.KYC.QuestionsAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_questionsanswers ALTER COLUMN Order COMMENT 'Display order of this answer within the question. NULL for unordered answers. (Tier 1 - upstream wiki, UserApiDB.KYC.QuestionsAnswers)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
