-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AllocationType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AllocationType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_allocationtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_allocationtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_allocationtype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining how a fund interval allocation is classified - Copy (investing via CopyTrading) or Asset (direct investment in an instrument). Used in Smart Portfolios / CopyFunds. Source: etoro.Dictionary.AllocationType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AllocationType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_allocationtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AllocationType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_allocationtype ALTER COLUMN AllocationType COMMENT 'Primary key identifying the allocation strategy. 1=Copy (CopyTrading), 2=Asset (direct instrument). Referenced by Trade.FundIntervalAllocation via FK. Default value 1 in Trade.CreateNewFundAllocation. (Tier 1 - upstream wiki, etoro.Dictionary.AllocationType)';
ALTER TABLE main.general.bronze_etoro_dictionary_allocationtype ALTER COLUMN AllocationTypeDesc COMMENT 'Human-readable description. Values: ''Copy'', ''Asset''. Nullable per DDL. Used in reports and UI. (Tier 1 - upstream wiki, etoro.Dictionary.AllocationType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
