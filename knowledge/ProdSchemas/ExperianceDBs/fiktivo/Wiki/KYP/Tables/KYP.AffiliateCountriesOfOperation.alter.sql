-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.KYP.AffiliateCountriesOfOperation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/KYP/Tables/KYP.AffiliateCountriesOfOperation.md
-- Layer: bronze
-- UC Target: main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation
-- =============================================================================

-- ---- UC Target: main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation (business_group=general) ----
ALTER TABLE main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation SET TBLPROPERTIES (
    'comment' = 'Junction table storing the countries where an affiliate entity operates, as declared during KYP (Know Your Partner) compliance verification. Source: fiktivo.KYP.AffiliateCountriesOfOperation on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/KYP/Tables/KYP.AffiliateCountriesOfOperation.md).'
);

ALTER TABLE main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'KYP',
    'source_table' = 'AffiliateCountriesOfOperation',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation ALTER COLUMN AffiliateID COMMENT 'FK to KYP.Affiliate. Identifies the affiliate entity. Part of composite PK. (Tier 1 - upstream wiki, fiktivo.KYP.AffiliateCountriesOfOperation)';
ALTER TABLE main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation ALTER COLUMN CountryID COMMENT 'FK to dbo.tblaff_Country. Identifies a country where the affiliate operates. Part of composite PK. One row per country per affiliate. (Tier 1 - upstream wiki, fiktivo.KYP.AffiliateCountriesOfOperation)';
ALTER TABLE main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation ALTER COLUMN Trace COMMENT 'Computed audit column: JSON with session/connection details. Inherited pattern from KYP.Affiliate. (Tier 1 - upstream wiki, fiktivo.KYP.AffiliateCountriesOfOperation)';
ALTER TABLE main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation ALTER COLUMN ValidFrom COMMENT 'Temporal versioning row start. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, fiktivo.KYP.AffiliateCountriesOfOperation)';
ALTER TABLE main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation ALTER COLUMN ValidTo COMMENT 'Temporal versioning row end. History in History.KYPAffiliateCountriesOfOperation. (Tier 1 - upstream wiki, fiktivo.KYP.AffiliateCountriesOfOperation)';

