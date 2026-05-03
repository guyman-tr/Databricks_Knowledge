-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.ConditionToCompoundProperty
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ConditionToCompoundProperty.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_conditiontocompoundproperty
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_conditiontocompoundproperty (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty SET TBLPROPERTIES (
    'comment' = 'Temporal HISTORY_TABLE for CEP.ConditionToCompoundProperty - stores 9,513 versioned snapshots of the many-to-many mapping between CEP conditions and compound properties. Source: etoro.History.ConditionToCompoundProperty on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ConditionToCompoundProperty.md).'
);

ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'ConditionToCompoundProperty',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty ALTER COLUMN CompoundPropertyID COMMENT 'ID of the compound property (logical group). Matches CEP.ConditionToCompoundProperty.CompoundPropertyID. FK to CEP.CompoundProperties. (Tier 1 - upstream wiki, etoro.History.ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty ALTER COLUMN ConditionID COMMENT 'ID of the individual condition being assigned to the compound property. FK to CEP.Conditions. (Tier 1 - upstream wiki, etoro.History.ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty ALTER COLUMN ValidFrom COMMENT 'Application-level effective date for this mapping. Business logic field. (Tier 1 - upstream wiki, etoro.History.ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty ALTER COLUMN DbLoginName COMMENT 'SQL Server login at time of change. Audit column. (Tier 1 - upstream wiki, etoro.History.ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty ALTER COLUMN AppLoginName COMMENT 'Application login from context_info(). Audit column. (Tier 1 - upstream wiki, etoro.History.ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty ALTER COLUMN SysStartTime COMMENT 'When this version became current in CEP.ConditionToCompoundProperty. (Tier 1 - upstream wiki, etoro.History.ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_conditiontocompoundproperty ALTER COLUMN SysEndTime COMMENT 'When this version was superseded. (Tier 1 - upstream wiki, etoro.History.ConditionToCompoundProperty)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
