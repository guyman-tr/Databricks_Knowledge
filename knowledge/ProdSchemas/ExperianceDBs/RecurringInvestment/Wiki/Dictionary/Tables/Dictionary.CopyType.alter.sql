-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.CopyType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.CopyType.md
-- Layer: bronze
-- UC Target: main.experience.bronze_recurringinvestment_dictionary_copytype
-- =============================================================================

-- ---- UC Target: main.experience.bronze_recurringinvestment_dictionary_copytype (business_group=experience) ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copytype SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying copy trading relationship types for recurring investment plans - direct instrument, Popular Investor, or SmartPortfolio. Source: RecurringInvestment.Dictionary.CopyType on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.CopyType.md).'
);

ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copytype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'CopyType',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copytype ALTER COLUMN ID COMMENT 'Unique numeric identifier for the copy type. 0=None (direct instrument), 1=PI (Popular Investor copy), 4=SmartPortfolio (managed portfolio copy). See Copy Type. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.CopyType)';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copytype ALTER COLUMN Name COMMENT 'Human-readable label for the copy trading relationship type. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.CopyType)';

