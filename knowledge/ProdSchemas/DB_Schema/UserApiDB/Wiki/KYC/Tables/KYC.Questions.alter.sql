-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.KYC.Questions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.Questions.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_kyc_questions
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_kyc_questions (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_kyc_questions SET TBLPROPERTIES (
    'comment' = 'Master table of KYC suitability questionnaire questions with localized text, multi-selection flag, and active status. Source: UserApiDB.KYC.Questions on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.Questions.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_kyc_questions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'KYC',
    'source_table' = 'Questions',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_kyc_questions ALTER COLUMN QuestionId COMMENT 'Part of composite PK. Question identifier. Same QuestionId appears in multiple languages. (Tier 1 - upstream wiki, UserApiDB.KYC.Questions)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_questions ALTER COLUMN LanguageId COMMENT 'Part of composite PK. Language of the question text. Implicit FK to Dictionary.Language. (Tier 1 - upstream wiki, UserApiDB.KYC.Questions)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_questions ALTER COLUMN QuestionText COMMENT 'Localized display text for this question. (Tier 1 - upstream wiki, UserApiDB.KYC.Questions)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_questions ALTER COLUMN MultipleSelection COMMENT 'Whether multiple answers can be selected. Default: 0 (single-select). (Tier 1 - upstream wiki, UserApiDB.KYC.Questions)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_questions ALTER COLUMN IsActive COMMENT 'Whether this question is currently active in the questionnaire. Default: 1 (active). (Tier 1 - upstream wiki, UserApiDB.KYC.Questions)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_questions ALTER COLUMN TranslationKey COMMENT 'i18n key for frontend localization. (Tier 1 - upstream wiki, UserApiDB.KYC.Questions)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_questions ALTER COLUMN QuestionShortDescription COMMENT 'Short internal description for reporting and admin tools. (Tier 1 - upstream wiki, UserApiDB.KYC.Questions)';

