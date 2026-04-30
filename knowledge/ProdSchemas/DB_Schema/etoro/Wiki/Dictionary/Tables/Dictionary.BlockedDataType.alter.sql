-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.BlockedDataType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BlockedDataType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_blockeddatatype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_blockeddatatype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_blockeddatatype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 5 types of customer data that can be blacklisted — User Name, Email, OriginalCID, Credit Card, and PayPal Email — used by the fraud prevention and risk management blacklist system. Source: etoro.Dictionary.BlockedDataType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BlockedDataType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_blockeddatatype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'BlockedDataType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_blockeddatatype ALTER COLUMN BlockedDataTypeID COMMENT 'Primary key identifying the blocked data category. Values 1-5. Referenced by BackOffice.CustomerBlackList.BlockedDataTypeID (FK) and History.RiskNotification.BlockedDataTypeID (FK) to classify what type of data is on the blacklist. (Tier 1 - upstream wiki, etoro.Dictionary.BlockedDataType)';
ALTER TABLE main.general.bronze_etoro_dictionary_blockeddatatype ALTER COLUMN Name COMMENT 'Human-readable name of the blocked data category (e.g., ''User Name'', ''Email'', ''Credit Card''). Enforced unique via the DBDT_NAME index. Used in BackOffice UIs for blacklist management and in risk notification reports. (Tier 1 - upstream wiki, etoro.Dictionary.BlockedDataType)';

