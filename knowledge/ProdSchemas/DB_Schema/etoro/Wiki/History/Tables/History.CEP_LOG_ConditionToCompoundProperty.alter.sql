-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CEP_LOG_ConditionToCompoundProperty
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_ConditionToCompoundProperty.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty SET TBLPROPERTIES (
    'comment' = 'Trigger-based audit log capturing previous versions of condition-to-compound-property assignments in the CEP rules engine; records which conditions belonged to which compound properties at the time of change. Source: etoro.History.CEP_LOG_ConditionToCompoundProperty on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_ConditionToCompoundProperty.md).'
);

ALTER TABLE main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CEP_LOG_ConditionToCompoundProperty',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty ALTER COLUMN CompoundPropertyID COMMENT 'The compound property that contained the condition. References CEP.CompoundProperties. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty ALTER COLUMN ConditionID COMMENT 'The condition that was a member of this compound property. References CEP.Conditions. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty ALTER COLUMN ValidFrom COMMENT 'Timestamp when this membership version became active. Copied from parent row. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_ConditionToCompoundProperty)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty ALTER COLUMN ValidTo COMMENT 'Timestamp when this membership was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_ConditionToCompoundProperty)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
