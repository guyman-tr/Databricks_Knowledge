-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.BankBin
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BankBin.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_bankbin
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_bankbin (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_bankbin SET TBLPROPERTIES (
    'comment' = 'Mapping table linking bank BIN (Bank Identification Number) codes to internal bank identifiers, enabling card-issuer identification for deposit routing and fraud detection. Source: etoro.Dictionary.BankBin on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BankBin.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_bankbin SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'BankBin',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_bankbin ALTER COLUMN BankID COMMENT 'FK to Dictionary.Bank.BankID. Identifies the issuing bank for this BIN code. Part of composite PK. (Tier 1 - upstream wiki, etoro.Dictionary.BankBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_bankbin ALTER COLUMN BinCode COMMENT 'The 6-digit BIN (Bank Identification Number) prefix from the card number. Part of composite PK. Also has a dedicated NC index (DBNB_BINCODE) for efficient lookups by BIN during deposit processing. (Tier 1 - upstream wiki, etoro.Dictionary.BankBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_bankbin ALTER COLUMN Comment COMMENT 'Optional annotation explaining the BIN-to-bank mapping. Currently NULL for the single production row. May contain notes about card product types or special routing instructions. (Tier 1 - upstream wiki, etoro.Dictionary.BankBin)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
