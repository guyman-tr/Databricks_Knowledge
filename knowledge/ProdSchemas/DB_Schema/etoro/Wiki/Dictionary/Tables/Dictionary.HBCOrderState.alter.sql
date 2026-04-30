-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HBCOrderState
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HBCOrderState.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_hbcorderstate
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_hbcorderstate (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_hbcorderstate SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the six lifecycle states of HBC (Hedge Back-to-Client) orders — from initial creation through pending, filled, rejected, cancelled, or unrecoverable states. Source: etoro.Dictionary.HBCOrderState on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HBCOrderState.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_hbcorderstate SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HBCOrderState',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_hbcorderstate ALTER COLUMN OrderStateID COMMENT 'Primary key identifying the HBC order state. 0=New, 1=Pending, 2=Filled, 3=Rejected, 4=Cancelled, 5=UnRecoverable. Stored on Hedge.HBCOrderLog to track order lifecycle progression. (Tier 1 - upstream wiki, etoro.Dictionary.HBCOrderState)';
ALTER TABLE main.general.bronze_etoro_dictionary_hbcorderstate ALTER COLUMN OrderStateName COMMENT 'Human-readable label for the order state. Used in hedge monitoring dashboards, order log displays, and alerting systems. Describes the current status of the HBC order in the execution pipeline. (Tier 1 - upstream wiki, etoro.Dictionary.HBCOrderState)';

