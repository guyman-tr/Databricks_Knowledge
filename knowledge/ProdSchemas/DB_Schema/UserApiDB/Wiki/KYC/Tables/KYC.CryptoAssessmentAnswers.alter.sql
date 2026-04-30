-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.KYC.CryptoAssessmentAnswers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers SET TBLPROPERTIES (
    'comment' = 'Maps KYC answers to crypto assessment categories, marking correctness for the crypto knowledge test. Source: UserApiDB.KYC.CryptoAssessmentAnswers on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md).'
);

ALTER TABLE main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'KYC',
    'source_table' = 'CryptoAssessmentAnswers',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers ALTER COLUMN Id COMMENT 'Primary key. Auto-incrementing. (Tier 1 - upstream wiki, UserApiDB.KYC.CryptoAssessmentAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers ALTER COLUMN AnswerId COMMENT 'FK to KYC.Answers. The answer option. (Tier 1 - upstream wiki, UserApiDB.KYC.CryptoAssessmentAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers ALTER COLUMN IsCorrect COMMENT 'Whether this answer demonstrates correct understanding of the crypto risk. 1=correct, 0=incorrect. (Tier 1 - upstream wiki, UserApiDB.KYC.CryptoAssessmentAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers ALTER COLUMN AnswerCategoryId COMMENT 'FK to Dictionary.CryptoAssessmentAnswerCategory. Risk category (1-7): Complete Loss, Cyber-Risks, Diversification, Regulatory, Liquidity, Technical, Volatility. See Crypto Assessment Answer Category. (Tier 1 - upstream wiki, UserApiDB.KYC.CryptoAssessmentAnswers)';
ALTER TABLE main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers ALTER COLUMN IsEnabled COMMENT 'Whether this answer is currently active in the assessment. Default: 1 (enabled). (Tier 1 - upstream wiki, UserApiDB.KYC.CryptoAssessmentAnswers)';

