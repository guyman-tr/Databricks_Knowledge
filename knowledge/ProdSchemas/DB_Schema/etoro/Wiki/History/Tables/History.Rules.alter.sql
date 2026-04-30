-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.Rules
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Rules.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_rules
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_rules (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_rules SET TBLPROPERTIES (
    'comment' = 'System-versioned temporal history table for CEP.Rules, recording all past states of the Complex Event Processing hedging automation rules - the configuration that controls how eToro''s automated trading system routes hedge orders between hedge servers. Source: etoro.History.Rules on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Rules.md).'
);

ALTER TABLE main.general.bronze_etoro_history_rules SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'Rules',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN RuleID COMMENT 'Identifier of the original CEP.Rules row (IDENTITY int in source, NOT an identity here). Same RuleID can appear multiple times - one per historical state. Uniquely identifies which rule this history entry belongs to. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN RuleTypeID COMMENT 'Classifies the rule''s routing mechanism. FK to Dictionary.RuleType. Values: 0=NONE, 1=ManualHedgeRouting (operator-configured explicit routing), 2=HierarchyHedgeRouting (computed from hedging hierarchy). Determines how the CEP engine evaluates the rule. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN Name COMMENT 'Human-readable rule identifier. Convention observed: "{RuleContext}{Entity}{RoutingTarget}Rule" (e.g., "HedgingAutomationInstrumentID5ToHsId1Rule"). Supports operator understanding and management UI display. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN Description COMMENT 'Longer explanation of the rule''s purpose and conditions. In sample data, populated as literal "Description" - may be auto-generated or sparsely populated in practice. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN IsActive COMMENT 'Whether the rule participates in CEP engine evaluation. 1=active (evaluated by engine), 0=disabled (skipped). CEP.GetRules reads all rows without IsActive filter - the engine may apply its own active check. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN HedgeRuleActionTypeID COMMENT 'The type of hedging action this rule triggers when matched. No FK defined in DDL; no Dictionary.HedgeRuleActionType table found in SSDT. Value 1 seen in sample data. Likely an embedded enumeration in the CEP application code defining the routing action type. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN Occurred COMMENT 'Original creation timestamp of the rule. Set by default on INSERT. Represents when the rule was first defined, even if it has been modified since (unlike ValidFrom which is reset on updates). (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN ValidFrom COMMENT 'Tracks the most recent modification time of the rule at the application level. Reset to getutcdate() by the CEPRulesUpdate trigger on every UPDATE. Can be used to detect recently-changed rules. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN Priority COMMENT 'Determines evaluation order among active rules. Lower (more negative) values = higher priority. Default=1. Value -1001 in sample = system-level high-priority rule. Rules are applied in ascending order; the first matching rule determines the routing action. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN DbLoginName COMMENT 'Computed in source as suser_name() - SQL Server login that last modified this rule. Stored as a plain value in history. Enables accountability: shows whether a change came from an application service (e.g., "DevTradingSTG") or a human admin. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN AppLoginName COMMENT 'Computed in source as CONVERT(varchar(500), context_info()) - the application-set session context at the time of the change. NULL when context_info() was not set (e.g., direct SQL changes). (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN SysStartTime COMMENT 'UTC instant when this rule state became current in CEP.Rules. Automatically managed by SQL Server temporal system versioning. Nanosecond precision. (Tier 1 - upstream wiki, etoro.History.Rules)';
ALTER TABLE main.general.bronze_etoro_history_rules ALTER COLUMN SysEndTime COMMENT 'UTC instant when this rule state was superseded. Automatically set by SQL Server. Leading key of the clustered index. Default ''9999-12-31'' in source represents the currently active state. (Tier 1 - upstream wiki, etoro.History.Rules)';

