-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.BlockUnBlockReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BlockUnBlockReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_blockunblockreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_blockunblockreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_blockunblockreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the reasons recorded when a customer''s trading operations are blocked or unblocked. Critical for compliance audit trails - every restriction or lift must have a documented reason. Source: etoro.Dictionary.BlockUnBlockReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BlockUnBlockReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_blockunblockreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'BlockUnBlockReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_blockunblockreason ALTER COLUMN ID COMMENT 'Primary key; unique identifier. NOT FOR REPLICATION - IDs come from master in replication. Referenced by Customer.BlockedCustomerOperations.BlockReasonID, History.BlockedCustomerOperations.BlockReasonID/UnBlockReasonID. (Tier 1 - upstream wiki, etoro.Dictionary.BlockUnBlockReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_blockunblockreason ALTER COLUMN Reason COMMENT 'Human-readable reason label (e.g., "Risk", "Compliance"). Returned by Trade.GetCustomerBlockUnBlockReasonsForAPI. Used in Trade.GetSmartCopyRestrictions as RemovableByReason. (Tier 1 - upstream wiki, etoro.Dictionary.BlockUnBlockReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
