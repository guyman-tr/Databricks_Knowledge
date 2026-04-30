-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.LotCount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.LotCount.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_lotcount
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_lotcount (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_lotcount SET TBLPROPERTIES (
    'comment' = 'Defines the universe of valid lot count (unit quantity) values that can be used for trading positions across the platform. Source: etoro.Dictionary.LotCount on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.LotCount.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_lotcount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'LotCount',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_lotcount ALTER COLUMN LotCountID COMMENT 'Primary key and simultaneously the lot count value itself (LotCountID = Value in all rows). Referenced by Trade.PositionTbl, Trade.ProviderInstrumentToLotCount, and 100+ trading procedures as the position unit quantity. Range: 0–10,000. (Tier 1 - upstream wiki, etoro.Dictionary.LotCount)';
ALTER TABLE main.general.bronze_etoro_dictionary_lotcount ALTER COLUMN Value COMMENT 'The numeric lot count value. Always equals LotCountID — a denormalized design where the PK carries the business meaning directly. Represents the number of units (shares/contracts/coins) in a position. (Tier 1 - upstream wiki, etoro.Dictionary.LotCount)';

