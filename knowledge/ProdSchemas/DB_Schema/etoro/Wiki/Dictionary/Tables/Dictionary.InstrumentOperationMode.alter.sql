-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.InstrumentOperationMode
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InstrumentOperationMode.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_dictionary_instrumentoperationmode
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_dictionary_instrumentoperationmode (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_dictionary_instrumentoperationmode SET TBLPROPERTIES (
    'comment' = 'Lookup table defining whether an instrument is managed (active trading operations) or unmanaged (no platform-driven operations) by the trading engine. Source: etoro.Dictionary.InstrumentOperationMode on the etoro production database, ingested via the Generic Pipeline (Snapshot strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InstrumentOperationMode.md).'
);

ALTER TABLE main.dealing.bronze_etoro_dictionary_instrumentoperationmode SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'InstrumentOperationMode',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Snapshot',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_dictionary_instrumentoperationmode ALTER COLUMN ID COMMENT 'Operation mode: 0=ManagedInstrument (full automated operations), 1=UnmanagedInstrument (no automated operations). Referenced by instrument configuration tables to control trading engine behavior. (Tier 1 - upstream wiki, etoro.Dictionary.InstrumentOperationMode)';
ALTER TABLE main.dealing.bronze_etoro_dictionary_instrumentoperationmode ALTER COLUMN Description COMMENT 'Mode label: "ManagedInstrument" or "UnmanagedInstrument". Despite varchar(500) allocation, values are short descriptive labels. (Tier 1 - upstream wiki, etoro.Dictionary.InstrumentOperationMode)';

