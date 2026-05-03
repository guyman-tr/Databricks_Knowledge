-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.OperationTypesForBlocking
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OperationTypesForBlocking.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_operationtypesforblocking
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_operationtypesforblocking (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_operationtypesforblocking SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the high-level operation categories that can be blocked per customer. Parent level in a two-tier blocking system with AtomicOperationsForBlocking. Source: etoro.Dictionary.OperationTypesForBlocking on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OperationTypesForBlocking.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_operationtypesforblocking SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'OperationTypesForBlocking',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_operationtypesforblocking ALTER COLUMN OperationTypeID COMMENT 'Primary key. 1 - 24. MCP-verified. FK target from Customer.BlockedCustomerOperations and Trade.OperationTypeForBlockingToAtomic. (Tier 1 - upstream wiki, etoro.Dictionary.OperationTypesForBlocking)';
ALTER TABLE main.general.bronze_etoro_dictionary_operationtypesforblocking ALTER COLUMN OperationDescription COMMENT 'Human-readable description. Values: ''Copy User'', ''Copied'', ''Trading'', ''Position Open'', ''Manual Edit SL'', etc. MCP-verified. (Tier 1 - upstream wiki, etoro.Dictionary.OperationTypesForBlocking)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
