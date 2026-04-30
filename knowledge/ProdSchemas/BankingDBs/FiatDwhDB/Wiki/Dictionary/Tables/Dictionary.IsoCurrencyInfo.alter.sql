-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Dictionary.IsoCurrencyInfo
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.IsoCurrencyInfo.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo SET TBLPROPERTIES (
    'comment' = 'Reference table containing ISO 4217 currency codes with alphabetical code, numeric code, and minor unit (decimal places) for all supported currencies. Source: FiatDwhDB.Dictionary.IsoCurrencyInfo on the FiatDwhDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.IsoCurrencyInfo.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'IsoCurrencyInfo',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo ALTER COLUMN AlphabeticalCode COMMENT 'ISO 4217 three-letter currency code (e.g., USD, EUR, GBP). Primary key. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.IsoCurrencyInfo)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo ALTER COLUMN NumericCode COMMENT 'ISO 4217 three-digit numeric code (e.g., 840, 978, 826). Referenced by CurrencyISON columns. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.IsoCurrencyInfo)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo ALTER COLUMN MinorUnit COMMENT 'Number of decimal places (0-4). Determines amount precision. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.IsoCurrencyInfo)';

