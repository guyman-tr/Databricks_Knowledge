-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.MirrorOrderCreated
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.MirrorOrderCreated.md
-- Layer: bronze
-- UC Target: main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated
-- =============================================================================

-- ---- UC Target: main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated (business_group=experience) ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated SET TBLPROPERTIES (
    'comment' = 'Lookup table providing a boolean flag indicating whether a mirror (copy) order was created for a copy trading plan instance. Source: RecurringInvestment.Dictionary.MirrorOrderCreated on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.MirrorOrderCreated.md).'
);

ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'MirrorOrderCreated',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated ALTER COLUMN ID COMMENT 'Unique numeric identifier. Only value is 1 (TRUE). NULL in referencing tables means no mirror order created. See Mirror Order Created. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.MirrorOrderCreated)';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated ALTER COLUMN Name COMMENT 'Human-readable label. Only value is "TRUE". (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.MirrorOrderCreated)';

