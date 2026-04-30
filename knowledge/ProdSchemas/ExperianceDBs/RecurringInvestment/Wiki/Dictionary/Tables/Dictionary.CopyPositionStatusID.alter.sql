-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.CopyPositionStatusID
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.CopyPositionStatusID.md
-- Layer: bronze
-- UC Target: main.experience.bronze_recurringinvestment_dictionary_copypositionstatusid
-- =============================================================================

-- ---- UC Target: main.experience.bronze_recurringinvestment_dictionary_copypositionstatusid (business_group=experience) ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copypositionstatusid SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the status of copy trading position creation steps - registration and fund allocation. Source: RecurringInvestment.Dictionary.CopyPositionStatusID on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.CopyPositionStatusID.md).'
);

ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copypositionstatusid SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'CopyPositionStatusID',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copypositionstatusid ALTER COLUMN ID COMMENT 'Unique numeric identifier for the copy position status. 1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed. See Copy Position Status. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.CopyPositionStatusID)';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copypositionstatusid ALTER COLUMN Name COMMENT 'Human-readable label for the copy position status step and outcome. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.CopyPositionStatusID)';

