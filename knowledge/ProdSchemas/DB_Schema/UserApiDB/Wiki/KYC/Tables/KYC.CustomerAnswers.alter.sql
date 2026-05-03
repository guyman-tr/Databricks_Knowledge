-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.KYC.CustomerAnswers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CustomerAnswers.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_kyc_customeranswers
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_kyc_customeranswers (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_kyc_customeranswers SET TBLPROPERTIES (
    'comment' = 'Stores user responses to KYC suitability questionnaire questions, with 180M+ records tracking every answer submission. Source: UserApiDB.KYC.CustomerAnswers on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CustomerAnswers.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_kyc_customeranswers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'KYC',
    'source_table' = 'CustomerAnswers',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_kyc_customeranswers ALTER COLUMN GCID COMMENT 'Part of composite PK. Global Customer ID. (Tier 1 - upstream wiki, UserApiDB.KYC.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_customeranswers ALTER COLUMN QuestionId COMMENT 'Part of composite PK. References KYC.Questions. Which question was answered. (Tier 1 - upstream wiki, UserApiDB.KYC.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_customeranswers ALTER COLUMN AnswerId COMMENT 'Part of composite PK. References KYC.Answers. Which answer was selected. Dynamic data masking applied. (Tier 1 - upstream wiki, UserApiDB.KYC.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_customeranswers ALTER COLUMN OccurredAt COMMENT 'When this answer was submitted. Used for audit trails and FirstUpdated calculation. (Tier 1 - upstream wiki, UserApiDB.KYC.CustomerAnswers)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_customeranswers ALTER COLUMN FreeText COMMENT 'Optional free-text input for answers that support elaboration. (Tier 1 - upstream wiki, UserApiDB.KYC.CustomerAnswers)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
