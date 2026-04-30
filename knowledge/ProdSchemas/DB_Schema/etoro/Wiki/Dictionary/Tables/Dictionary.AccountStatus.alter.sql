-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AccountStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_accountstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_accountstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_accountstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the possible open/closed states of an eToro trading account. Source: etoro.Dictionary.AccountStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_accountstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AccountStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_accountstatus ALTER COLUMN AccountStatusID COMMENT 'Primary key identifying the account state. 1=Open (active account, full platform access), 2=Closed (deactivated, no activity permitted). Referenced by Customer.CustomerStatic.AccountStatusID and Hedge.AccountStatus tables. See Account Status. (Dictionary.AccountStatus) (Tier 1 - upstream wiki, etoro.Dictionary.AccountStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_accountstatus ALTER COLUMN AccountStatusName COMMENT 'Human-readable label for the account state. Used in BackOffice reporting procedures (e.g., BackOffice.GetBlockedCustomers, BackOffice.GetClosedAccountsByLastChangeDate) to display account state in administrative UI. (Tier 1 - upstream wiki, etoro.Dictionary.AccountStatus)';

