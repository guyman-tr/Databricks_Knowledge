-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CEP_LOG_Rules
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_Rules.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_cep_log_rules
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_cep_log_rules (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules SET TBLPROPERTIES (
    'comment' = 'Trigger-based audit log capturing previous versions of CEP rule definitions; each row records a past state of a rule''s type, name, active status, action type, priority, and validity period. Source: etoro.History.CEP_LOG_Rules on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_Rules.md).'
);

ALTER TABLE main.general.bronze_etoro_history_cep_log_rules SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CEP_LOG_Rules',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN RuleID COMMENT 'Identifies the rule that was changed. IDENTITY PK in CEP.Rules. Part of composite PK here. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN RuleTypeID COMMENT 'The type of rule. FK to Dictionary.RuleType in parent table. All observed values are 1 (single rule type in use). (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN Name COMMENT 'Human-readable rule name at time of change. Convention: "HedgingAutomationIntrumentID{N}ToHsId{N}Rule". Note the typo "Intrument" is present in production rule names. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN Description COMMENT 'Optional extended description of the rule''s purpose. Typically NULL for auto-generated hedging rules. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN IsActive COMMENT 'Whether this rule was active (evaluating and triggering) at time of change. Rules can be disabled without deletion. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN HedgeRuleActionTypeID COMMENT 'The action the hedge server takes when this rule fires. Value 1 dominates (97%); values 5, 8, 9, 11, 21, 22 represent other hedge actions like position routing, risk controls, etc. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN Occurred COMMENT 'Timestamp when the rule event was last processed by the CEP engine. Defaults to getutcdate() in parent. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN ValidFrom COMMENT 'Timestamp when this rule version became active. Copied from parent row. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN ValidTo COMMENT 'Timestamp when this rule was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_rules ALTER COLUMN Priority COMMENT 'Rule evaluation priority. Negative values (e.g., -1001) observed for high-specificity routing rules. Lower (more negative) = higher override precedence. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_Rules)';

