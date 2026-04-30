-- =============================================================================
-- Databricks ALTER Script: bronze RecurringManager.Dictionary.Frequency
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.Frequency.md
-- Layer: bronze
-- UC Target: main.billing.bronze_recurringmanager_dictionary_frequency
-- =============================================================================

-- ---- UC Target: main.billing.bronze_recurringmanager_dictionary_frequency (business_group=billing) ----
ALTER TABLE main.billing.bronze_recurringmanager_dictionary_frequency SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the three supported recurring payment cadences: Weekly, BiWeekly, and Monthly. Source: RecurringManager.Dictionary.Frequency on the RecurringManager production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.Frequency.md).'
);

ALTER TABLE main.billing.bronze_recurringmanager_dictionary_frequency SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringManager',
    'source_schema' = 'Dictionary',
    'source_table' = 'Frequency',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_recurringmanager_dictionary_frequency ALTER COLUMN FrequencyID COMMENT 'Primary key identifying the frequency. 1=Weekly, 2=BiWeekly, 3=Monthly. Drives the scheduler''s next-execution-date calculation. See Frequency for full definitions. (Dictionary.Frequency) (Tier 1 - upstream wiki, RecurringManager.Dictionary.Frequency)';
ALTER TABLE main.billing.bronze_recurringmanager_dictionary_frequency ALTER COLUMN Name COMMENT 'Human-readable label for the frequency. Values: "Weekly", "BiWeekly", "Monthly". (Tier 1 - upstream wiki, RecurringManager.Dictionary.Frequency)';

