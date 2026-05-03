-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Language
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Language.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_language
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_language (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_language SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 28 supported UI and communication languages on the eToro platform, with ISO and culture codes for localization. Source: etoro.Dictionary.Language on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Language.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_language SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Language',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_language ALTER COLUMN LanguageID COMMENT 'Primary key identifying the language. 1=English(UK), 2=German, 3=Arabic, 4=Chinese, 5=Russian, 6=Spanish, 7=French, 8=Italian, 9=Japanese, 10=Portuguese(BR), 11=Turkish, 12=Greek, 13=Korean, 14=Swedish, 15=Norwegian, 16=Hungarian, 17=Polish, 18=ChineseTraditional, 19=Dutch, 20=EuropeanPortuguese, 21=Czech, 22=Malay, 23=Danish, 24=Romanian, 25=EnglishUS, 26=Vietnamese, 27=Thai, 28=Finnish. Referenced by Dictionary.Country.LanguageID. See Language. (Dictionary.Language) (Tier 1 - upstream wiki, etoro.Dictionary.Language)';
ALTER TABLE main.general.bronze_etoro_dictionary_language ALTER COLUMN Name COMMENT 'Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. (Tier 1 - upstream wiki, etoro.Dictionary.Language)';
ALTER TABLE main.general.bronze_etoro_dictionary_language ALTER COLUMN IsoCode COMMENT 'ISO 639-1 two-letter language code (e.g., "en", "de", "ar"). Used for URL routing, API locale headers, and content management. May be shared between regional variants (e.g., both en-GB and en-US share "en"). (Tier 1 - upstream wiki, etoro.Dictionary.Language)';
ALTER TABLE main.general.bronze_etoro_dictionary_language ALTER COLUMN CultureCode COMMENT '.NET culture code for full locale specification (e.g., "en-GB", "de-DE", "zh-CN"). Used for number formatting (decimal separators), date formatting, and currency display. Provides the regional distinction that IsoCode alone cannot. (Tier 1 - upstream wiki, etoro.Dictionary.Language)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
