-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CandleTimeframes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CandleTimeframes.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_candletimeframes
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_candletimeframes (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_candletimeframes SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 9 candlestick chart time intervals - from 1 minute to 1 week - used for price chart display and candle data aggregation. Source: etoro.Dictionary.CandleTimeframes on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CandleTimeframes.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_candletimeframes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CandleTimeframes',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_candletimeframes ALTER COLUMN Id COMMENT 'Primary key identifying the timeframe. Values 1-9. Referenced by Trade.CandleGroupToIntervals.TimeframeID (FK) to map which timeframes are available per instrument group. (Tier 1 - upstream wiki, etoro.Dictionary.CandleTimeframes)';
ALTER TABLE main.general.bronze_etoro_dictionary_candletimeframes ALTER COLUMN Name COMMENT 'PascalCase name of the timeframe (e.g., ''OneMinute'', ''FourHours'', ''OneWeek''). Used by the charting UI as a programmatic key for timeframe selection. Nullable but all 9 production rows have values. (Tier 1 - upstream wiki, etoro.Dictionary.CandleTimeframes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
