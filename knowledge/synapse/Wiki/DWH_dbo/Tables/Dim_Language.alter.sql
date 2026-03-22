-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Language
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_Language` is the platform''s language reference table, mapping each LanguageID to the human-readable language name, its ISO 639-1 two-letter code, and its IETF BCP 47 culture code. The 29 rows cover 28 supported platform languages plus a LanguageID=0 null-sentinel (`N/A`). Customer profiles and events carry a LanguageID indicating the customer''s selected UI language and preferred communication locale. The table includes two Chinese variants (LanguageID=4 `Chinese`/zh-CN for Simplified, LanguageID=18 `ChineseTraditional`/zh-TW for Traditional) and two English variants (LanguageID=1 `English`/en-GB for British, LanguageID=25 `EnglishUS`/en-US for American). Both variants share the same IsoCode but differ in CultureCode. ETL is part of the bulk `SP_Dictionaries_DL_To_Synapse` stored procedure (runs daily). Source is `DWH_staging.etoro_Dictionary_Language`. The table is HEAP-indexed (no clustered index) because at 29 rows, index overhead is negligible. Synapse: REPLICATE, HEAP (no clustered index).'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP (no clustered index)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN LanguageID COMMENT 'Primary key identifying the language. 1=English(UK), 2=German, 3=Arabic, 4=Chinese, 5=Russian, 6=Spanish, 7=French, 8=Italian, 9=Japanese, 10=Portuguese(BR), 11=Turkish, 12=Greek, 13=Korean, 14=Swedish, 15=Norwegian, 16=Hungarian, 17=Polish, 18=ChineseTraditional, 19=Dutch, 20=EuropeanPortuguese, 21=Czech, 22=Malay, 23=Danish, 24=Romanian, 25=EnglishUS, 26=Vietnamese, 27=Thai, 28=Finnish. Referenced by Dictionary.Country.LanguageID. (Tier 1 — Dictionary.Language)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN Name COMMENT 'Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. (Tier 1 — Dictionary.Language)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN DWHLanguageID COMMENT 'Always equal to LanguageID. Standard DWH DWH{X}ID redundancy pattern. Do not use for JOINs. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN StatusID COMMENT 'Hardcoded to 1 for all rows. Conveys no business information. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN InsertDate COMMENT 'ETL load timestamp -- GETDATE() at load time, same as UpdateDate. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN IsoCode COMMENT 'ISO 639-1 two-letter language code (e.g., ''en'', ''de'', ''ar''). Used for URL routing, API locale headers, and content management. (Tier 1 — Dictionary.Language)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN CultureCode COMMENT '.NET culture code for full locale specification (e.g., ''en-GB'', ''de-DE'', ''zh-CN''). Used for number formatting, date formatting, and currency display. (Tier 1 — Dictionary.Language)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN LanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN DWHLanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN IsoCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language ALTER COLUMN CultureCode SET TAGS ('pii' = 'none');
