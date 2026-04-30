-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Objects
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Objects.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_objects
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_objects (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_objects SET TBLPROPERTIES (
    'comment' = 'Registry of application-level objects and operations that are subject to permission checks, mapping BackOffice tools (Configuration Manager, DealingReportGenerator, CEP UI) to their controllable operations. Source: etoro.Dictionary.Objects on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Objects.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_objects SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Objects',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_objects ALTER COLUMN ObjectID COMMENT 'Unique identifier for the permissioned object. Values 1-28. Referenced by Internal.CheckSinglePermission for authorization checks. (Tier 1 - upstream wiki, etoro.Dictionary.Objects)';
ALTER TABLE main.general.bronze_etoro_dictionary_objects ALTER COLUMN AppName COMMENT 'Parent application name: "Configuration Manager", "ConfigurationManager" (alternate casing), "DealingReportGenerator", "CEP UI". Used with ObjectName as a composite key for permission lookups. (Tier 1 - upstream wiki, etoro.Dictionary.Objects)';
ALTER TABLE main.general.bronze_etoro_dictionary_objects ALTER COLUMN ObjectName COMMENT 'Specific object/operation within the application (e.g., "Spreads", "HedgeCostReport", "CEPOperations"). Combined with AppName to uniquely identify a permission target. (Tier 1 - upstream wiki, etoro.Dictionary.Objects)';
ALTER TABLE main.general.bronze_etoro_dictionary_objects ALTER COLUMN Description COMMENT 'Human-readable description of what the object controls. Some entries use the ObjectName as the description; others provide more detailed context like "Bulk open operation for all whitelisted cids". (Tier 1 - upstream wiki, etoro.Dictionary.Objects)';

