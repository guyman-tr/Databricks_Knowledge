-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Region
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Region.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_region
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_region (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_region SET TBLPROPERTIES (
    'comment' = 'Lookup table defining geographic regions for country grouping, regulatory bucketing, marketing segmentation, and default currency assignment. Source: etoro.Dictionary.Region on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Region.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_region SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Region',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_region ALTER COLUMN RegionID COMMENT 'Primary key identifying the geographic region. 0=Unknown, 1=N. America, 2=S. America, 3=Europe, 4=Asia, 5=Africa, 6=Oceania, 7=Canada, 8=UK, 9-25=country-specific regions. Referenced by Dictionary.Country.RegionID. See Region. (Dictionary.Region) (Tier 1 - upstream wiki, etoro.Dictionary.Region)';
ALTER TABLE main.general.bronze_etoro_dictionary_region ALTER COLUMN Name COMMENT 'Human-readable region name. UNIQUE constraint. Used in marketing dashboards, analytics, and user segmentation. (Tier 1 - upstream wiki, etoro.Dictionary.Region)';
ALTER TABLE main.general.bronze_etoro_dictionary_region ALTER COLUMN DefaultCurrency COMMENT 'FK to Dictionary.Currency — the default trading currency for new users in this region. 1=USD, 2=EUR, 3=GBP, 5=AUD, 7=CAD. Applied during registration to set the user''s account base currency. (Tier 1 - upstream wiki, etoro.Dictionary.Region)';

