-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CountryToCountryGroup
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryToCountryGroup.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_countrytocountrygroup
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_countrytocountrygroup (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_countrytocountrygroup SET TBLPROPERTIES (
    'comment' = 'Many-to-many mapping table that assigns countries to named country groups used for regulatory gating, feature eligibility, risk classification, and marketing segmentation. Source: etoro.Dictionary.CountryToCountryGroup on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryToCountryGroup.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_countrytocountrygroup SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CountryToCountryGroup',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_countrytocountrygroup ALTER COLUMN CountryGroupID COMMENT 'The country group this mapping belongs to. FK to Dictionary.CountryGroup. Key groups: 1=ESMA_Countries (34 countries), 4=US_Territories (7 countries), 10=European Union (28), 17=ROW (101), 22=CfdRestrictedCountries (28), 25=SilverClubCountriesNotEligibleForInterest (244), 27=ERC20AllowedCountries (79). See Country Group. (Tier 1 - upstream wiki, etoro.Dictionary.CountryToCountryGroup)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrytocountrygroup ALTER COLUMN CountryID COMMENT 'The country assigned to this group. FK to Dictionary.Country. A country can appear in multiple groups simultaneously. See Country. (Tier 1 - upstream wiki, etoro.Dictionary.CountryToCountryGroup)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
