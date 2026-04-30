-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ChampionshipPlayerStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ChampionshipPlayerStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_championshipplayerstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_championshipplayerstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_championshipplayerstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 4 states of a player''s participation in a trading championship — NULL (unset), Registration, Removed, and In Process. Source: etoro.Dictionary.ChampionshipPlayerStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ChampionshipPlayerStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_championshipplayerstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ChampionshipPlayerStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_championshipplayerstatus ALTER COLUMN ChampionshipPlayerStatusID COMMENT 'Primary key identifying the player status. Values 0-3. Referenced by Championship.ChampionshipPlayer table and used in procedures ChampionshipPlayerSetStatus, ChampionshipPlayerAdd, ChampionshipStart, ChampionshipEnd. (Tier 1 - upstream wiki, etoro.Dictionary.ChampionshipPlayerStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_championshipplayerstatus ALTER COLUMN Name COMMENT 'Status label (e.g., ''Registration'', ''Removed'', ''In process''). Fixed-width char(50) — values are right-padded with spaces. Enforced unique via DCPS_NAME index. Used in views for display purposes. (Tier 1 - upstream wiki, etoro.Dictionary.ChampionshipPlayerStatus)';

