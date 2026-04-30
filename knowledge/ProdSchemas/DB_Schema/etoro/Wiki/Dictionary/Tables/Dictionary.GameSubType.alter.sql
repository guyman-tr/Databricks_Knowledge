-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.GameSubType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GameSubType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_gamesubtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_gamesubtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_gamesubtype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 11 trading game/activity sub-type categories — from legacy social games (Race, Slot, Poker) to the current eToro Trading mode — used to group related game types. Source: etoro.Dictionary.GameSubType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GameSubType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_gamesubtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'GameSubType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_gamesubtype ALTER COLUMN GameSubTypeID COMMENT 'Primary key identifying the game sub-type category. 0=None, 1=Race, 2=Slot, 3=Poker, 4=Globe Trader, 5=Trade Box, 6=Rope Game, 7=VS USD, 8=IB Trade, 9=Forex Charts, 10=eToro Trading. Referenced by Dictionary.GameType via FK to group game variants into categories. (Tier 1 - upstream wiki, etoro.Dictionary.GameSubType)';
ALTER TABLE main.general.bronze_etoro_dictionary_gamesubtype ALTER COLUMN Name COMMENT 'Unique human-readable label for the sub-type category. Fixed-width char(50). Used in reporting, history views, and BackOffice for classifying trading activities. Enforced unique via DGST_NAME index. (Tier 1 - upstream wiki, etoro.Dictionary.GameSubType)';

