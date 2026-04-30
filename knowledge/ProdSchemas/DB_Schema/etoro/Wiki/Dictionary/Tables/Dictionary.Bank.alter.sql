-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Bank
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Bank.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_bank
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_bank (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_bank SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the banking and payment processing partners used by eToro for fund custody and transaction processing. Source: etoro.Dictionary.Bank on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Bank.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_bank SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Bank',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_bank ALTER COLUMN BankID COMMENT 'Primary key identifying the banking/payment partner. Referenced by Dictionary.Regulation.BankID to link regulatory entities to their custodian banks. Referenced by Dictionary.CardTypeToBank and Dictionary.BankBin for payment card routing. (Tier 1 - upstream wiki, etoro.Dictionary.Bank)';
ALTER TABLE main.general.bronze_etoro_dictionary_bank ALTER COLUMN Name COMMENT 'Human-readable name of the banking partner. UNIQUE constraint ensures no duplicates. Used in payment routing reports and back-office displays. (Tier 1 - upstream wiki, etoro.Dictionary.Bank)';
ALTER TABLE main.general.bronze_etoro_dictionary_bank ALTER COLUMN IsActive COMMENT 'Whether this banking partner is currently processing transactions. 1=active (new transactions can be routed), 0=inactive (retained for historical audit only). Payment routing procedures filter on IsActive=1. (Tier 1 - upstream wiki, etoro.Dictionary.Bank)';

