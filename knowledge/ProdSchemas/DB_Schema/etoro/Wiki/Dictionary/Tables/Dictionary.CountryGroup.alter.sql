-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CountryGroup
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryGroup.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_countrygroup
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_countrygroup (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_countrygroup SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 33 country groups used for regulatory, marketing, risk, and feature-gating purposes - from regulatory zones (ESMA, US territories) to marketing regions (Arabic, French, German) to feature flags (CfdRestrictedCountries, ERC20AllowedCountries). Source: etoro.Dictionary.CountryGroup on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryGroup.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_countrygroup SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CountryGroup',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_countrygroup ALTER COLUMN CountryGroupID COMMENT 'Primary key identifying the country group. Values 1-33 (non-contiguous - IDs 9 and 24 are missing). Referenced by Dictionary.CountryToCountryGroup mapping table and dbo.V_Country view. (Tier 1 - upstream wiki, etoro.Dictionary.CountryGroup)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrygroup ALTER COLUMN CountryGroupName COMMENT 'Descriptive name of the group using PascalCase or underscore convention (e.g., ''ESMA_Countries'', ''ERC20AllowedCountries'', ''TR_CASP_countries_eToroSEY''). Used as a programmatic identifier in feature-gating logic and configuration systems. (Tier 1 - upstream wiki, etoro.Dictionary.CountryGroup)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrygroup ALTER COLUMN CFKey COMMENT 'Mapping key to an external Configuration Framework system. Only 13 of 33 groups have a CFKey - groups without one are internal-only and not exposed to centralized configuration. Enforced unique (when not NULL) via filtered unique index Idx_Dictionary_CountryGroup. (Tier 1 - upstream wiki, etoro.Dictionary.CountryGroup)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
