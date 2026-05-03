-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.KYC.ReasonsForNoTaxID
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.ReasonsForNoTaxID.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_kyc_reasonsfornotaxid
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_kyc_reasonsfornotaxid (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_kyc_reasonsfornotaxid SET TBLPROPERTIES (
    'comment' = 'Lookup table defining valid reasons why a user cannot provide a Tax Identification Number, with optional free-text validation. Source: UserApiDB.KYC.ReasonsForNoTaxID on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.ReasonsForNoTaxID.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_kyc_reasonsfornotaxid SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'KYC',
    'source_table' = 'ReasonsForNoTaxID',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_kyc_reasonsfornotaxid ALTER COLUMN ReasonID COMMENT 'Primary key. CRS-aligned reason code (1-5). (Tier 1 - upstream wiki, UserApiDB.KYC.ReasonsForNoTaxID)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_reasonsfornotaxid ALTER COLUMN Description COMMENT 'User-facing description of the reason, displayed in the KYC form. (Tier 1 - upstream wiki, UserApiDB.KYC.ReasonsForNoTaxID)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_reasonsfornotaxid ALTER COLUMN ValidationExpression COMMENT 'Regex for validating free-text explanation. Only ReasonID=1 has a validation rule (requires explanation). (Tier 1 - upstream wiki, UserApiDB.KYC.ReasonsForNoTaxID)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
