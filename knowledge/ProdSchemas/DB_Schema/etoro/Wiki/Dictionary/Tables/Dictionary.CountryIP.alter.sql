-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CountryIP
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryIP.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_countryip
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_countryip (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_countryip SET TBLPROPERTIES (
    'comment' = 'Large geolocation mapping table (6.8M+ rows) that maps IP address ranges to countries and regions — used for GeoIP resolution during registration, login, and fraud detection. Source: etoro.Dictionary.CountryIP on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryIP.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_countryip SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CountryIP',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_countryip ALTER COLUMN CountryID COMMENT 'References Dictionary.Country. Part of the composite PK. Identifies which country owns this IP range. Used by Internal.GetCountryIDByIP to resolve an IP to a country. (Tier 1 - upstream wiki, etoro.Dictionary.CountryIP)';
ALTER TABLE main.general.bronze_etoro_dictionary_countryip ALTER COLUMN IPFrom COMMENT 'Start of the IP address range as an integer. Part of the composite PK. IPv4 addresses are converted to integers for efficient range comparisons. Used with IPTo for BETWEEN lookups. (Tier 1 - upstream wiki, etoro.Dictionary.CountryIP)';
ALTER TABLE main.general.bronze_etoro_dictionary_countryip ALTER COLUMN IPTo COMMENT 'End of the IP address range as an integer. Part of the composite PK. When IPFrom = IPTo, the range covers exactly one IP address. Used with IPFrom for BETWEEN lookups. (Tier 1 - upstream wiki, etoro.Dictionary.CountryIP)';
ALTER TABLE main.general.bronze_etoro_dictionary_countryip ALTER COLUMN RegionID COMMENT 'Sub-national region within the country. References a region lookup (likely Dictionary.Region or similar). NULL when regional granularity is not available for the IP range. Used by Internal.GetRegionIDByIP for sub-country geolocation. (Tier 1 - upstream wiki, etoro.Dictionary.CountryIP)';

