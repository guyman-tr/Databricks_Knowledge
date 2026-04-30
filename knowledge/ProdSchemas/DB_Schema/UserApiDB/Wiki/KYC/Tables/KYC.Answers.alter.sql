-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.KYC.Answers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.Answers.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_kyc_answers
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_kyc_answers (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_kyc_answers SET TBLPROPERTIES (
    'comment' = 'Master table of KYC questionnaire answer options with localized text, status tracking, free-text validation, and translation keys. Source: UserApiDB.KYC.Answers on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.Answers.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_kyc_answers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'KYC',
    'source_table' = 'Answers',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_kyc_answers ALTER COLUMN AnswerId COMMENT 'Primary key. Answer identifier. Referenced by QuestionsAnswers, CustomerAnswers, AnswerThresholds, CryptoAssessmentAnswers. (Tier 1 - upstream wiki, UserApiDB.KYC.Answers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_answers ALTER COLUMN LanguageId COMMENT 'Language of the answer text. Implicit FK to Dictionary.Language. (Tier 1 - upstream wiki, UserApiDB.KYC.Answers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_answers ALTER COLUMN AnswerText COMMENT 'Localized display text for this answer option. (Tier 1 - upstream wiki, UserApiDB.KYC.Answers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_answers ALTER COLUMN StatusID COMMENT 'FK to Dictionary.AnswerStatus. 0=Outdated, 1=Active. Default: 1. See Answer Status. (Tier 1 - upstream wiki, UserApiDB.KYC.Answers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_answers ALTER COLUMN FreeTextValidationExpression COMMENT 'Regex pattern for validating free-text input when this answer is selected. NULL if no free-text input. (Tier 1 - upstream wiki, UserApiDB.KYC.Answers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_answers ALTER COLUMN TranslationKey COMMENT 'i18n translation key for multi-language support. Used by frontend to look up localized text. (Tier 1 - upstream wiki, UserApiDB.KYC.Answers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_answers ALTER COLUMN AnswerShortDescription COMMENT 'Short description for internal use and reporting. (Tier 1 - upstream wiki, UserApiDB.KYC.Answers)';

