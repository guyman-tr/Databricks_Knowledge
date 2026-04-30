-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.Dictionary.ApexStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.ApexStatus.md
-- Layer: bronze
-- UC Target: main.finance.bronze_usabroker_dictionary_apexstatus
-- =============================================================================

-- ---- UC Target: main.finance.bronze_usabroker_dictionary_apexstatus (business_group=finance) ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_apexstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 16 high-level lifecycle statuses for Apex Clearing brokerage accounts, from NEW through COMPLETE, REJECTED, RESTRICTED, and CLOSED. Source: USABroker.Dictionary.ApexStatus on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.ApexStatus.md).'
);

ALTER TABLE main.finance.bronze_usabroker_dictionary_apexstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'Dictionary',
    'source_table' = 'ApexStatus',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_usabroker_dictionary_apexstatus ALTER COLUMN StatusID COMMENT 'Primary key. 16 values (1-16) covering the complete account lifecycle. Referenced by Apex.ApexData.StatusID (explicit FK) and Apex.RequestLog.StatusID (implicit). (Tier 1 - upstream wiki, USABroker.Dictionary.ApexStatus)';
ALTER TABLE main.finance.bronze_usabroker_dictionary_apexstatus ALTER COLUMN Name COMMENT 'UPPERCASE display name for the status. Used in API responses and UI display. (Tier 1 - upstream wiki, USABroker.Dictionary.ApexStatus)';

