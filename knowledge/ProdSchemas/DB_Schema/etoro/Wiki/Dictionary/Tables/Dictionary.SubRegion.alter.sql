-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.SubRegion
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.SubRegion.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_subregion
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_subregion (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_subregion SET TBLPROPERTIES (
    'comment' = 'Maps provinces/sub-regions within countries to their parent region for granular geographic classification of customers. Source: etoro.Dictionary.SubRegion on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.SubRegion.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_subregion SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'SubRegion',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_subregion ALTER COLUMN SubRegionID COMMENT 'Auto-incrementing primary key identifying the sub-region/province. Referenced by Customer.Address, Customer.CustomerStatic, History.Customer. (Tier 1 - upstream wiki, etoro.Dictionary.SubRegion)';
ALTER TABLE main.general.bronze_etoro_dictionary_subregion ALTER COLUMN CountryID COMMENT 'FK to Dictionary.Country.CountryID. Currently all rows = 102 (Italy). Determines which country this sub-region belongs to. (Tier 1 - upstream wiki, etoro.Dictionary.SubRegion)';
ALTER TABLE main.general.bronze_etoro_dictionary_subregion ALTER COLUMN RegionID COMMENT 'FK to Dictionary.RegionByIP.RegionByIP_ID. Maps province to its parent IP-based region. Multiple provinces share the same region (e.g., all Sicilian provinces → RegionID 1421). (Tier 1 - upstream wiki, etoro.Dictionary.SubRegion)';
ALTER TABLE main.general.bronze_etoro_dictionary_subregion ALTER COLUMN ShortName COMMENT 'Province abbreviation code (e.g., "MI" for Milan, "RM" for Rome). Part of unique index with CountryID and RegionID. Standard Italian province codes. (Tier 1 - upstream wiki, etoro.Dictionary.SubRegion)';
ALTER TABLE main.general.bronze_etoro_dictionary_subregion ALTER COLUMN Name COMMENT 'Full province name (e.g., "Milan", "Rome", "Florence"). Nullable but populated for all current rows. Unicode-enabled for international names. (Tier 1 - upstream wiki, etoro.Dictionary.SubRegion)';

