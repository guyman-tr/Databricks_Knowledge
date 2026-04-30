-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Feature
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Feature.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_feature
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_feature (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_feature SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the types of trading execution features whose thresholds are configured per instrument — price filters, execution delays, volatility limits, and staleness timeouts. Source: etoro.Dictionary.Feature on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Feature.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_feature SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Feature',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_feature ALTER COLUMN FeatureID COMMENT 'Primary key identifying the execution feature type. 1=Price Filter (MS), 2=Execution Delay (MS), 3=Rate Volatility (Pip), 4=Inactivity Timeout (MS), 5=Limit Execution (Pip), 6=Rate Volatility (Percentage), 7=Price Stale timeout (MS). Referenced by Trade.ActiveFeatureThreshold and Trade.FeatureThresholdValues to link threshold values to specific execution features per instrument. (Tier 1 - upstream wiki, etoro.Dictionary.Feature)';
ALTER TABLE main.general.bronze_etoro_dictionary_feature ALTER COLUMN Name COMMENT 'Human-readable label for the feature including its unit of measurement in parentheses (MS=milliseconds, Pip=price pips, Percentage). Used in the Configuration Manager UI and audit logs. Not a code-level identifier — FeatureID is used in all programmatic references. (Tier 1 - upstream wiki, etoro.Dictionary.Feature)';

