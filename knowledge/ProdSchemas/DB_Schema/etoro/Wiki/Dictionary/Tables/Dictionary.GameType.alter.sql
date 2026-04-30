-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.GameType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GameType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_gametype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_gametype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_gametype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 14 specific trading game/activity types — from legacy social games (Horse Race, Slot, Poker) to the current eToro Trading mode — each classified under a parent sub-type category. Source: etoro.Dictionary.GameType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GameType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_gametype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'GameType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_gametype ALTER COLUMN GameTypeID COMMENT 'Primary key identifying the specific game/trading type. Key values: 0=NULL (fallback), 34=eToro Trading (current production). Legacy: 1=Horse Race, 2=Car Race, 3=Forex Marathon, 4=Dollar Trend, 11=Slot, 21=Poker, 31=Globe Trader, 32=IB Trades, 33=Trade Box, 41=Race Pro, 51/52=Forex Charts. Referenced by History.ForexResult, Championship.Championship, and multiple history views/procedures. (Tier 1 - upstream wiki, etoro.Dictionary.GameType)';
ALTER TABLE main.general.bronze_etoro_dictionary_gametype ALTER COLUMN GameSubTypeID COMMENT 'FK to Dictionary.GameSubType classifying this game type under a parent category. 0=None, 1=Race, 2=Slot, 3=Poker, 4=Globe Trader, 5=Trade Box, 6=Rope Game, 7=VS USD, 8=IB Trade, 9=Forex Charts, 10=eToro Trading. Groups related game variants together. (Tier 1 - upstream wiki, etoro.Dictionary.GameType)';
ALTER TABLE main.general.bronze_etoro_dictionary_gametype ALTER COLUMN Name COMMENT 'Human-readable label for the game type. Fixed-width char(50). Used in history views, closed position reports, and BackOffice for display. Describes the specific trading activity format. (Tier 1 - upstream wiki, etoro.Dictionary.GameType)';

