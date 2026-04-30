-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HedgePositionFailSeverity
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgePositionFailSeverity.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_hedgepositionfailseverity
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_hedgepositionfailseverity (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailseverity SET TBLPROPERTIES (
    'comment' = 'Lookup table defining six severity tiers for hedge position failures — from "no problem" through "critical" to "unknown" — used to drive alerting thresholds and escalation paths in the hedge monitoring system. Source: etoro.Dictionary.HedgePositionFailSeverity on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgePositionFailSeverity.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailseverity SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HedgePositionFailSeverity',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailseverity ALTER COLUMN HedgeSeverityTypeID COMMENT 'Primary key identifying the severity tier. 1=None/NoProblem (informational), 2=Low/Warning, 3=Medium (investigate), 4=High (prompt response), 5=Critical (immediate alert), 6=Unknown/TBD (treat as critical). Referenced by Dictionary.HedgePositionFailReason to classify each failure''s severity. (Tier 1 - upstream wiki, etoro.Dictionary.HedgePositionFailSeverity)';
ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailseverity ALTER COLUMN Name COMMENT 'Compound severity label using format "Level_Description". Used in monitoring dashboards and alert configurations. The underscore-separated format provides both the severity level and a brief description. (Tier 1 - upstream wiki, etoro.Dictionary.HedgePositionFailSeverity)';

