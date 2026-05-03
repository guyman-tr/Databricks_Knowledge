-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.FeeDefinition
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_feedefinition
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_feedefinition (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_feedefinition SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the fee billing frequency categories - No Fee, Daily Fee, or Weekly Fee - applied to trading positions. Source: etoro.Dictionary.FeeDefinition on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_feedefinition SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'FeeDefinition',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_feedefinition ALTER COLUMN FeeID COMMENT 'Fee billing frequency: 0=No Fee (exempt from overnight charges), 1=Daily Fee (charged each trading day), 2=Weekly Fee (charged once per week). Referenced by Trade.InstrumentMetaData.FeeID and Trade.ExchangeInstrumentFeeDefinition. (Tier 1 - upstream wiki, etoro.Dictionary.FeeDefinition)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_feedefinition ALTER COLUMN FeeDescription COMMENT 'Human-readable fee frequency label: "No Fee", "Daily Fee", "Weekly Fee". Used in instrument configuration UIs and reporting. (Tier 1 - upstream wiki, etoro.Dictionary.FeeDefinition)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
