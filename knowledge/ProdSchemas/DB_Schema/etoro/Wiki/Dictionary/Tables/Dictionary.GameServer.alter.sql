-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.GameServer
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GameServer.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_gameserver
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_gameserver (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_gameserver SET TBLPROPERTIES (
    'comment' = 'Configuration table defining the trading/game server instances - their network addresses, server types, and online status - used for server routing and championship/game platform management. Source: etoro.Dictionary.GameServer on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GameServer.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_gameserver SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'GameServer',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_gameserver ALTER COLUMN GameServerID COMMENT 'Primary key identifying the server instance. 0=Unknown (fallback). Referenced by Championship.Championship, Game.ForexGame, and History tables to record which server hosted a trading session or competition. (Tier 1 - upstream wiki, etoro.Dictionary.GameServer)';
ALTER TABLE main.general.bronze_etoro_dictionary_gameserver ALTER COLUMN ServerTypeID COMMENT 'FK to Dictionary.ServerType classifying the server''s operational role. Defaults to 0 (Unknown). Determines what type of trading/game operations this server handles. (Tier 1 - upstream wiki, etoro.Dictionary.GameServer)';
ALTER TABLE main.general.bronze_etoro_dictionary_gameserver ALTER COLUMN Name COMMENT 'Unique human-readable server name (e.g., "GAME1"). Fixed-width char(50). Used in server management, monitoring, and audit logs. Enforced unique via DGMS_NAME index. (Tier 1 - upstream wiki, etoro.Dictionary.GameServer)';
ALTER TABLE main.general.bronze_etoro_dictionary_gameserver ALTER COLUMN Port COMMENT 'Network port for client connections to this server. Defaults to 6010 - the standard eToro trading server port. Override per server when non-standard ports are needed. (Tier 1 - upstream wiki, etoro.Dictionary.GameServer)';
ALTER TABLE main.general.bronze_etoro_dictionary_gameserver ALTER COLUMN IP COMMENT 'IPv4 address of the server on the internal network. Used for routing trading connections. The "Unknown" server uses 127.0.0.1 (loopback) as a safe fallback. (Tier 1 - upstream wiki, etoro.Dictionary.GameServer)';
ALTER TABLE main.general.bronze_etoro_dictionary_gameserver ALTER COLUMN IsOnline COMMENT 'Server availability flag. 1=online and accepting connections, 0=offline or decommissioned. Used by routing logic to exclude offline servers from active service. The Unknown server (ID 0) is permanently offline. (Tier 1 - upstream wiki, etoro.Dictionary.GameServer)';
ALTER TABLE main.general.bronze_etoro_dictionary_gameserver ALTER COLUMN Passport COMMENT 'SQL Server rowversion/timestamp column for optimistic concurrency control. Automatically updated on each row modification. Named "Passport" as a legacy convention. (Tier 1 - upstream wiki, etoro.Dictionary.GameServer)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
