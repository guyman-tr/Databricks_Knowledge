-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ConditionOperators
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ConditionOperators.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_conditionoperators
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_conditionoperators (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_conditionoperators SET TBLPROPERTIES (
    'comment' = 'Temporal lookup table defining the 8 comparison operators used in CEP (Complex Event Processing) rule conditions — Equal, NotEqual, Greater Than, Smaller Than, Contains, and their variants. Source: etoro.Dictionary.ConditionOperators on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ConditionOperators.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_conditionoperators SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ConditionOperators',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_conditionoperators ALTER COLUMN OperatorID COMMENT 'Primary key identifying the comparison operator. Values 1-8. Referenced by CEP.Conditions to define how a property value is compared against a threshold in rule evaluation. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionOperators)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionoperators ALTER COLUMN Name COMMENT 'Operator label (e.g., ''Equal'', ''Greater Than'', ''Contains''). Used in the CEP configuration UI to display available operators and in rule evaluation to determine comparison logic. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionOperators)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionoperators ALTER COLUMN DbLoginName COMMENT 'Computed column — returns the current SQL Server login name at query time. Audit trail column showing which database account is reading the data. Not persisted. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionOperators)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionoperators ALTER COLUMN AppLoginName COMMENT 'Computed column — returns the application-layer context info set via SET CONTEXT_INFO. Identifies which application service is accessing the data. Returns NULL when no context info is set. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionOperators)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionoperators ALTER COLUMN SysStartTime COMMENT 'System-versioned temporal start timestamp. Records when this row version became current. Used by temporal queries (FOR SYSTEM_TIME) to retrieve historical operator definitions. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionOperators)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionoperators ALTER COLUMN SysEndTime COMMENT 'System-versioned temporal end timestamp. Value ''9999-12-31'' indicates the row is currently active. When a row is updated or deleted, this gets set to the modification time and the row moves to History.ConditionOperators. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionOperators)';

