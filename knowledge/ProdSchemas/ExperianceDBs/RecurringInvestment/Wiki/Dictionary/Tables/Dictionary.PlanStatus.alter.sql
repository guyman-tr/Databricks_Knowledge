-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.PlanStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_recurringinvestment_dictionary_planstatus
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_recurringinvestment_dictionary_planstatus (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining lifecycle states for recurring investment plans - from initialization through active execution, cancellation, or stop. Source: RecurringInvestment.Dictionary.PlanStatus on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md).'
);

ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'PlanStatus',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planstatus ALTER COLUMN ID COMMENT 'Unique numeric identifier for the plan status. 0=Initializing (failed creation), 1=Active (only operational status), 2=Cancelled (terminal), 3=Stopped (unused), 4=Invalid (unused). See Plan Status. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.PlanStatus)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planstatus ALTER COLUMN StatusName COMMENT 'Human-readable label for the plan lifecycle state. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.PlanStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-30 08:48:09 UTC
-- Bronze deploy: RecurringInvestment batch 1
-- ====================
