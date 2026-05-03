-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.Conditions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Conditions.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_conditions
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_conditions (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_conditions SET TBLPROPERTIES (
    'comment' = 'Temporal HISTORY_TABLE for CEP.Conditions - stores 9,558 versioned row snapshots of CEP rule conditions as they are created, modified, and deleted; actively written to as CEP rules evolve. Source: etoro.History.Conditions on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Conditions.md).'
);

ALTER TABLE main.general.bronze_etoro_history_conditions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'Conditions',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN ConditionID COMMENT 'ID of the CEP condition being versioned. Matches CEP.Conditions.ConditionID. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN OperatorID COMMENT 'Comparison operator for this condition. FK to Dictionary.ConditionOperators. E.g., 1=equals. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN Value COMMENT 'The threshold or target value for the condition. Varchar to accommodate numeric, string, and list values. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN PropertyID COMMENT 'The property being tested. FK to Dictionary.ConditionProperties. E.g., 2=some instrument-related property. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN ValidFrom COMMENT 'Application-level effective date for this condition. Business logic field, distinct from SQL Server''s SysStartTime. Set by the CEP UI/service layer. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN DbLoginName COMMENT 'SQL Server login at time of change. Audit column. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN AppLoginName COMMENT 'Application login from context_info(). Audit column. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN SysStartTime COMMENT 'When this version became current in CEP.Conditions. Set by SQL Server temporal engine. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN SysEndTime COMMENT 'When this version was superseded. Set by SQL Server temporal engine. (Tier 1 - upstream wiki, etoro.History.Conditions)';
ALTER TABLE main.general.bronze_etoro_history_conditions ALTER COLUMN HostName COMMENT 'Server hostname that performed the change. Additional audit field beyond DbLoginName/AppLoginName. (Tier 1 - upstream wiki, etoro.History.Conditions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
