-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CEP_LOG_CompoundPropertyToRule
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_CompoundPropertyToRule.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_cep_log_compoundpropertytorule
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_cep_log_compoundpropertytorule (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundpropertytorule SET TBLPROPERTIES (
    'comment' = 'Trigger-based audit log capturing previous versions of compound property-to-rule assignments in the CEP rules engine; records which compound properties were attached to which rules and the expected value at time of change. Source: etoro.History.CEP_LOG_CompoundPropertyToRule on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_CompoundPropertyToRule.md).'
);

ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundpropertytorule SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CEP_LOG_CompoundPropertyToRule',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundpropertytorule ALTER COLUMN RuleID COMMENT 'The CEP rule this compound property was assigned to. References CEP.Rules (RuleID). Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundpropertytorule ALTER COLUMN CompoundPropertyID COMMENT 'The compound property (named condition group) assigned to the rule. References CEP.CompoundProperties (CompoundPropertyID). Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundpropertytorule ALTER COLUMN Value COMMENT 'Expected evaluation outcome of the compound property. True = the compound property must evaluate to true for rule activation; False = must evaluate to false (logical negation). Nullable. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundpropertytorule ALTER COLUMN ValidFrom COMMENT 'Timestamp when this assignment version became active. Copied from parent row. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundPropertyToRule)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundpropertytorule ALTER COLUMN ValidTo COMMENT 'Timestamp when this assignment was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundPropertyToRule)';

