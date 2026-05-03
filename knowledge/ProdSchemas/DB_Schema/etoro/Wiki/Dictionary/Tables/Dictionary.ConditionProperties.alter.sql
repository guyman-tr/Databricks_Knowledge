-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ConditionProperties
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ConditionProperties.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_conditionproperties
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_conditionproperties (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_conditionproperties SET TBLPROPERTIES (
    'comment' = 'Temporal lookup table defining the 27 tradeable properties that can be evaluated in CEP (Complex Event Processing) rule conditions - covering instrument attributes, customer attributes, position details, and hedge parameters. Source: etoro.Dictionary.ConditionProperties on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ConditionProperties.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_conditionproperties SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ConditionProperties',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_conditionproperties ALTER COLUMN PropertyID COMMENT 'Primary key identifying the condition property. Values 1-27 (not contiguous - ID 3 is missing). Referenced by CEP.Conditions and CEP.PropertyToRuleType to define which data field a rule condition evaluates. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionProperties)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionproperties ALTER COLUMN Name COMMENT 'Property name matching a field in the trading data model (e.g., ''InstrumentType'', ''Leverage'', ''CID'', ''SettlementType''). Used by the CEP engine to dynamically resolve which data field to evaluate at runtime. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionProperties)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionproperties ALTER COLUMN DbLoginName COMMENT 'Computed column - returns the current SQL Server login name at query time. Audit trail for data access tracking. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionProperties)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionproperties ALTER COLUMN AppLoginName COMMENT 'Computed column - returns the application-layer context info. Identifies which service is accessing the data. Returns NULL when no context info is set. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionProperties)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionproperties ALTER COLUMN SysStartTime COMMENT 'System-versioned temporal start timestamp. Most original properties show 2021-09-13 (initial population). Recent additions: AccountType (2025-04-02), SettlementType (2025-08-19). (Tier 1 - upstream wiki, etoro.Dictionary.ConditionProperties)';
ALTER TABLE main.general.bronze_etoro_dictionary_conditionproperties ALTER COLUMN SysEndTime COMMENT 'System-versioned temporal end timestamp. ''9999-12-31'' = currently active. Historical versions stored in History.ConditionProperties. (Tier 1 - upstream wiki, etoro.Dictionary.ConditionProperties)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
