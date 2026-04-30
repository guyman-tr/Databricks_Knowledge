-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.Dictionary.AccountType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.AccountType.md
-- Layer: bronze
-- UC Target: main.finance.bronze_usabroker_dictionary_accounttype
-- =============================================================================

-- ---- UC Target: main.finance.bronze_usabroker_dictionary_accounttype (business_group=finance) ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_accounttype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the types of brokerage accounts available at Apex Clearing: CASH, MARGIN, and OPTION. Source: USABroker.Dictionary.AccountType on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.AccountType.md).'
);

ALTER TABLE main.finance.bronze_usabroker_dictionary_accounttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'Dictionary',
    'source_table' = 'AccountType',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_usabroker_dictionary_accounttype ALTER COLUMN AccuntTypeID COMMENT 'Primary key. Typo in column name (missing ''o'' - should be AccountTypeID). Values: 1=CASH, 2=MARGIN, 3=OPTION. Referenced by Apex.UserData.AccountTypeID. (Tier 1 - upstream wiki, USABroker.Dictionary.AccountType)';
ALTER TABLE main.finance.bronze_usabroker_dictionary_accounttype ALTER COLUMN Name COMMENT 'Display name for the account type. UPPERCASE format matching Apex Clearing''s API conventions. (Tier 1 - upstream wiki, USABroker.Dictionary.AccountType)';

