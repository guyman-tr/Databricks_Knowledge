-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.FeatureThreshold
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeatureThreshold.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_featurethreshold
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_featurethreshold (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_featurethreshold SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the five threshold severity tiers (Minimum through Maximum) used to classify trading execution feature sensitivity levels per instrument. Source: etoro.Dictionary.FeatureThreshold on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeatureThreshold.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_featurethreshold SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'FeatureThreshold',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_featurethreshold ALTER COLUMN ThresholdID COMMENT 'Primary key identifying the threshold severity tier. Values are spaced at intervals of 5 (0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum) to allow future intermediate tiers. Referenced by Trade.FeatureThresholdValues and Trade.ActiveFeatureThreshold to classify execution feature sensitivity levels per instrument. (Tier 1 - upstream wiki, etoro.Dictionary.FeatureThreshold)';
ALTER TABLE main.general.bronze_etoro_dictionary_featurethreshold ALTER COLUMN Name COMMENT 'Human-readable label for the threshold tier (Minimum/Low/Medium/High/Maximum). Used in the Configuration Manager UI for display and in audit logs when threshold levels are changed by the dealing team. (Tier 1 - upstream wiki, etoro.Dictionary.FeatureThreshold)';

