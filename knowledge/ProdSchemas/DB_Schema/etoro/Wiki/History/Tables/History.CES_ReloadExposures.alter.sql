-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CES_ReloadExposures
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CES_ReloadExposures.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_ces_reloadexposures
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_ces_reloadexposures (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_ces_reloadexposures SET TBLPROPERTIES (
    'comment' = 'Audit log for CES (Currency/CEP Exposure Service) exposure reload operations - records who triggered a per-instrument exposure reload and when. Source: etoro.History.CES_ReloadExposures on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CES_ReloadExposures.md).'
);

ALTER TABLE main.general.bronze_etoro_history_ces_reloadexposures SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CES_ReloadExposures',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_ces_reloadexposures ALTER COLUMN ID COMMENT 'Surrogate row ID. IDENTITY seed=1, step=2 (odd-only IDs). No PK constraint - the table is a heap. (Tier 1 - upstream wiki, etoro.History.CES_ReloadExposures)';
ALTER TABLE main.general.bronze_etoro_history_ces_reloadexposures ALTER COLUMN Occurred COMMENT 'UTC timestamp when the exposure reload was logged. Default = GETUTCDATE(). (Tier 1 - upstream wiki, etoro.History.CES_ReloadExposures)';
ALTER TABLE main.general.bronze_etoro_history_ces_reloadexposures ALTER COLUMN DBUserName COMMENT 'SQL Server login name of the session that triggered the reload. Populated via SUSER_NAME() in History.CES_LogReloadExposures. (Tier 1 - upstream wiki, etoro.History.CES_ReloadExposures)';
ALTER TABLE main.general.bronze_etoro_history_ces_reloadexposures ALTER COLUMN AppUserName COMMENT 'Application-level user name passed as a parameter to History.CES_LogReloadExposures. Identifies the system or user that initiated the reload. (Tier 1 - upstream wiki, etoro.History.CES_ReloadExposures)';
ALTER TABLE main.general.bronze_etoro_history_ces_reloadexposures ALTER COLUMN InstrumentID COMMENT 'The financial instrument whose CES exposure data was reloaded. Implicit FK to History.Instrument. NULL if the reload was schema-wide rather than instrument-specific. (Tier 1 - upstream wiki, etoro.History.CES_ReloadExposures)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
