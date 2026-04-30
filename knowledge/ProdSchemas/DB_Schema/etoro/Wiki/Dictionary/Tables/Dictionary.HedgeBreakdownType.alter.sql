-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HedgeBreakdownType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeBreakdownType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_hedgebreakdowntype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_hedgebreakdowntype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_hedgebreakdowntype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the six stages of the hedge execution pipeline — from customer order submission through trade status changes, exposure queries, provider order placement, provider execution, and execution confirmation. Source: etoro.Dictionary.HedgeBreakdownType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeBreakdownType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_hedgebreakdowntype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HedgeBreakdownType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_hedgebreakdowntype ALTER COLUMN ID COMMENT 'Primary key identifying the hedge pipeline stage. 1=Customer order, 2=Trade status change, 3=Exposure query, 4=Order sent to provider, 5=Provider execution, 6=Confirmation received. Stored on History.HedgingBreakdownLog for per-event timing analysis. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeBreakdownType)';
ALTER TABLE main.general.bronze_etoro_dictionary_hedgebreakdowntype ALTER COLUMN HedgeBreakdownName COMMENT 'Descriptive label for the pipeline stage. Explains what happens at each step in business terms. Used in hedge monitoring dashboards and latency analysis reports to label each timing point. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeBreakdownType)';

