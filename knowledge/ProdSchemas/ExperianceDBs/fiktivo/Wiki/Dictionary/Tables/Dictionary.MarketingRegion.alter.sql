-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.Dictionary.MarketingRegion
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.MarketingRegion.md
-- Layer: bronze
-- UC Target: main.experience.bronze_fiktivo_dictionary_marketingregion
-- =============================================================================

-- ---- UC Target: main.experience.bronze_fiktivo_dictionary_marketingregion (business_group=experience) ----
ALTER TABLE main.experience.bronze_fiktivo_dictionary_marketingregion SET TBLPROPERTIES (
    'comment' = 'Lookup table defining geographic and linguistic marketing regions used for segmenting affiliate operations, reporting, and regional commission structures. Source: fiktivo.Dictionary.MarketingRegion on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.MarketingRegion.md).'
);

ALTER TABLE main.experience.bronze_fiktivo_dictionary_marketingregion SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'Dictionary',
    'source_table' = 'MarketingRegion',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_fiktivo_dictionary_marketingregion ALTER COLUMN MarketingRegionID COMMENT 'Primary key identifying the marketing region. Values: 0=Unknown, 1=Arabic, 2=Asia, 3=Australia, 4=Canada, 5=French, 6=German, 7=India, 8=Italian, 9=North Europe, 10=ROE, 11=ROW, 12=South Africa, 13=Spanish & Portuguese, 14=UK, 15=USA. See Marketing Region for full definitions. (Tier 1 - upstream wiki, fiktivo.Dictionary.MarketingRegion)';
ALTER TABLE main.experience.bronze_fiktivo_dictionary_marketingregion ALTER COLUMN Name COMMENT 'Human-readable region label. Subject to UNIQUE constraint (UK_DMR_Name) ensuring no duplicate names. Used in reporting displays, admin filters, and commission plan configuration. (Tier 1 - upstream wiki, fiktivo.Dictionary.MarketingRegion)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
