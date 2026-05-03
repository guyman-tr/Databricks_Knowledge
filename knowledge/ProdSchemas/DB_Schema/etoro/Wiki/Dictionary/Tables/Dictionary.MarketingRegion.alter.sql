-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.MarketingRegion
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MarketingRegion.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_marketingregion
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_marketingregion (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_marketingregion SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 21 geographic marketing segments used for customer acquisition, localization, and regional reporting. Source: etoro.Dictionary.MarketingRegion on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MarketingRegion.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_marketingregion SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'MarketingRegion',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_marketingregion ALTER COLUMN MarketingRegionID COMMENT 'Marketing region identifier (0-99). Referenced by Dictionary.Country.MarketingRegionID. Values: 0=Unknown, 1=Africa, 2=Arabic, 3=Australia, 4=Canada, 5=China, 6=French, 7=German, 8=Israel, 9=Italian, 10=North Europe, 11=Other Asia, 12=ROE, 13=ROW, 14=Russian, 15=South & Central America, 16=Spain, 17=UK, 18=USA, 20=Eastern Europe, 99=eToro. (Tier 1 - upstream wiki, etoro.Dictionary.MarketingRegion)';
ALTER TABLE main.general.bronze_etoro_dictionary_marketingregion ALTER COLUMN Name COMMENT 'Marketing region name. Unique constraint prevents duplicates. Used in BI dashboards, marketing reports, and sales territory assignments. (Tier 1 - upstream wiki, etoro.Dictionary.MarketingRegion)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
