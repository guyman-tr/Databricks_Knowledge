-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.PositionStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PositionStatus.md
-- Layer: bronze
-- UC Target: main.experience.bronze_recurringinvestment_dictionary_positionstatus
-- =============================================================================

-- ---- UC Target: main.experience.bronze_recurringinvestment_dictionary_positionstatus (business_group=experience) ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_positionstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table tracking the outcome of position creation after a trading order is filled in a recurring investment cycle. Source: RecurringInvestment.Dictionary.PositionStatus on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PositionStatus.md).'
);

ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_positionstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'PositionStatus',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_positionstatus ALTER COLUMN ID COMMENT 'Unique numeric identifier for the position status. 1=Success, 2=Failed, 3=InProgress, 4=Unknown, 6=NoPositionOrderCanceledByUser, 7=NoPositionOrderExpiredOrCanceledByEtoro. Gap at ID=5 suggests a deprecated status. See Position Status. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.PositionStatus)';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_positionstatus ALTER COLUMN PositionStatus COMMENT 'Human-readable label describing the position creation outcome. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.PositionStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-30 08:48:09 UTC
-- Bronze deploy: RecurringInvestment batch 1
-- ====================
