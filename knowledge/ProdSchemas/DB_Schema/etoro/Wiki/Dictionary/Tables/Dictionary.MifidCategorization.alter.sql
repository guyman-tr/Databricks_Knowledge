-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.MifidCategorization
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MifidCategorization.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_mifidcategorization
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_mifidcategorization (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_mifidcategorization SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the MiFID II client categorization levels used to classify customers under EU regulatory requirements. Source: etoro.Dictionary.MifidCategorization on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MifidCategorization.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_mifidcategorization SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'MifidCategorization',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_mifidcategorization ALTER COLUMN MifidCategorizationID COMMENT 'MiFID II client classification tier: 0=None (non-EU), 1=Retail (full protection, default), 2=Professional (reduced protection), 3=Elective Professional (opted-in retail), 4=Retail Pending (under review), 5=Pending (assessment incomplete). Referenced by BackOffice.Customer.MifidCategorizationID (FK, DEFAULT 1) and History.BackOfficeCustomer. Feeds into computed column TradingRiskStatusID. (Tier 1 - upstream wiki, etoro.Dictionary.MifidCategorization)';
ALTER TABLE main.general.bronze_etoro_dictionary_mifidcategorization ALTER COLUMN Name COMMENT 'Human-readable classification label. Used in compliance dashboards and regulatory reports. (Tier 1 - upstream wiki, etoro.Dictionary.MifidCategorization)';

