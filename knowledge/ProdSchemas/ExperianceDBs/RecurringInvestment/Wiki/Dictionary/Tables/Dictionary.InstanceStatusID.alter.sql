-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.InstanceStatusID
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.InstanceStatusID.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid SET TBLPROPERTIES (
    'comment' = 'Lookup table defining lifecycle states for recurring investment plan instances - from in-progress through success, skip, cancellation, or failure. Source: RecurringInvestment.Dictionary.InstanceStatusID on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.InstanceStatusID.md).'
);

ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'InstanceStatusID',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid ALTER COLUMN ID COMMENT 'Unique numeric identifier for the instance status. 1=Success, 2=Cancelled, 3=Skipped, 4=UserSkipped, 5=InProgress, 6=Technical Issue, 7=Completed without position. See Instance Status. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.InstanceStatusID)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid ALTER COLUMN InstanceStatusID COMMENT 'Human-readable label for the instance lifecycle state. Note: column name matches table name, which is a naming convention anomaly - this is the descriptive label, not a foreign key. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.InstanceStatusID)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-30 08:48:09 UTC
-- Bronze deploy: RecurringInvestment batch 1
-- ====================
