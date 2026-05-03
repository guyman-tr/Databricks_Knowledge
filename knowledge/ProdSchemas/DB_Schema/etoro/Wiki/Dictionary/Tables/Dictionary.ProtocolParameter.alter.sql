-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ProtocolParameter
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ProtocolParameter.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_protocolparameter
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_protocolparameter (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_protocolparameter SET TBLPROPERTIES (
    'comment' = 'Configuration table storing 49 named parameters for payment protocols - API keys, URLs, merchant IDs, secrets - used by the billing engine to configure PSP connections. Source: etoro.Dictionary.ProtocolParameter on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ProtocolParameter.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_protocolparameter SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ProtocolParameter',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_protocolparameter ALTER COLUMN ParamID COMMENT 'Primary key. Sequential ID for each parameter definition across all protocols (1-49). (Tier 1 - upstream wiki, etoro.Dictionary.ProtocolParameter)';
ALTER TABLE main.general.bronze_etoro_dictionary_protocolparameter ALTER COLUMN ProtocolID COMMENT 'FK -> Dictionary.Protocol. Groups parameters by payment protocol. Indexed for efficient lookup. (Tier 1 - upstream wiki, etoro.Dictionary.ProtocolParameter)';
ALTER TABLE main.general.bronze_etoro_dictionary_protocolparameter ALTER COLUMN ParamName COMMENT 'Configuration parameter key name (e.g., "apiUsername", "merchantID", "secret"). Used by the billing engine to build PSP-specific connection configurations. (Tier 1 - upstream wiki, etoro.Dictionary.ProtocolParameter)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
