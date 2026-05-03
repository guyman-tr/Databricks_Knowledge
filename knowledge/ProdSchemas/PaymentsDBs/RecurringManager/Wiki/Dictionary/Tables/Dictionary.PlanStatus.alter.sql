-- =============================================================================
-- Databricks ALTER Script: bronze RecurringManager.Dictionary.PlanStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md
-- Layer: bronze
-- UC Target: main.billing.bronze_recurringmanager_dictionary_planstatus
-- =============================================================================

-- ---- UC Target: main.billing.bronze_recurringmanager_dictionary_planstatus (business_group=billing) ----
ALTER TABLE main.billing.bronze_recurringmanager_dictionary_planstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table representing the lifecycle state of a recurring payment plan - the top-level entity governing whether executions continue to be scheduled. Source: RecurringManager.Dictionary.PlanStatus on the RecurringManager production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md).'
);

ALTER TABLE main.billing.bronze_recurringmanager_dictionary_planstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringManager',
    'source_schema' = 'Dictionary',
    'source_table' = 'PlanStatus',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_recurringmanager_dictionary_planstatus ALTER COLUMN PlanStatusID COMMENT 'Primary key identifying the plan lifecycle state. 1=Active (generates executions), 2=Cancelled (permanent, user/BO), 3=Stopped (permanent, system), 4=Invalid (config error), 5=Paused (temporary, reversible). See Plan Status for full definitions. (Dictionary.PlanStatus) (Tier 1 - upstream wiki, RecurringManager.Dictionary.PlanStatus)';
ALTER TABLE main.billing.bronze_recurringmanager_dictionary_planstatus ALTER COLUMN Name COMMENT 'Human-readable label for the plan status. Values: "Active", "Cancelled", "Stopped", "Invalid", "Paused". (Tier 1 - upstream wiki, RecurringManager.Dictionary.PlanStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:40:10 UTC
-- Bronze deploy: RecurringManager batch 1
-- ====================
