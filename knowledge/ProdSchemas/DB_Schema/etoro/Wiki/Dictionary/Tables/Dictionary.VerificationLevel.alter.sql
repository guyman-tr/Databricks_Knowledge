-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.VerificationLevel
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.VerificationLevel.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_verificationlevel
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_verificationlevel (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_verificationlevel SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the four tiers of customer identity verification (Level 0-3) that progressively unlock platform capabilities — from basic registration through full KYC-verified status with complete trading and withdrawal access. Source: etoro.Dictionary.VerificationLevel on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.VerificationLevel.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_verificationlevel SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'VerificationLevel',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_verificationlevel ALTER COLUMN ID COMMENT 'Verification tier identifier: 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Stored on BackOffice.Customer.VerificationLevelID and checked by 60+ procedures to gate trading, withdrawals, and compliance operations. (Tier 1 - upstream wiki, etoro.Dictionary.VerificationLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_verificationlevel ALTER COLUMN Name COMMENT 'Display label for the verification tier: "Level 0" through "Level 3". Used in BackOffice UI, compliance reports, and customer headers. Nullable by DDL but all current values are populated. (Tier 1 - upstream wiki, etoro.Dictionary.VerificationLevel)';

