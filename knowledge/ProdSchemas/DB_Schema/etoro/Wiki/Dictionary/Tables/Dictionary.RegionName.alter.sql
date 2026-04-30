-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RegionName
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RegionName.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_regionname
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_regionname (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_regionname SET TBLPROPERTIES (
    'comment' = 'Reference table mapping country subdivisions (states/provinces/territories) to their full names — covering Australia, Canada, and other countries with regulatory region requirements. Page-compressed. Source: etoro.Dictionary.RegionName on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RegionName.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_regionname SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RegionName',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_regionname ALTER COLUMN CountryID COMMENT 'Part of composite PK. References Dictionary.Country (implicit). Identifies which country this region belongs to. (Tier 1 - upstream wiki, etoro.Dictionary.RegionName)';
ALTER TABLE main.general.bronze_etoro_dictionary_regionname ALTER COLUMN ShortName COMMENT 'Part of composite PK. ISO or country-specific short code for the region (e.g., "NSW", "AB", "CA"). (Tier 1 - upstream wiki, etoro.Dictionary.RegionName)';
ALTER TABLE main.general.bronze_etoro_dictionary_regionname ALTER COLUMN Name COMMENT 'Full human-readable name of the region (e.g., "New South Wales", "Alberta"). Displayed in registration forms and reports. (Tier 1 - upstream wiki, etoro.Dictionary.RegionName)';

