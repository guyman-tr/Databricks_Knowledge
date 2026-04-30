-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.DWH.Questions_Answers_V
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_dwh_questions_answers_v
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_dwh_questions_answers_v (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_dwh_questions_answers_v SET TBLPROPERTIES (
    'comment' = 'Data warehouse view joining KYC questions with their possible answers, providing a flat question-answer reference dataset for reporting and analytics. Source: UserApiDB.DWH.Questions_Answers_V on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_dwh_questions_answers_v SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'DWH',
    'source_table' = 'Questions_Answers_V',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_dwh_questions_answers_v ALTER COLUMN QuestionId COMMENT 'KYC question identifier. From KYC.Questions. Groups all answer rows for the same question. (Tier 1 - upstream wiki, UserApiDB.DWH.Questions_Answers_V)';
ALTER TABLE main.bi_db.bronze_userapidb_dwh_questions_answers_v ALTER COLUMN QuestionText COMMENT 'The full text of the KYC question as shown to the user. From KYC.Questions. (Tier 1 - upstream wiki, UserApiDB.DWH.Questions_Answers_V)';
ALTER TABLE main.bi_db.bronze_userapidb_dwh_questions_answers_v ALTER COLUMN MultipleSelection COMMENT 'Whether the user may select more than one answer for this question. 1=multiple allowed, 0=single answer only. From KYC.Questions. (Tier 1 - upstream wiki, UserApiDB.DWH.Questions_Answers_V)';
ALTER TABLE main.bi_db.bronze_userapidb_dwh_questions_answers_v ALTER COLUMN AnswerId COMMENT 'KYC answer option identifier. From KYC.Answers via KYC.QuestionsAnswers junction. (Tier 1 - upstream wiki, UserApiDB.DWH.Questions_Answers_V)';
ALTER TABLE main.bi_db.bronze_userapidb_dwh_questions_answers_v ALTER COLUMN AnswerText COMMENT 'The full text of the answer option as shown to the user. From KYC.Answers. (Tier 1 - upstream wiki, UserApiDB.DWH.Questions_Answers_V)';

