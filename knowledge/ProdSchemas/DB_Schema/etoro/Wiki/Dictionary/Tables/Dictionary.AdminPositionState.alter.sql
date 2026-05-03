-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AdminPositionState
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AdminPositionState.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_adminpositionstate
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_adminpositionstate (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_adminpositionstate SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 4 administrative position order states - Pending, Placed, Filled, and Rejected - used to track admin-initiated position operations through the execution pipeline. Source: etoro.Dictionary.AdminPositionState on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AdminPositionState.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_adminpositionstate SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AdminPositionState',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_adminpositionstate ALTER COLUMN Id COMMENT 'Identifier for the admin position state. 1=Pending, 2=Placed, 3=Filled, 4=Rejected. No PK constraint defined (heap table). Referenced by Trade.SetAdminPositionState and Trade.OrderForOpenCreateWrapper. (Tier 1 - upstream wiki, etoro.Dictionary.AdminPositionState)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_adminpositionstate ALTER COLUMN State COMMENT 'Human-readable state name. Describes the current stage of the admin position operation lifecycle. (Tier 1 - upstream wiki, etoro.Dictionary.AdminPositionState)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
