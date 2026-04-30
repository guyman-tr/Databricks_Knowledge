-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.HighLevelDepositStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.HighLevelDepositStatus.md
-- Layer: bronze
-- UC Target: main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus
-- =============================================================================

-- ---- UC Target: main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus (business_group=experience) ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying recurring deposit outcomes at a high level - success, soft decline (retryable), or hard decline (permanent). Source: RecurringInvestment.Dictionary.HighLevelDepositStatus on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.HighLevelDepositStatus.md).'
);

ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'HighLevelDepositStatus',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus ALTER COLUMN ID COMMENT 'Unique numeric identifier for the high-level deposit status. 1=Success, 2=SoftDecline, 3=HardDecline. See High Level Deposit Status. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.HighLevelDepositStatus)';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus ALTER COLUMN HighLevelDepositStatus COMMENT 'Human-readable label describing the deposit outcome category. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.HighLevelDepositStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-30 08:48:09 UTC
-- Bronze deploy: RecurringInvestment batch 1
-- ====================
