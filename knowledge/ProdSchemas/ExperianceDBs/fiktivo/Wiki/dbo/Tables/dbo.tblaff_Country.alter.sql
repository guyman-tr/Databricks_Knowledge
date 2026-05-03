-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_Country
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Country.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_country
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_country (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_country SET TBLPROPERTIES (
    'comment' = 'Country reference table mapping each country to its default affiliate group, marketing region, and affiliate type for geo-targeted affiliate configuration. Source: fiktivo.dbo.tblaff_Country on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Country.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_country SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_Country',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_country ALTER COLUMN CountryID COMMENT 'Primary key. ISO 3166-1 numeric country code. 0 = "Not available" sentinel. Referenced by tblaff_Affiliates.CountryID (explicit FK). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Country)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_country ALTER COLUMN Abbreviation COMMENT 'ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Used for display and API integration. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Country)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_country ALTER COLUMN Name COMMENT 'Country display name (e.g., "United States", "United Kingdom"). MASKED (dynamic data masking). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Country)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_country ALTER COLUMN AffiliatesGroupsID COMMENT 'Default affiliate group for this country. References dbo.tblaff_AffiliatesGroups. NULL = no country-level group default. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Country)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_country ALTER COLUMN MarketingRegionID COMMENT 'FK to Dictionary.MarketingRegion. Groups country into marketing territory. See Marketing Region: 0=Unknown, 1=Arabic, ..., 15=USA. Default 0 (Unknown). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Country)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_country ALTER COLUMN AffiliateTypeID COMMENT 'Default commission plan for affiliates from this country. References dbo.tblaff_AffiliateTypes. NULL = use group-level default plan. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Country)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
