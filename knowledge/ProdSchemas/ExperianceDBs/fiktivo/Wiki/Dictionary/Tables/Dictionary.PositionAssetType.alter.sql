-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.Dictionary.PositionAssetType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dictionary_positionassettype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dictionary_positionassettype (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_positionassettype SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying financial instrument asset classes for trading positions, used for commission segmentation and first-position-based affiliate plans. Source: fiktivo.Dictionary.PositionAssetType on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_positionassettype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'Dictionary',
    'source_table' = 'PositionAssetType',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_positionassettype ALTER COLUMN ID COMMENT 'Primary key identifying the asset class. Values: 0=All, 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto, 11=Copy. See Position Asset Type for full definitions. ID=0 serves as a wildcard in filter contexts. (Tier 1 - upstream wiki, fiktivo.Dictionary.PositionAssetType)';
ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_positionassettype ALTER COLUMN Name COMMENT 'Human-readable label for the asset class. Used in commission plan configuration, reporting displays, and admin UIs. (Tier 1 - upstream wiki, fiktivo.Dictionary.PositionAssetType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
