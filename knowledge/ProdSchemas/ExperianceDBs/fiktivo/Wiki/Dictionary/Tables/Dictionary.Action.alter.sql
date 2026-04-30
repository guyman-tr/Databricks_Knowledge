-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.Dictionary.Action
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.Action.md
-- Layer: bronze
-- UC Target: main.general.bronze_fiktivo_dictionary_action
-- =============================================================================

-- ---- UC Target: main.general.bronze_fiktivo_dictionary_action (business_group=general) ----
ALTER TABLE main.general.bronze_fiktivo_dictionary_action SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying the type of data modification recorded in audit/change logs - Insert, Update, or Delete. Source: fiktivo.Dictionary.Action on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.Action.md).'
);

ALTER TABLE main.general.bronze_fiktivo_dictionary_action SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'Dictionary',
    'source_table' = 'Action',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_fiktivo_dictionary_action ALTER COLUMN ActionID COMMENT 'Primary key identifying the audit action type. Values: 1=Insert, 2=Update, 3=Delete. See Action for full business definitions. Referenced by dbo.AuditLog.ActionID. (Tier 1 - upstream wiki, fiktivo.Dictionary.Action)';
ALTER TABLE main.general.bronze_fiktivo_dictionary_action ALTER COLUMN Name COMMENT 'Human-readable label for the action type. Used in audit log displays and admin reports. Standard DML operation names: "Insert", "Update", "Delete". (Tier 1 - upstream wiki, fiktivo.Dictionary.Action)';

