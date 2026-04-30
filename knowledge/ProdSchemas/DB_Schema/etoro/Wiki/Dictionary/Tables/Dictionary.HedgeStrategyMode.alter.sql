-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HedgeStrategyMode
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeStrategyMode.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_hedgestrategymode
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_hedgestrategymode (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_hedgestrategymode SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 hedging strategy modes for eToro''s internal risk management. Source: etoro.Dictionary.HedgeStrategyMode on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeStrategyMode.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_hedgestrategymode SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HedgeStrategyMode',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_hedgestrategymode ALTER COLUMN HedgeStrategyModeID COMMENT 'Primary key. 1=Auto (automated hedging), 2=Manual (risk team managed), 3=Disabled (no hedging). See Hedge Strategy Mode. (Dictionary.HedgeStrategyMode) (Tier 1 - upstream wiki, etoro.Dictionary.HedgeStrategyMode)';
ALTER TABLE main.general.bronze_etoro_dictionary_hedgestrategymode ALTER COLUMN Description COMMENT 'Human-readable strategy description. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeStrategyMode)';

