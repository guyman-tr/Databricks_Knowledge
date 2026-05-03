-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Leverage
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Leverage.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_leverage
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_leverage (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_leverage SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the available leverage multiplier values (1x to 400x) for trading positions. Source: etoro.Dictionary.Leverage on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Leverage.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_leverage SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Leverage',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_leverage ALTER COLUMN LeverageID COMMENT 'Primary key - internal identifier for the leverage tier. Note: LeverageID does NOT equal the leverage Value (e.g., LeverageID=9 has Value=2, LeverageID=10 has Value=30). Always use Value for business logic. See Leverage. (Dictionary.Leverage) (Tier 1 - upstream wiki, etoro.Dictionary.Leverage)';
ALTER TABLE main.general.bronze_etoro_dictionary_leverage ALTER COLUMN Value COMMENT 'The actual leverage multiplier. UNIQUE constraint. Values: 1, 2, 5, 10, 20, 30, 50, 100, 200, 400. Stored in Trade.PositionTbl.Leverage. Used in margin calculations: RequiredMargin = PositionAmount / LeverageValue. Determines PnL multiplier and overnight fee scaling. (Tier 1 - upstream wiki, etoro.Dictionary.Leverage)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
