-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.KYC.AnswerThresholds
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.AnswerThresholds.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_kyc_answerthresholds
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_kyc_answerthresholds (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_kyc_answerthresholds SET TBLPROPERTIES (
    'comment' = 'Stores numeric min/max threshold values for KYC answers that represent ranges (e.g., income brackets, experience years). Source: UserApiDB.KYC.AnswerThresholds on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.AnswerThresholds.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_kyc_answerthresholds SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'KYC',
    'source_table' = 'AnswerThresholds',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_kyc_answerthresholds ALTER COLUMN AnswerID COMMENT 'Primary key. FK to KYC.Answers.AnswerId. One threshold record per answer. (Tier 1 - upstream wiki, UserApiDB.KYC.AnswerThresholds)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_answerthresholds ALTER COLUMN MinThreshold COMMENT 'Minimum numeric value for this answer''s range. NULL for open-ended lower bound. (Tier 1 - upstream wiki, UserApiDB.KYC.AnswerThresholds)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_answerthresholds ALTER COLUMN MaxThreshold COMMENT 'Maximum numeric value for this answer''s range. NULL for open-ended upper bound. (Tier 1 - upstream wiki, UserApiDB.KYC.AnswerThresholds)';

