-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CompoundPropertyToRule
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CompoundPropertyToRule.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_compoundpropertytorule
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_compoundpropertytorule (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table for CEP.CompoundPropertyToRule - automatically captures superseded compound-property-to-rule assignments whenever a mapping is changed or deleted. Source: etoro.History.CompoundPropertyToRule on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CompoundPropertyToRule.md).'
);

ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CompoundPropertyToRule',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule ALTER COLUMN RuleID COMMENT 'ID of the CEP rule. Matches CEP.CompoundPropertyToRule.RuleID. Implicit FK to CEP.Rules. (Tier 1 - upstream wiki, etoro.History.CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule ALTER COLUMN CompoundPropertyID COMMENT 'ID of the compound property. Matches CEP.CompoundPropertyToRule.CompoundPropertyID. Implicit FK to CEP.CompoundProperties. (Tier 1 - upstream wiki, etoro.History.CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule ALTER COLUMN Value COMMENT 'Expected boolean value of the compound property for rule evaluation: 1=must be true, 0=must be false. (Tier 1 - upstream wiki, etoro.History.CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule ALTER COLUMN ValidFrom COMMENT 'Application-level timestamp when this mapping version became valid. (Tier 1 - upstream wiki, etoro.History.CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule ALTER COLUMN DbLoginName COMMENT 'SQL Server login that made the change. (Tier 1 - upstream wiki, etoro.History.CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule ALTER COLUMN AppLoginName COMMENT 'Application login from context_info() at change time. (Tier 1 - upstream wiki, etoro.History.CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule ALTER COLUMN SysStartTime COMMENT 'Temporal row start: when this version became current. (Tier 1 - upstream wiki, etoro.History.CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_compoundpropertytorule ALTER COLUMN SysEndTime COMMENT 'Temporal row end: when this version was superseded. Clustered index lead column. (Tier 1 - upstream wiki, etoro.History.CompoundPropertyToRule)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
