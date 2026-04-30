-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.State
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.State.md
-- Layer: bronze
-- UC Target: main.finance.bronze_usabroker_apex_state
-- =============================================================================

-- ---- UC Target: main.finance.bronze_usabroker_apex_state (business_group=finance) ----
ALTER TABLE main.finance.bronze_usabroker_apex_state SET TBLPROPERTIES (
    'comment' = 'Core state machine table tracking the current workflow step for each customer''s Apex account processing, including account creation, updates, closures, and identity investigations. Source: USABroker.apex.State on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.State.md).'
);

ALTER TABLE main.finance.bronze_usabroker_apex_state SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'State',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_usabroker_apex_state ALTER COLUMN GCID COMMENT 'Global Customer ID. Primary key - one state record per customer. Referenced by StateProcessingData and UserValidationErrors via FK. The core identifier linking all Apex workflow tables. (Tier 1 - upstream wiki, USABroker.apex.State)';
ALTER TABLE main.finance.bronze_usabroker_apex_state ALTER COLUMN ApexStateID COMMENT 'The current state machine step for this customer''s Apex account processing. FK to Dictionary.State. 47 possible values spanning creation (1-10), update (11-19), investigation (20-35), restriction (38-39), closure (41-45), and special approval (46-47) workflows. See State (Apex State) for full definitions. (Dictionary.State) (Tier 1 - upstream wiki, USABroker.apex.State)';
ALTER TABLE main.finance.bronze_usabroker_apex_state ALTER COLUMN Comment COMMENT 'Context text for the current state. Typically contains error messages, investigation details, or processing notes. Truncated to 4000 chars by SaveState before storage. NULL for normal progression states. Contains structured data like "Error = {type}; Code = {code}; Description = {msg}" or investigation reasons. (Tier 1 - upstream wiki, USABroker.apex.State)';
ALTER TABLE main.finance.bronze_usabroker_apex_state ALTER COLUMN BeginTime COMMENT 'System versioning row start time. Records when this state was entered. Essential for tracking state transition timing and detecting stuck states. Part of SYSTEM_TIME period for temporal table History.State. (Tier 1 - upstream wiki, USABroker.apex.State)';
ALTER TABLE main.finance.bronze_usabroker_apex_state ALTER COLUMN EndTime COMMENT 'System versioning row end time. ''9999-12-31'' indicates the current active state. Part of SYSTEM_TIME period. (Tier 1 - upstream wiki, USABroker.apex.State)';

