-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Flow
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Flow.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_flow
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_flow (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_flow SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the three trading execution flow types — Open Trade, Close Trade, and Internal Transfer — used to classify billing and BackOffice operations by their trade lifecycle stage. Source: etoro.Dictionary.Flow on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Flow.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_flow SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Flow',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_flow ALTER COLUMN FlowID COMMENT 'Primary key identifying the execution flow type. 1=Open Trade Execution, 2=Close Trade Execution, 3=Internal Transfer. Referenced by BackOffice and Billing procedures to classify financial operations by their trade lifecycle context. (Tier 1 - upstream wiki, etoro.Dictionary.Flow)';
ALTER TABLE main.general.bronze_etoro_dictionary_flow ALTER COLUMN Description COMMENT 'Human-readable label for the flow type. Displayed in BackOffice billing screens, cashout request views, and withdrawal reports. Used for filtering and grouping operations by trade lifecycle stage. (Tier 1 - upstream wiki, etoro.Dictionary.Flow)';

