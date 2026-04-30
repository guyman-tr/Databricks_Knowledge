-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.PlanType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanType.md
-- Layer: bronze
-- UC Target: main.experience.bronze_recurringinvestment_dictionary_plantype
-- =============================================================================

-- ---- UC Target: main.experience.bronze_recurringinvestment_dictionary_plantype (business_group=experience) ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_plantype SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying the fundamental nature of a recurring investment plan - direct instrument investment or copy trading. Source: RecurringInvestment.Dictionary.PlanType on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanType.md).'
);

ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_plantype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'PlanType',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_plantype ALTER COLUMN ID COMMENT 'Unique numeric identifier for the plan type. 1=Instrument (direct investment), 2=Copy (copy trading). See Plan Type. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.PlanType)';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_plantype ALTER COLUMN Name COMMENT 'Human-readable label for the plan investment strategy type. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.PlanType)';

