-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.PlanEventCode
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanEventCode.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_recurringinvestment_dictionary_planeventcode
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_recurringinvestment_dictionary_planeventcode (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planeventcode SET TBLPROPERTIES (
    'comment' = 'Comprehensive event classification table for recurring investment plan lifecycle events, organized by numeric ranges covering successes, failures, cancellations, eligibility, compliance, and position errors. Source: RecurringInvestment.Dictionary.PlanEventCode on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanEventCode.md).'
);

ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planeventcode SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'PlanEventCode',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planeventcode ALTER COLUMN ID COMMENT 'Unique numeric event code. Range-based: 100s=success, 200s=deposit fail, 300s=cancel, 400s=creation fail, 500s=order issues, 600s=position issues, 700s=user actions, 800s=eligibility, 900s=instrument, 1000s=validation, 1100s=compliance, 1200+=position errors. See Plan Event Code. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.PlanEventCode)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planeventcode ALTER COLUMN EventName COMMENT 'Human-readable event name describing the specific lifecycle event. Phase suffixes (_Phase02, _Phase05) indicate detection phase. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.PlanEventCode)';

