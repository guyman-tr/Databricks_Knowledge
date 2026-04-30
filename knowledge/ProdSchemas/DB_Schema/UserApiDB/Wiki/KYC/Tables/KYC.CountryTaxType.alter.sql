-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.KYC.CountryTaxType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CountryTaxType.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_kyc_countrytaxtype
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_kyc_countrytaxtype (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_kyc_countrytaxtype SET TBLPROPERTIES (
    'comment' = 'Configuration table mapping countries to their accepted tax ID types with validation rules, mask patterns, and requirement levels. Source: UserApiDB.KYC.CountryTaxType on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CountryTaxType.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_kyc_countrytaxtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'KYC',
    'source_table' = 'CountryTaxType',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_kyc_countrytaxtype ALTER COLUMN CountryID COMMENT 'Part of composite PK. Country identifier. Implicit FK to Dictionary.Country. (Tier 1 - upstream wiki, UserApiDB.KYC.CountryTaxType)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_countrytaxtype ALTER COLUMN TaxTypeID COMMENT 'Part of composite PK. Tax ID subtype. Maps to Dictionary.ExtendedUserValueType.ValueTypeID (FieldTypeID=3). (Tier 1 - upstream wiki, UserApiDB.KYC.CountryTaxType)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_countrytaxtype ALTER COLUMN TaxIdRequirmentTypeId COMMENT 'FK to Dictionary.TaxIdRequirmentType. Whether this tax type is Required(1), Not Required(2), or NoTaxRequired(3) for this country. Default: 1 (Required). See Tax ID Requirement Type. (Tier 1 - upstream wiki, UserApiDB.KYC.CountryTaxType)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_countrytaxtype ALTER COLUMN ValidationExpression COMMENT 'Regex pattern for validating the tax ID format. Country-specific (e.g., UK UTR: 10-digit numeric). (Tier 1 - upstream wiki, UserApiDB.KYC.CountryTaxType)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_countrytaxtype ALTER COLUMN MaskExpression COMMENT 'Input mask pattern for the UI tax ID field. Guides user input format. (Tier 1 - upstream wiki, UserApiDB.KYC.CountryTaxType)';
ALTER TABLE main.compliance.bronze_userapidb_kyc_countrytaxtype ALTER COLUMN MinLength COMMENT 'Minimum character length for the tax ID value. (Tier 1 - upstream wiki, UserApiDB.KYC.CountryTaxType)';

