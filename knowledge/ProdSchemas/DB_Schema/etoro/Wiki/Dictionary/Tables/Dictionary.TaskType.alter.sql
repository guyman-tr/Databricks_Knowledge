-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.TaskType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TaskType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_tasktype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_tasktype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_tasktype SET TBLPROPERTIES (
    'comment' = 'Classifies BackOffice tasks by department/function for workflow routing and tracking. Source: etoro.Dictionary.TaskType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TaskType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_tasktype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'TaskType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_tasktype ALTER COLUMN TaskTypeID COMMENT 'Primary key identifying the task category. 1=Sales, 2=Support, 3=Risk, 4=Withdraw. Referenced by BackOffice.Task and History.Task. (Tier 1 - upstream wiki, etoro.Dictionary.TaskType)';
ALTER TABLE main.general.bronze_etoro_dictionary_tasktype ALTER COLUMN Name COMMENT 'Unique functional area label. Enforced unique by DTTP_NAME index. (Tier 1 - upstream wiki, etoro.Dictionary.TaskType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
